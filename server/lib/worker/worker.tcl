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

set conf(lang)		{en fr}

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
	    ::n writelog "auth" "lastaccess $l $tok" $la $l
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
#
array set curhdl {name {} count 0}

#
# Load all procedure handlers
#

proc load-handlers {wdir} {
    global curhdl

    foreach f [lsort [glob -nocomplain $wdir/hdl-*.tcl]] {
	#
	# extract the future prefix for handler proc
	#
	set curhdl(name) $f
	regsub {.*/(hdl-[^/]*).tcl$} $curhdl(name) {\1} curhdl(name)
	regsub -all {[^-a-zA-Z0-9]+} $curhdl(name) {-} curhdl(name)
	set curhdl(count) 0

	#
	# load handler
	#
	uplevel \#0 source $f
    }
}

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
    # by the URI /netmagis/foo/bar/domain). There are two solutions to
    # remove the prefix:
    # 1- recognize the prefix, which means adding a new flag or
    #	configuration option to our program
    # 2- match anything: the simplest way, without security compromise.
    #

    regsub -all {\(([^:]+):[^)]+\)} $pathspec {(\1)} re

    #
    # Create new procedure for this handler
    # An API-handler is transformed into a procedure which accepts
    # the following parameters
    # - _meth: get/post/delete/put
    # - _parm: all parameters
    # - all parameters given in the handler header
    #

    global curhdl
    incr curhdl(count)

    set hname "_$curhdl(name)-$curhdl(count)"
    proc $hname {_meth _parm _prefix _paramdict} "
	::scgi::import-param \$_paramdict
	unset _paramdict
	$script
    "

    lappend route($method) [list $re $vars $paramspec $neededcap $hname]
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
    # Find the appropriate route
    #

    set cap [::n capabilities]
    set bestfit 0
    foreach r $route($meth) {
	lassign [check-route $uri $cap $parm $r] ok prefix hname tpar
	if {$ok == 4} then {
	    set bestfit 4
	    break
	} else {
	    if {$ok > $bestfit} then {
		set bestfit $ok
		set q $tpar
	    }
	}
    }

    switch $bestfit {
	0 {
	    ::scgi::serror 404 [mc "URI '%s' not found" $uri]
	}
	1 {
	    ::scgi::serror 401 [mc "Not authenticated"]
	}
	2 {
	    ::scgi::serror 403 [mc "Forbidden"]
	}
	3 {
	    ::scgi::serror 400 [mc "Mandatory query parameter '%s' not found" $q]
	}
	4 {
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
# - 1 if route match but not authenticated
# - 2 if route match but not enough capabilities (even if parameters match)
# - 3 if route match without matching parameter (tpar=missing parameter)
# - 4 if ok (hname=handler proc, tpar=parameters)
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
    #

    lassign $rte re vars paramspec neededcap hname

    set ok 0
    set prefix ""
    set tpar [dict create]

    # uri contains both the prefix (e.g. /where/you/configured/netmagis)
    # and the pattern to match. We complete the regexp to get the prefix
    set re "^$conf(baseurl)$re$"

    set l [regexp -inline $re $uri]
    if {[llength $l] > 0} then {

	# Extract prefix
	set prefix [lindex $l 0]

	# Extract named groups if any
	set i 0
	foreach val [lreplace $l 0 0] {
	    set var [lindex $vars $i]
	    dict set tpar $var $val
	    incr i
	}

	# Check capabilities
	if {! ($neededcap in $cap)} then {
	    # by default: anonymous => 401 not auth
	    set ok 1
	    if {"logged" in $cap} then {
		# not anonymous => 403 forbidden
		set ok 2
	    }
	}

	# Check parameters
	if {$ok == 0} then {
	    set ok 4
	    foreach {var min} $paramspec {
		if {! [dict exists $parm $var] && $min > 0} then {
		    set ok 3
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
