#
# worker program (worker thread to answer SCGI requests)
#
# Tcl variables initialized during the thread start
# - conf(conffile): pathname of configuration file
# - conf(libdir): pathname of the directory containing worker/ and pkgtcl/
# - conf(files): pathname of the directory containing *.html files
# - conf(version): application version
# - auto_path: path of Tcl packages specific to Netmagis
#

set conf(lang)		{en fr de}

package require snit
package require Pgtcl
package require md5crypt
package require ip
package require ldapx

package require msgcat
namespace import ::msgcat::*

package require pgdb
package require nmenv
package require lconf
package require nmjson
package require rr

array set route {
    get {}
    post {}
    put {}
    delete {}
}

##############################################################################
# Thread initialisation
##############################################################################

proc thread-init {conffile version wdir} {
    global conf

    ::lconf::lconf create ::lc
    ::lc read $conffile

    ::pgdb::db create ::dbdns
    ::dbdns init "dns" ::lc $version

    ::pgdb::db create ::dbmac
    ::dbmac init "mac" ::lc ""

    ::nmenv::nmenv create ::n
    ::n setdb ::dbdns

    #
    # Create a global object for configuration parameters
    #

    uplevel \#0 source $wdir/libworker.tcl
    load-handlers $wdir
}

##############################################################################
# Authentication
##############################################################################

#
# Check authentication token
#
# Input:
#   - parameters:
#	- token : authentication token (given by the session cookie)
# Output:
#   - return value: login or "" if invalid token
#

proc check-authtoken {token} {
    set idle       [::n confget "authexpire"]
    set apiexpire  [::n confget "apiexpire"]
    set wtmpexpire [::n confget "wtmpexpire"]

    #
    # Expire old utmp entries
    #

    ::dbdns lock {global.utmp global.wtmp} {

	# Get the list of expired sessions for the log (see below)

	set sql "SELECT u.login, t.token, t.lastaccess
			    FROM global.nmuser u, global.utmp t
			    WHERE t.lastaccess < NOW() - interval '$idle second'
				AND u.idcor = t.idcor
				AND t.api = 0"
	set lexp {}
	::dbdns exec $sql tab {
	    lappend lexp [list $tab(login) $tab(token) $tab(lastaccess)]
	}

	# Transfer all expired interactive utmp entries to wtmp, delete
	# all expired api utmp entries, and delete old wtmp entries

	set sql "INSERT INTO global.wtmp (idcor, token, start, ip, stop, stopreason)
		    SELECT idcor, token, start, ip, lastaccess, 'expired'
			FROM global.utmp
			WHERE lastaccess < NOW() - interval '$idle second'
			    AND api = 0
			;
		 DELETE FROM global.utmp
			WHERE lastaccess < NOW() - interval '$idle second'
			    AND api = 0
			;
		 DELETE FROM global.utmp
			WHERE lastaccess < NOW() - interval '$apiexpire day'
			    AND api = 1
			;
		 DELETE FROM global.wtmp
			WHERE stop < NOW() - interval '$wtmpexpire day'
			"
	::dbdns exec $sql

	# Log expired sessions

	foreach e $lexp {
	    lassign $e l tok la
	    ::n writelog "auth" "lastaccess $l $tok" null null $la $l
	}
    }

    #
    # Check our own authentication token
    #

    set qtoken [pg_quote $token]
    set login ""
    set found false
    set sql "UPDATE global.utmp t
		    SET lastaccess = NOW()
		    FROM global.nmuser u
		    WHERE token = $qtoken
			AND u.idcor = t.idcor
			AND u.present != 0
		    RETURNING u.login"
    ::dbdns exec $sql tab {
	set login $tab(login)
	set found true
    }

    if {$found} then {
	# re-inject cookie (for login/call-cgi)
	# XXX
	###############::scgi::set-cookie "session" $token 0 "" "" 0 0
    }

    return $login
}

##############################################################################
# Handler registration
##############################################################################

#
# Prefix for handler procedures
# The "array set" below is for documentation purpose only
#
array set curhdl {
    name {}
    count:get 0
    count:delete 0
    count:post 0
    count:put 0
}

#
# Load all procedure handlers
#

proc load-handlers {wdir} {
    global curhdl

    foreach f [lsort [glob -nocomplain $wdir/hdl-*.tcl]] {
	#
	# extract the future prefix for handler proc
	#
	catch {unset curhdl}
	set curhdl(name) $f
	regsub {.*/(hdl-[^/]*).tcl$} $curhdl(name) {\1} curhdl(name)
	regsub -all {[^-a-zA-Z0-9]+} $curhdl(name) {-} curhdl(name)

	#
	# load handler
	#
	uplevel \#0 source $f
    }
}

#
# api-handler is used to register a handler at load-time
#
# Arguments:
# - method: get/post/put/delete
# - pathspec: a regexp with some group definitions and variables
# - neededcap: user capability to call this handler
# - paramspec: query parameter specifiers
# - script: Tcl script
#
# Example:
#   api-handler get {/resource/([0-9]+:idres)} logged {
#	filter 0
#	sort 1
#     } {
#	  # Tcl script using $idres, $filter and $sort
#	  ::scgi::set-header Content-Type: application/json
#	  ::scgi::set-body ....
#     }
#
# Specifications:
# - pathspec: regexp with group definitions and variable names
#	group definitions is introduced by parenthesis (...)
#	as with any regexp (see re_syntax Tcl man page).
#	Each group is ended by ":" and a variable name (see example).
#	The regexp must not contain "^" and "$" symbols.
# - neededcap: user capabilities (see nmenv.tcl package and
#	"capabilities" method). The most useful are:
#	- any: handler need not any capabiliy (even unauthenticated
#		users are permitted)
#	- logged: only authenticated users are permitted
#	- admin: only users with admin privileges are permitted
# - paramspec: pairs <varname> <min>. Each query parameter value
#	will be assigned to the corresponding <varname> (an empty
#	value is assigned for non-existant parameter). A check is
#	made on the minimum number.
#	If paramspec is empty, this is the "fall-back" handler
#	(i.e. any uri will match)
# - script: the Tcl script is executed as a proc, with the
#	the following preset variables (in addition to pathspec
#	and paramspec specific variables):
#	_meth: method
#	_parm: dict containing the following keys:
#		_bodytype: request Content-Type
#		_body: request body
#		<query parameter name>: query value
#	_prefix: uri part before the matched regexp
#		Example: if uri=/foo/bar/netmagis/resource/123
#		and pathspec=/resource/(0-9]+:idres)
#		then _prefix will be set to /foot/bar/netmagis
#

proc api-handler {method pathspec neededcap paramspec script} {
    global route

    set method [string tolower $method]

    if {! [info exists route($method)]} then {
	puts stderr "invalid method for route $pathspec"
	exit 1
    }

    #
    # Check the path specification
    #

    set n1 [regexp -all {[(]} $pathspec]
    set n2 [regexp -all {[)]} $pathspec]
    set n3 [regexp -all {[:]} $pathspec]
    set n4 [regsub -all {\(([^:]+):[^)]+\)} $pathspec {} dummy]
    if {$n1 != $n2 || $n2 != $n3 || $n3 != $n4} then {
	puts stderr "invalid path specification '$pathspec'"
	exit 1
    }

    #
    # Extract variable names from path specification
    #

    set vars {}
    foreach {all var} [regexp -all -inline {:([^)]+)\)} $pathspec] {
	lappend vars $var
    }

    #
    # Build regexp for URI matching
    # Note: URI include the full path of the resource, which is prefixed
    # by the location on the server (e.g. resource /domain is requested
    # by the URI /netmagis/foo/bar/domain).
    #

    regsub -all {\(([^:]+):[^)]+\)} $pathspec {(\1)} re

    #
    # Create new procedure for this handler
    #

    global curhdl
    incr curhdl(count:$method)

    set hname "_$curhdl(name)-$method-$curhdl(count:$method)"
    proc $hname {_meth _parm _prefix _paramdict} "
	::scgi::import-param \$_paramdict
	unset _paramdict
	$script
    "

    set rte [list $re $vars $paramspec $neededcap $hname]

    if {$re eq ""} then {
	if {[info exists route(fallback-$method)]} then {
	    lassign $route(fallback-$method) foo1 foo2 foo3 foo4 $hnameold
	    puts stderr "Fallback method for $method specified more than once"
	    puts stderr "\t($hname vs $hnameold)"
	    exit 1
	}
	# append the "fallback" indicator
	lappend rte 1
	set route(fallback-$method) $rte
    } else {
	# append the "no fallback" indicator
	lappend rte 0
	lappend route($method) $rte
    }
}

##############################################################################
# Request handling
##############################################################################

#
# Input:
#   - uri: CGI pseudo-header "SCRIPT_NAME"
#   - meth: GET, POST, etc.
#   - parm: see scgi::parse-param procedure
# Output:
#   - stdout: <code> <text>

proc handle-request {uri meth parm} {
    global conf
    global route

    #
    # Try to reconnect to the database
    #

    try {
	::dbdns reconnect
	::dbmac reconnect
    } on error msg {
	::scgi::serror 503 $msg
    }

    #
    # Check if user is authenticated. No decision is made at this
    # point.
    #

    set authtoken [::scgi::get-cookie "session"]
    set login [check-authtoken $authtoken]
    # login may be empty (<=> not authenticated)

    ::n login $login

    #
    # Check if user is acting as another (through the "uid" cookie)
    #

    set suid [::scgi::get-cookie "uid"]
    if {$suid ne ""} then {
	::n setuid $suid
    }

    #
    # Locale settings
    # 1- use "l" query parameter if present
    # 2- else, use the "lang" cookie value
    # 3- else, use the "Accept-Language" header values
    # 4- else, use the default ("en")
    #

    set l [::scgi::dget $parm "l"]
    if {$l eq ""} then {
	set l [::scgi::get-cookie "lang"]
	if {$l eq ""} then {
	    set l [::scgi::get-locale $conf(lang)]
	}
    }

    if {! ($l in $conf(lang))} then {
	set l "en"
    }

    uplevel #0 mclocale $l
    uplevel #0 mcload "$conf(libdir)/worker/msgs"

    #
    # Get all the routes. Fetch the fall-back handler in order
    # to check it last.
    #

    set allroutes $route($meth)
    if {[info exists route(fallback-$meth)]} then {
	lappend allroutes $route(fallback-$meth)
    }

    #
    # Find the appropriate route
    #

    set cap [::n capabilities]
    set bestfit 0
    set bestcr {0}

    foreach r $allroutes {
	set cr [check-route $uri $cap $parm $r]
	lassign $cr ok prefix hname tpar
	if {$ok == 5} then {
	    set bestfit 5
	    set bestcr $cr
	    break
	} else {
	    if {$ok > $bestfit} then {
		set bestfit $ok
		set bestcr $cr
	    }
	}
    }

    lassign $bestcr ok prefix hname tpar

    switch $bestfit {
	0 {
	    ::scgi::serror 404 [mc {URI '%1$s' not found for method '%2$s'} $uri $meth]
	}
	2 {
	    ::scgi::serror 401 [mc "Not authenticated"]
	}
	3 {
	    ::scgi::serror 403 [mc "Forbidden"]
	}
	4 {
	    ::scgi::serror 400 [mc "Mandatory query parameter '%s' not found" $q]
	}
	1 -
	5 {
	    #
	    # Run the script as a procedure to avoid namespace
	    # pollution. The procedure is run with the following
	    # parameters:
	    # - meth: http method
	    # - parm: see scgi::parse-param procedure
	    # - cookie: dict containing cookie items
	    # - prefix: prefix part of url
	    # - tpar: query parameters of handler
	    #

	    if {[::scgi::isdebug "request"]} then {
		puts stderr "$meth $uri -> $hname"
	    }
	    $hname $meth $parm $prefix $tpar
	}
    }
}


#
# Check URI: try to match the regexp, extract prefix and named
# groups and check parameter specifications
# Named groups and parameters are stored in the tpar dict
#
# Returns: list { ok prefix hname tpar }
# where ok value is:
# - 0 if no match
# - 1 if ok, but fall-back (hname=handler proc, tpar=parameters)
# - 2 if route match but not authenticated
# - 3 if route match but not enough capabilities (even if parameters match)
# - 4 if route match without matching parameter (tpar=missing parameter)
# - 5 if ok and not fall-back (hname=handler proc, tpar=parameters)
#

proc check-route {uri cap parm rte} {
    global conf

    #
    # Each route is registered as a list
    #	{ re vars paramspec neededcap script }
    # with:
    # - re: regexp including groups "(...)" for variable
    #	matching
    # - vars: list of variables for group matching
    # - paramspec: list of query parameters spec
    #	{ param min param min ... }
    #	example : { crit 0 field 1 }
    #	- param: parameter name
    #	- min: minimum number of occurrence (max is always 1)
    # - neededcap: a capability such as one returned in nmenv package
    # - hname: name of proc for this handler
    # - fall-back: 1 if this is a fall-back handler, 0 if not
    #

    lassign $rte re vars paramspec neededcap hname fb

    set ok 0
    set prefix ""
    set tpar [dict create]

    # uri contains both the prefix (e.g. /where/you/configured/netmagis)
    # and the pattern to match. We complete the regexp to get the prefix
    set re "^(/.*)$re/?$"

    set l [regexp -inline $re $uri]
    if {[llength $l] > 0} then {

	# Extract prefix
	set prefix [lindex $l 1]

	# Extract named groups if any
	set i 0
	foreach val [lreplace $l 0 1] {
	    set var [lindex $vars $i]
	    dict set tpar $var $val
	    incr i
	}

	# Check capabilities
	if {! ($neededcap in $cap)} then {
	    # by default: anonymous => 401 not auth
	    set ok 2
	    if {"logged" in $cap} then {
		# not anonymous => 403 forbidden
		set ok 3
	    }
	}

	# Check parameters
	if {$ok == 0} then {
	    set ok [expr {$fb?1:5}]
	    foreach {var min} $paramspec {
		if {! [dict exists $parm $var] && $min > 0} then {
		    set ok 4
		    set tpar $var
		    break
		} else {
		    set vals [::scgi::dget $parm $var]
		    dict set tpar $var [lindex $vals 0]
		}
	    }
	}
    }

    return [list $ok $prefix $hname $tpar]
}

try {
    thread-init $conf(conffile) $conf(version) $conf(libdir)/worker
} on error msg {
    puts stderr $msg
    exit 1
}
