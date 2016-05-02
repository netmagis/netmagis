set conf(static-dir)	/tmp

package require snit
package require Pgtcl

array set route {
    get {}
    post {}
    put {}
    delete {}
}

##############################################################################
# Thread initialisation
##############################################################################

proc thread-init {conffile} {
    global dbfd

    ::local-config create ::lc
    ::lc read $conffile

    ::db create ::dbdns
    ::dbdns init "dns" ::lc 3.0.0foobar 		;# "%NMVERSION%"

    ::db create ::dbmac
    ::dbmac init "mac" ::lc ""

    ::db-config create ::config
    ::config setdb ::dbdns

    ::nmlog create ::log
    ::log setdb ::dbdns

    #
    # Prepare for DB connection
    #

    set dbfd(dns) "not connected"
    set dbfd(mac) "not connected"

    #
    # Create a global object for configuration parameters
    #

    # config ::dnsconfig
    # puts "READY [info procs route-*]"
}

##############################################################################
# Configuration interface
##############################################################################

snit::type ::local-config {
    variable conf

    method read {file} {
	if {[catch {set fd [open "$file" "r"]} msg]} then {
	    error "Cannot open configuration file '$file'"
	}
	set lineno 1
	set errors ""
	set conf [dict create]
	while {[gets $fd line] >= 0} {
	    regsub {#.*} $line {} line
	    regsub {\s*$} $line {} line
	    if {$line ne ""} then {
		if {[regexp {(\S+)\s+"(.*)"} $line m key val]} then {
		    dict set conf $key  $val
		} elseif {[regexp {(\S+)\s+(.*)} $line m key val]} then {
		    dict set conf $key $val
		} else {
		    append errors "$file($lineno): unrecognized line $line\n"
		}
	    }
	    incr lineno
	}
	close $fd
	if {$errors ne ""} then {
	    error $errors
	}
	dict set conf _conffile $file
	dict set conf _version "%NMVERSION%"
    }

    method get {key} {
	if {[dict exists $conf $key]} then {
	    set v [dict get $conf $key]
	} else {
	    set v ""
	}
	return $v
    }
}

##############################################################################
# Configuration parameters from database
##############################################################################

#
# Configuration parameters class
#
# This class is a simple way to access to configuration parameters
# of the Netmagis application.
#
# Methods:
# - setdb dbfd
#	set the database handle used to access parameters
# - class
#	returns all known classes
# - desc class-or-key
#	returns the description associated with class or key
# - keys [ class ]
#	returns all keys associed with the class, or all known keys
# - keytype key
#	returns type of a given key, under the format {string|bool|text|menu x}
#	X is present only for the "menu" type.
# - keyhelp key
#	returns the help message associated with a key
# - get key
#	returns the value associated with a key
# - set key val
#	set the value associated with a key and returns an empty string or
#	an error message.
#

snit::type ::db-config {
    # database object
    variable dbo ""

    # configuration parameter specification
    # {{class class-spec} {class class-spec} ...}
    # class = class name
    # class-spec = {{key ro/rw type} {key ro/rw type} ...}
    variable configspec {
	{general
	    {datefmt rw {string}}
	    {dayfmt rw {string}}
	    {authmethod rw {menu {{pgsql Internal} {ldap {LDAP}} {casldap CAS}}}}
	    {authexpire rw {string}}
	    {authtoklen rw {string}}
	    {apiexpire rw {string}}
	    {wtmpexpire rw {string}}
	    {failloginthreshold1 rw {string}}
	    {faillogindelay1 rw {string}}
	    {failloginthreshold2 rw {string}}
	    {faillogindelay2 rw {string}}
	    {failipthreshold1 rw {string}}
	    {failipdelay1 rw {string}}
	    {failipthreshold2 rw {string}}
	    {failipdelay2 rw {string}}
	    {pageformat rw {menu {{a4 A4} {letter Letter}}} }
	    {schemaversion ro {string}}
	}
	{dns
	    {defuser rw {string}}
	}
	{dhcp
	    {dhcpdefdomain rw {string}}
	    {dhcpdefdnslist rw {string}}
	    {default_lease_time rw {string}}
	    {max_lease_time rw {string}}
	    {min_lease_time rw {string}}
	}
	{topo
	    {topoactive rw {bool}}
	    {defdomain rw {string}}
	    {topofrom rw {string}}
	    {topoto rw {string}}
	    {topographddelay rw {string}}
	    {toposendddelay rw {string}}
	    {topomaxstatus rw {string}}
	    {sensorexpire rw {string}}
	    {modeqexpire rw {string}}
	    {ifchangeexpire rw {string}}
	    {fullrancidmin rw {string}}
	    {fullrancidmax rw {string}}
	}
	{mac
	    {macactive rw {bool}}
	}
	{authcas
	    {casurl rw {string}}
	}
	{authldap
	    {ldapurl rw {string}}
	    {ldapbinddn rw {string}}
	    {ldapbindpw rw {string}}
	    {ldapbasedn rw {string}}
	    {ldapsearchlogin rw {string}}
	    {ldapattrlogin rw {string}}
	    {ldapattrname rw {string}}
	    {ldapattrgivenname rw {string}}
	    {ldapattrmail rw {string}}
	    {ldapattrphone rw {string}}
	    {ldapattrmobile rw {string}}
	    {ldapattrfax rw {string}}
	    {ldapattraddr rw {string}}
	}
	{authpgsql
	    {authpgminpwlen rw {string}}
	    {authpgmaxpwlen rw {string}}
	    {authpgmailfrom rw {string}}
	    {authpgmailreplyto rw {string}}
	    {authpgmailcc rw {string}}
	    {authpgmailbcc rw {string}}
	    {authpgmailsubject rw {string}}
	    {authpgmailbody rw {text}}
	    {authpggroupes rw {string}}
	}
    }

    #
    # Internal representation of parameter specification
    #
    # (class)			{<cl1> ... <cln>}
    # (class:<cl1>)		{<k1> ... <kn>}
    # (key:<k1>:type)		{string|bool|text|menu ...}
    # (key:<k1>:rw)		ro|rw
    #

    variable internal -array {}

    constructor {} {
	set internal(class) {}
	foreach class $configspec {

	    set classname [lindex $class 0]
	    lappend internal(class) $classname
	    set internal(class:$classname) {}

	    foreach key [lreplace $class 0 0] {
		lassign $key keyname keyrw keytype

		lappend internal(class:$classname) $keyname
		set internal(key:$keyname:type) $keytype
		set internal(key:$keyname:rw) $keyrw
	    }
	}
    }

    method setdb {db} {
	set dbo $db
    }

    # returns all classes
    method class {} {
	return $internal(class)
    }

    # returns textual description of the given class or key
    method desc {cork} {
	set r $cork
	if {[info exists internal(class:$cork)]} then {
	    set r [mc "cfg:$cork"]
	} elseif {[info exists internal(key:$cork:type)]} {
	    set r [mc "cfg:$cork:desc"]
	}
	return $r
    }

    # returns all keys associated with a class (default  : all classes)
    method keys {{class {}}} {
	if {[llength $class] == 0} then {
	    set class $internal(class)
	}
	set lk {}
	foreach c $class {
	    set lk [concat $lk $internal(class:$c)]
	}
	return $lk
    }

    # returns key rw/ro
    method keyrw {key} {
	set r ""
	if {[info exists internal(key:$key:rw)]} then {
	    set r $internal(key:$key:rw)
	}
	return $r
    }

    # returns key type
    method keytype {key} {
	set r ""
	if {[info exists internal(key:$key:type)]} then {
	    set r $internal(key:$key:type)
	}
	return $r
    }

    # returns key help
    method keyhelp {key} {
	set r $key
	if {[info exists internal(key:$key:type)]} then {
	    set r [mc "cfg:$key:help"]
	}
	return $r
    }

    # returns key value
    method get {key} {
	if {[info exists internal(key:$key:type)]} then {
	    set found 0
	    $dbo exec "SELECT * FROM global.config WHERE key = '$key'" tab {
		set val $tab(value)
		set found 1
	    }
	    if {! $found} then {
		switch $internal(key:$key:type) {
		    string	{ set val "" }
		    bool	{ set val 0 }
		    set text	{ set val "" }
		    set menu	{ set val "" }
		    default	{ set val "type unknown" }
		}
	    }
	} else {
	    error "Unknown configuration key '$key'"
	}
	return $val
    }

    # set key value
    # returns empty string if ok, or an error message
    method set {key val} {
	if {[info exists internal(key:$key:rw)]} then {
	    if {$internal(key:$key:rw) eq "rw"} then {
		set r ""
		set k [pg_quote $key]
		set v [pg_quote $val]

		set sql "DELETE FROM global.config WHERE key = $k"
		$dbo exec $sql

		set sql "INSERT INTO global.config (key, value) VALUES ($k, $v)"
		$dbo exec $sql
	    } else {
		error "Cannot modify read-only key '$key'"
	    }
	} else {
	    error "Unknown configuration key '$key'"
	}

	return $r
    }
}


##############################################################################
# PostgreSQL interface
##############################################################################

snit::type ::db {
    # Database prefix in configuration file
    variable dbprefix

    # Access to local configuration file
    variable lc

    # Database handler (result of pg_connect)
    variable dbfd "not connected"

    # Expected schema version
    variable appver ""
    variable nver ""

    # prefix: "dns" or "mac" (according to local configuration file)
    # confobj: access to the local configuration file
    # versioncheck: version number (such as 3.0.5beta1) or ""

    method init {prefix confobj {versioncheck {}}} {
	set dbprefix $prefix
	set lc $confobj
	if {$versioncheck ne ""} then {
	    if {! [regsub {^(\d+)\.(\d+).*} $versioncheck {\1\2} nver]} then {
		error "Netmagis version '$versioncheck' unrecognized"
	    }
	    set appver $versioncheck
	}
    }

    method disconnect {} {
	catch {pg_disconnect $dbfd}
	set dbfd "not connected"
    }

    method reconnect {} {
	if {$dbfd ne "not connected"} then {
	    return {}
	}

	#
	# Get conninfo string
	#
	set conninfo {}
	foreach f {{host host} {port port} {dbname name}
			    {user user} {password password}} {
	    lassign $f connkey suffix
	    set v [$lc get "${dbprefix}db${suffix}"]
	    regsub {['\\]} $v {\\&} v
	    lappend conninfo "$connkey='$v'"
	}
	set conninfo [join $conninfo " "]

	try {
	    set dbfd [pg_connect -conninfo $conninfo]
	} on error msg {
	    error "Database $dbprefix unavailable"
	}

	if {$appver ne ""} then {
	    set sql "SELECT value FROM global.config
				    WHERE key = 'schemaversion'"
	    set sver ""
	    $self exec $sql tab {
		set sver $tab(value)
	    }
	    if {$sver != $nver} then {
		error "DB version $sver does not match app version $appver"
	    }
	}
    }

    # exec sql [tab script]
    method exec {sql args} {
	try {
	    switch [llength $args] {
		0 {
		    uplevel 1 [list pg_execute $dbfd $sql]
		}
		2 {
		    lassign $args tab script
		    uplevel 1 [list pg_execute -array $tab $dbfd $sql $script]
		}
		default {
		    error {wrong # args: should be "exec sql ?tab script?"}
		}
	    }

	} trap {NONE} {msg err} {
	    # Pgtcl 1.9 returns errorcode == NONE
	    set errinfo [dict get $err -errorinfo]
	    if {[regexp "^PGRES_FATAL_ERROR" $errinfo]} then {
		# reset db handle
		set info [pg_dbinfo status $dbfd]
		if {$info ne "connection_ok"} then {
		    $self disconnect
		}
		error $msg
	    } else {
		# it is not a Pgtcl error
		error $msg $errinfo NONE
	    }
	}
    }

    # lock {table ...} script
    method lock {ltab script} {
	# Lock tables
	lappend sql "BEGIN WORK"
	foreach t $ltab {
	    lappend sql "LOCK $t"
	}
	$self exec [join $sql ";"]

	try {
	    uplevel 1 $script

	} on ok {res dict} {
	    # lock ... ok => commit
	    $self exec "COMMIT WORK"
	    return -code ok $res

	} on return {res dict} {
	    # lock ... ok => commit + return
	    $self exec "COMMIT WORK"
	    return -code return $res

	} on continue {res dict} {
	    # lock ... continue => commit + continue (a loop must exist)
	    $self exec "COMMIT WORK"
	    return -code continue $res

	} on break {res dict} {
	    # lock ... break => commit + break (a loop must exist)
	    $self exec "COMMIT WORK"
	    return -code break $res

	} on error {res dict} {
	    # lock ... error => abort with an error
	    $self exec "ABORT WORK"
	    error $res $::errorInfo

	} on 6 {res dict} {
	    # lock ... abort => abort without error
	    $self exec "ABORT WORK"
	    return -code ok $res

	}
    }

    # valid only inside a "lock ... script" block
    # => exit the script with the result, without any error
    method abort {{res {}}} {
	return -code 6 $res
    }
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
    variable idcor -1
    variable idgrp -1


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

    method idcor {} {
	if {$idcor == -1} then {
	    set qlogin [pg_quote $login]
	    set sql "SELECT idcor FROM global.nmuser WHERE login = $qlogin"
	    $dbo exec $sql tab {
		set idcor $tab(idcor)
	    }
	    if {$idcor == -1} then {
		error "login '$login' not found"
	    }
	}
	return $idcor
    }

    method idgrp {} {
	if {$idgrp == -1} then {
	    set qlogin [pg_quote $login]
	    set sql "SELECT idgrp FROM global.nmuser WHERE login = $qlogin"
	    $dbo exec $sql tab {
		set idgrp $tab(idgrp)
	    }
	    if {$idgrp == -1} then {
		error "login '$login' not found"
	    }
	}
	return $idgrp
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

	set qlogin [::pgsql::quote $login]
	set sql "SELECT p.idview
			FROM dns.p_view p, dns.view v, global.nmuser u
			WHERE p.idgrp = u.idgrp
			    AND p.idview = v.idview
			    AND u.login = '$qlogin'
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

	set qlogin [::pgsql::quote $login]
	set sql "SELECT p.iddom
			FROM dns.p_dom p, dns.domain d, global.nmuser u
			WHERE p.idgrp = u.idgrp
			    AND p.iddom = d.iddom
			    AND u.login = '$qlogin'
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

    switch -regexp -matchvar last $uri {
	{^/static/([[:alnum:]][-.[:alnum:]]*)$} {
	    if {$meth eq "get"} then {
		handle-static [lindex $last 1]
	    } else {
		::scgiapp::scgi-error 405 {Method not allowed}
	    }
	}
	default {
	    #
	    # Try API
	    # Search a suitable route among all routes registered
	    # in the route() array by the api-handler procedure
	    #

	    global route

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
		# - script: script to execute for this route
		#

		lassign $r re vars paramspec authneeded script

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
		# Run the script with all parameters imported
		# Script is run with the following variables
		#
		# - parms() array
		# - ::parm::<query-parameter-or-uri-variable>
		# - login ???
		# - may be other variables
		#
		::scgiapp::import-param ::parm $tpar
		eval $script
	    } else {
		::scgiapp::scgi-error 404 "URI '$uri' not found"
	    }
	}
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

	# Check parameters and 
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

proc handle-static {page} {
    global conf

    set path $conf(static-dir)/$page

    if {[file exists $path]} then {
	# Determine Content-Type, based on file extension
	switch -glob [string tolower $page] {
	    *.png	{ set ct "image/png" ; set bin 1 }
	    *.gif	{ set ct "image/gif" ; set bin 1 }
	    *.jpg	{ set ct "image/jpeg" ; set bin 1 }
	    *.jpeg	{ set ct "image/jpeg" ; set bin 1 }
	    *.pdf	{ set ct "application/pdf" ; set bin 1 }
	    *.html	{ set ct "text/html" ; set bin 0 }
	    default	{ set ct "text/plain" ; set bin 0 }
	}

	if {[catch {set fd [open $path "r"]} msg]} then {
	    ::scgiapp::scgi-error 404 "Cannot open '$page' ($msg)"
	}
	if {$bin} then {
	    fconfigure $fd -translation binary
	}
	set content [read $fd]
	close $fd

	::scgiapp::set-header Content-type $ct
	::scgiapp::set-body $content $bin
    } else {
	::scgiapp::scgi-error 404 "'$page' not found"
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

    lappend route($method) [list $re $vars $paramspec $authneeded $script]
}

api-handler get {/login} no {
	user	1
	passwd	1
    } {

    ::scgiapp::set-json {{a 1 b 2 c {areuh tagada bouzouh}}}

}

api-handler get {/views} yes {
    } {
    set idgrp [::u idgrp]
    set sql "SELECT array_to_json (array_agg (row_to_json (t))) AS res
		    FROM (
			SELECT v.name, '/views/' || v.idview AS link,
				    p.selected, p.sort
			    FROM dns.view v
			    INNER JOIN dns.p_view p
				ON v.idview = p.idview
			    WHERE p.idgrp = $idgrp
			    ORDER BY p.sort ASC, v.name ASC
		    ) t
		"
    set r ""
    ::dbdns exec $sql tab {
	set r $tab(res)
    }
    ::scgiapp::set-header Content-Type application/json
    ::scgiapp::set-body $r
}

api-handler get {/views/([0-9]+:idview)} yes {
    } {
    set idgrp [::u idgrp]
    set sql "SELECT row_to_json (t) AS res
		    FROM (
			SELECT v.name, p.selected, p.sort
			    FROM dns.view v
			    INNER JOIN dns.p_view p
				ON v.idview = p.idview
			    WHERE p.idgrp = $idgrp
				AND v.idview = $::parm::idview
		    ) t
		"
    set r ""
    ::dbdns exec $sql tab {
	set r $tab(res)
    }
    if {$r eq ""} then {
	::scgiapp::scgi-error 404 "View '$::parm::idview' not found"
    }
    ::scgiapp::set-header Content-Type application/json
    ::scgiapp::set-body $r
}

api-handler get {/names} yes {
	view	0
	cidr	0
	domain	0
    } {
    puts "/names => view=$::parm::view"
}

api-handler get {/names/([0-9]+:idrr)} yes {
	fields	0
    } {

    puts stderr "BINGO !"
    puts "idrr=$::parm::idrr"
    puts "fields=$::parm::fields"

    if {! [read-rr-by-id $dbfd(dns) $::parm::idrr trr]} then {
	puts "NOT FOUND"
    } else {
	puts [array get trr]
    }
}

try {
    thread-init $conffile
} on error msg {
    puts stderr $msg
    exit 1
}
