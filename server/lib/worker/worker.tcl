#
# worker program (worker thread to answer SCGI requests)
#
# Tcl variables initialized during the thread start
# - conffile: pathname of configuration file
# - wrkdir: pathname of the directory containing this file
# - auto_path: path of Tcl packages specific to Netmagis
#

set conf(static-dir)	%NMLIBDIR%/www
set conf(static-dir)	/tmp
set conf(lang)		{en fr}

package require snit
package require Pgtcl

package require pgdb
package require lconf
package require dbconf

package require msgcat
namespace import ::msgcat::*

array set route {
    get {}
    post {}
    put {}
    delete {}
}

##############################################################################
# Thread initialisation
##############################################################################

proc thread-init {conffile wdir} {
    ::lconf::lconf create ::lc
    ::lc read $conffile

    ::pgdb::db create ::dbdns
    ::dbdns init "dns" ::lc 3.0.0foobar 		;# "%NMVERSION%"

    ::pgdb::db create ::dbmac
    ::dbmac init "mac" ::lc ""

    ::dbconf::db-config create ::config
    ::config setdb ::dbdns

    ::nmlog create ::log
    ::log setdb ::dbdns

    #
    # Create a global object for configuration parameters
    #

    uplevel \#0 source $wdir/libworker.tcl
    load-handlers $wdir
}

##############################################################################
# Log management
##############################################################################

snit::type ::nmlog {

    # database object
    variable dbo

    variable subsys "netmagis"
    variable table "global.log"

    method setdb {db} {
	set dbo $db
    }

    method write {event msg {date {}} {login {}} {ip {}}} {
	if {$ip eq ""} then {
	    set ip [::scgiapp::get-header "REMOTE_ADDR"]
	}

	if {$login eq ""} then {
	    error XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXxx
	}

	foreach v {event login ip msg} {
	    if {[set $v] eq ""} then {
		    set $v NULL
	    } else {
		set $v [pg_quote [set $v]]
	    }
	}
	if {$date eq ""} then {
	    set datecol ""
	    set dateval ""
	} else {
	    set datecol "date,"
	    if {[regexp {^\d+$} $date]} then {
		set dateval "to_timestamp($date)"
	    } else {
		set dateval [pg_quote $date]
	    }
	    append dateval ","
	}
	set sub [pg_quote $subsys]
	set sql "INSERT INTO $table
			($datecol subsys, event, login, ip, msg)
		    VALUES ($dateval $sub, $event, $login, $ip, $msg)"
	$dbo exec $sql
    }
}

##############################################################################
# User characteristics
##############################################################################

#
# Netmagis user characteristics class
#
# This class stores all informations related to current Netmagis user
#
# Methods:
# - setdb dbfd
#	set the database handle used to access parameters
# - setlogin login
#	set the login name
#
# ....
#
# - viewname id
#	returns view name associated to view id (or empty string if error)
# - viewid name
#	returns view id associated to view name (or -1 if error)
# - myviewids
#	get all authorized view ids
# - isallowedview id
#	check if a view is authorized (1 if ok, 0 if not)
#
# - domainname id
#	returns domain name associated to domain id (or empty string if error)
# - domainid name
#	returns domain id associated to domain name (or -1 if error)
# - myiddom
#	get all authorized domain ids
# - isalloweddom id
#	check if a domain is authorized (1 if ok, 0 if not)
#
# History
#   2012/10/31 : pda/jean : design
#

snit::type ::nmuser {
    # database object
    variable dbo ""
    # login of user
    variable login ""

    # ids of user
    variable ids {
	idcor -1
	idgrp -1
	present 0
	p_admin 0
	p_smtp 0
	p_ttl 0
	p_mac 0
	p_genl 0
    }


    # Group management
    # Group information is loaded
    variable groupsloaded 0
    # allgroups(id:<id>)=name
    # allgroups(name:<name>)=id
    variable allgroups -array {}

    # View management
    # view information is loaded
    variable viewsloaded 0
    # allviews(id:<id>)=name
    # allviews(name:<name>)=id
    variable allviews -array {}
    # authviews(<id>)=1
    variable authviews -array {}
    # myviewids : sorted list of views
    variable myviewids {}

    # Domain management
    # domain information is loaded
    variable domainloaded 0
    # alldom(id:<id>)=name
    # alldom(name:<name>)=id
    variable alldom -array {}
    # authdom(<id>)=1
    variable authdom -array {}
    # myiddoms : sorted list of domains
    variable myiddom {}

    method setdb {db} {
	set dbo $db
    }

    method setlogin {newlogin} {
	if {$login ne $newlogin} then {
	    set viewsisloaded 0
	}
	set login $newlogin
    }

    method cap {cap} {
	set idcor [dict get $ids idcor]
	if {$idcor == -1} then {
	    set qlogin [pg_quote $login]
	    set sql "SELECT u.idcor, g.*
			    FROM global.nmuser u
				NATURAL INNER JOIN global.nmgroup g
				WHERE login = $qlogin"
	    set found 0
	    $dbo exec $sql tab {
		set ids [array get tab]
		set found 1
	    }
	    if {! $found} then {
		error "login '$login' not found"
	    }
	}
	return [dict get $ids $cap]
    }

    method idcor {} {
	return [$self cap "idcor"]
    }

    method idgrp {} {
	return [$self cap "idgrp"]
    }


    #######################################################################
    # Group management
    #######################################################################

    proc load-groups {selfns} {
	array unset allgroups

	set sql "SELECT * FROM global.nmgroup"
	$dbo exec $sql tab {
	    set idgrp $tab(idgrp)
	    set name  $tab(name)
	    set allgroups(id:$idgrp) $name
	    set allgroups(name:$name) $idgrp
	}
	set groupsloaded 1
    }

    method groupname {id} {
	if {! $groupsloaded} then {
	    load-groups $selfns
	}
	set r -1
	if {[info exists allgroups(id:$id)]} then {
	    set r $allgroups(id:$id)
	}
	return $r
    }

    method groupid {name} {
	if {! $groupsloaded} then {
	    load-groups $selfns
	}
	set r ""
	if {[info exists allgroups(name:$name)]} then {
	    set r $allgroups(name:$name)
	}
	return $r
    }

    #######################################################################
    # View management
    #######################################################################

    proc load-views {selfns} {
	array unset allviews
	array unset authviews
	set myviewids {}

	set sql "SELECT * FROM dns.view"
	$dbo exec $sql tab {
	    set idview $tab(idview)
	    set name   $tab(name)
	    set allviews(id:$idview) $name
	    set allviews(name:$name) $idview
	}

	set qlogin [pg_quote $login]
	set sql "SELECT p.idview
			FROM dns.p_view p, dns.view v, global.nmuser u
			WHERE p.idgrp = u.idgrp
			    AND p.idview = v.idview
			    AND u.login = $qlogin
			ORDER BY p.sort ASC, v.name ASC"
	$dbo exec $sql tab {
	    set idview $tab(idview)
	    set authviews($idview) 1
	    lappend myviewids $tab(idview)
	}

	set viewsloaded 1
    }

    method viewname {id} {
	if {! $viewsloaded} then {
	    load-views $selfns
	}
	set r -1
	if {[info exists allviews(id:$id)]} then {
	    set r $allviews(id:$id)
	}
	return $r
    }

    method viewid {name} {
	if {! $viewsloaded} then {
	    load-views $selfns
	}
	set r ""
	if {[info exists allviews(name:$name)]} then {
	    set r $allviews(name:$name)
	}
	return $r
    }

    method myviewids {} {
	if {! $viewsloaded} then {
	    load-views $selfns
	}
	return $myviewids
    }

    method isallowedview {id} {
	if {! $viewsloaded} then {
	    load-views $selfns
	}
	return [info exists authviews($id)]
    }

    #######################################################################
    # Domain management
    #######################################################################

    proc load-domains {selfns} {
	array unset alldom
	array unset authdom
	set myiddom {}

	set sql "SELECT * FROM dns.domain"
	$dbo exec $sql tab {
	    set iddom $tab(iddom)
	    set name   $tab(name)
	    set alldom(id:$iddom) $name
	    set alldom(name:$name) $iddom
	}

	set qlogin [pg_quote $login]
	set sql "SELECT p.iddom
			FROM dns.p_dom p, dns.domain d, global.nmuser u
			WHERE p.idgrp = u.idgrp
			    AND p.iddom = d.iddom
			    AND u.login = $qlogin
			ORDER BY p.sort ASC, d.name ASC"
	$dbo exec $sql tab {
	    set iddom $tab(iddom)
	    set authdom($iddom) 1
	    lappend myiddom $tab(iddom)
	}

	set domainloaded 1
    }

    method domainname {id} {
	if {! $domainloaded} then {
	    load-domains $selfns
	}
	set r -1
	if {[info exists alldom(id:$id)]} then {
	    set r $alldom(id:$id)
	}
	return $r
    }

    method domainid {name} {
	if {! $domainloaded} then {
	    load-domains $selfns
	}
	set r ""
	if {[info exists alldom(name:$name)]} then {
	    set r $alldom(name:$name)
	}
	return $r
    }

    method myiddom {} {
	if {! $domainloaded} then {
	    load-domains $selfns
	}
	return $myiddom
    }

    method isalloweddom {id} {
	if {! $domainloaded} then {
	    load-domains $selfns
	}
	return [info exists authdom($id)]
    }
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
    set idle       [::config get "authexpire"]
    set apiexpire  [::config get "apiexpire"]
    set wtmpexpire [::config get "wtmpexpire"]

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
	    ::log write "auth" "lastaccess $l $tok" $la $l
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
		    WHERE token = $qtoken AND u.idcor = t.idcor
		    RETURNING u.login"
    ::dbdns exec $sql tab {
	set login $tab(login)
	set found true
    }

    if {$found} then {
	# re-inject cookie (for login/call-cgi)
	::scgiapp::set-cookie "session" $token 0 "" "" 0 0
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

proc api-handler {method pathspec authneeded paramspec script} {
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
    #

    regsub -all {\(([^:]+):[^)]+\)} $pathspec {(\1)} re
    set re "^$re$"

    #
    # Create new procedure for this handler
    # An API-handler is transformed into a procedure which accepts
    # the following parameters
    # - _meth: get/post/delete/put
    # - _parm: all parameters
    # - _cookie: a dict with cookie items (e.g. "dict get $cookie session")
    # - all parameters given in the handler header
    #

    global curhdl
    incr curhdl(count)

    set hname "_$curhdl(name)-$curhdl(count)"
    proc $hname {_meth _parm _cookie _paramdict} "
	::scgiapp::import-param \$_paramdict
	unset _paramdict
	$script
    "

    lappend route($method) [list $re $vars $paramspec $authneeded $hname]
}

##############################################################################
# Request handling
##############################################################################

#
# Input:
#   - sock: socket
#   - headers: Tcl dictionnary containing http server informations
#   - body: request body, including form parameters
# Output:
#   - stdout: <code> <text>

proc handle-request {uri meth parm cookie} {
    global wrkdir
    global route

    uplevel #0 mclocale "en"
    uplevel #0 mcload $wrkdir/msgs

    set ok 0
    foreach r $route($meth) {
	#
	# Each route is registered as a list
	#	{ re vars paramspec authneeded script }
	# with:
	# - re: regexp including groups "(...)" for variable
	#	matching
	# - vars: list of variables for group matching
	# - paramspec: list of query parameters spec
	#	{ param min param min ... }
	#	example : { crit 0 field 1 }
	#	- param: parameter name
	#	- min: minimum number of occurrence (max is always 1)
	# - authneeded: boolean true if access is restricted
	#	to authenticated users
	# - hname: name of proc for this handler
	#

	lassign $r re vars paramspec authneeded hname

	lassign [check-route $uri $parm $re $vars $paramspec] ok tpar
	if {$ok} then {
	    break
	}
    }

    if {$ok} then {
	#
	# This route is ok. Try to reconnect to the database
	# and check authentication
	#

	try {
	    ::dbdns reconnect
	    ::dbmac reconnect
	} on error msg {
	    ::scgiapp::scgi-error 503 $msg
	}

	set authtoken [::scgiapp::dget $cookie "session"]
	set login [check-authtoken $authtoken]
	if {$authneeded && $login eq ""} then {
	    ::scgiapp::scgi-error 403 "Not authenticated"
	}

	if {$login ne ""} then {
	    catch {::u destroy}
	    ::nmuser create ::u
	    ::u setdb ::dbdns
	    ::u setlogin $login
	}

	#
	# Locale settings
	#

	if {[dict exists $parm "l"]} then {
	    set l [string trim [lindex [dict get $parm "l"] 0]]
	} else {
	    set l [::scgiapp::get-locale {en fr}]
	}

	if {$l ne ""} then {
	    uplevel #0 mclocale $l
	    uplevel #0 mcload $wrkdir/msgs
	}

	#
	# Run the script as a procedure to avoid namespace
	# pollution. The procedure is run with the following
	# parameters:
	# - meth: http method
	# - parm: see scgiapp::parse-param procedure
	# - cookie: dict containing cookie items
	# - tpar: query parameters of handler
	#

	$hname $meth $parm $cookie $tpar
    } else {
	::scgiapp::scgi-error 404 "URI '$uri' not found"
    }
}


#
# Check URI: try to match the regexp, extract named
# groups and check parameter specifications
# Named groups and parameters are stored in the tpar dict
#
# Returns: list { ok tpar }
#

proc check-route {uri parm re vars paramspec} {

    set ok 0
    set tpar [dict create]

    set l [regexp -inline $re $uri]
    if {[llength $l] > 0} then {

	# Extract named groups if any
	set i 0
	foreach val [lreplace $l 0 0] {
	    set var [lindex $vars $i]
	    dict set tpar $var $val
	    incr i
	}

	# Check parameters
	set ok 1
	foreach {var min} $paramspec {
	    if {! [dict exists $parm $var] && $min > 0} then {
		set ok 0
		break
	    } else {
		set vals [::scgiapp::dget $parm $var]
		dict set tpar $var [lindex $vals 0]
	    }
	}
    }

    return [list $ok $tpar]
}

try {
    thread-init $conffile $wrkdir
} on error msg {
    puts stderr $msg
    exit 1
}
