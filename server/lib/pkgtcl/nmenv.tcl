package require Tcl 8.6
package require snit

package provide nmenv 0.1

#
# This package provides a bunch of useful methods for Netmagis.
# Most of them are "lazy-loaded".
# To begin to use it, one just have to provide:
#	- a database object (see the pgdb package)
#	- a login
#

namespace eval ::nmenv {
  snit::type nmenv {

    ###########################################################################
    # database stuff
    ###########################################################################

    # database object
    variable db

    method setdb {dbo} {
	set db $dbo
    }

    ###########################################################################
    # user characteristics
    ###########################################################################

    #
    # Netmagis user characteristics class
    #
    # This class stores all informations related to current Netmagis user
    #
    # Methods:
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
    # - dhcpprofname id
    #	returns name associated to dhcpprofile id (or empty string if error)
    # - dhcpprofid name
    #	returns dhcpprofile id associated to dhcpprofile name (or -1 if error)
    # - myiddhcpprof
    #	get all authorized dhcpprofile ids
    # - isalloweddhcpprof id
    #	check if a dhcpprofile is authorized (1 if ok, 0 if not)
    #
    # - hinfoname id
    #	returns name associated to hinfo id (or empty string if error)
    # - hinfoid name
    #	returns hinfo id associated to hinfo name (or -1 if error)
    # - myidhinfo
    #	get all hinfo ids
    # - isallowedhinfo id
    #	check if a hinfo is present (1 if ok, 0 if not)
    #

    # keep track of lazy-loaded informations
    variable loaded -array {
	login	0
	cap	0
	views	0
	domains	0
	dhcpprofs 0
	hinfos	0
    }

    # real login of user (the one which is authenticated)
    variable rlogin ""

    # effective login of user (the one we substitued for)
    variable elogin ""

    # ids of user
    variable idanon -array {
	idcor -1
	idgrp -1
	present 0
	p_admin 0
	p_smtp 0
	p_ttl 0
	p_mac 0
	p_genl 0
    }

    variable ids -array [array get idanon]

    variable cap {}

    # Group management
    # allgroups(id:<id>)=name
    # allgroups(name:<name>)=id
    variable allgroups -array {}

    # View management
    # allviews(id:<id>)=name
    # allviews(name:<name>)=id
    variable allviews -array {}
    # authviews(<id>)=1
    variable authviews -array {}
    # myviewids : sorted list of views
    variable myviewids {}

    # Domain management
    # alldom(id:<id>)=name
    # alldom(name:<name>)=id
    variable alldom -array {}
    # authdom(<id>)=1
    variable authdom -array {}
    # myiddoms : sorted list of domains
    variable myiddom {}

    # DHCP profile management
    # alldhcpprof(id:<id>)=name
    # alldhcpprof(name:<name>)=id
    variable alldhcpprof -array {}
    # authdhcpprof(<id>)=1
    variable authdhcpprof -array {}
    # myiddhcpprofs : sorted list of dhcp profiles
    variable myiddhcpprof {}

    # Hinfo management
    # allhinfo(id:<id>)=name
    # allhinfo(name:<name>)=id
    variable allhinfo -array {}
    # myidhinfo : sorted list of hinfo
    variable myidhinfo {}

    proc load-ids {selfns login} {
	#
	# Get idcor and group info
	#

	array set ids [array get idanon]
	if {$login ne ""} then {
	    set qlogin [pg_quote $login]
	    set sql "SELECT u.idcor, u.present, g.*
			    FROM global.nmuser u
				NATURAL INNER JOIN global.nmgroup g
				WHERE login = $qlogin"
	    set found 0
	    $db exec $sql tab {
		array set ids [array get tab]
		set found 1
	    }
	    if {! $found} then {
		error "login '$login' not found"
	    }
	}
    }

    # $self login => return the current login
    # $self login "" => set the new login to "anonymous"
    # $self login joe => the the new login to "joe"

    method login {{newlogin {:get}}} {
	if {$newlogin ne ":get"} then {
	    #
	    # Reset lazy-load infos
	    #

	    foreach i [array names loaded] {
		set loaded($i) 0
	    }
	    set rlogin $newlogin
	    set elogin $newlogin
	    load-ids $selfns $rlogin
	    set loaded(login) 1
	}
	return $rlogin
    }

    method setuid {{newlogin {:get}}} {
	if {! $loaded(login)} then {
	    error "setuid called before login"
	}

	if {$newlogin ne ":get"} then {
	    # silently fails if real (or existing effective) user is not admin
	    if {$ids(p_admin) != 0} then {
		#
		# Reset lazy-load infos
		#

		foreach i [array names loaded] {
		    if {$i ne "login"} then {
			set loaded($i) 0
		    }
		}
		set elogin $newlogin
		load-ids $selfns $elogin
		set loaded(login) 1
	    }
	}
	return $elogin
    }

    method idcor {} {
	return $ids(idcor)
    }

    method idgrp {} {
	return $ids(idgrp)
    }

    # return a list with all authorized (user, group or global) capabilities
    #	- any: any user, even anonymous or non-preesent ones
    #	- logged: currently logged-in valid user (interactive or via an app)
    #	- admin: admin user
    #	- smtp: right to declare smtp access
    #	- ttl: right to modify ttl
    #	- mac: right to access mac module and mac module activated
    #	- topo: topo module activated
    #	- topogenl: right to generate topo links
    #	- pgauth: internal auth active
    #	- pgadmin: admin, internal auth admin and internal auth activated
    #	- setuid: currently acting as another user

    method capabilities {} {
	if {! $loaded(cap)} then {
	    if {! $loaded(login)} then {
		error "login not initialized"
	    }
	    set cap {any}
	    if {$elogin ne ""} then {
		#
		# Get global config values
		#

		set sql "SELECT key, value
			    FROM global.config
			    WHERE key = 'topoactive'
				OR key = 'macactive'
				OR key = 'authmethod'"
		::dbdns exec $sql tab {
		    set cfg($tab(key)) $tab(value)
		}

		lappend cap "logged"
		if {$ids(p_admin)} then {
		    lappend cap admin
		}
		if {$ids(p_smtp)} then {
		    lappend cap smtp
		}
		if {$ids(p_ttl)} then {
		    lappend cap ttl
		}
		if {$cfg(topoactive)} then {
		    lappend cap topo
		    if {$ids(p_genl)} then {
			lappend cap "topogenl"
		    }
		}
		if {$ids(p_mac) && $cfg(macactive)} then {
		    lappend cap mac
		}
		if {$cfg(authmethod) eq "pgsql"} then {
		    lappend cap "pgauth"
		    set qlogin [pg_quote $elogin]
		    set sql "SELECT r.admin
				    FROM pgauth.realm r
					NATURAL INNER JOIN pgauth.member m
				    WHERE login = $qlogin"
		    ::dbdns exec $sql tab {
			if {$tab(admin)} then {
			    lappend cap "pgadmin"
			}
		    }
		}
		if {$elogin ne $rlogin} then {
		    lappend cap "setuid"
		}
	    }
	}
	return $cap
    }

    #
    # Group management
    #

    proc load-groups {selfns} {
	array unset allgroups

	set sql "SELECT * FROM global.nmgroup"
	$db exec $sql tab {
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

    #
    # View management
    #

    proc load-views {selfns} {
	array unset allviews
	array unset authviews
	set myviewids {}

	set sql "SELECT * FROM dns.view"
	$db exec $sql tab {
	    set idview $tab(idview)
	    set name   $tab(name)
	    set allviews(id:$idview) $name
	    set allviews(name:$name) $idview
	}

	set sql "SELECT p.idview
			FROM dns.p_view p
			    NATURAL INNER JOIN dns.view v
			WHERE p.idgrp = $ids(idgrp)
			ORDER BY p.sort ASC, v.name ASC"
	$db exec $sql tab {
	    set idview $tab(idview)
	    set authviews($idview) 1
	    lappend myviewids $tab(idview)
	}

	set loaded(views) 1
    }

    method viewname {id} {
	if {! $loaded(views)} then {
	    load-views $selfns
	}
	set r -1
	if {[info exists allviews(id:$id)]} then {
	    set r $allviews(id:$id)
	}
	return $r
    }

    method viewid {name} {
	if {! $loaded(views)} then {
	    load-views $selfns
	}
	set r ""
	if {[info exists allviews(name:$name)]} then {
	    set r $allviews(name:$name)
	}
	return $r
    }

    method myviewids {} {
	if {! $loaded(views)} then {
	    load-views $selfns
	}
	return $myviewids
    }

    method isallowedview {id} {
	if {! $loaded(views)} then {
	    load-views $selfns
	}
	return [info exists authviews($id)]
    }

    #
    # Domain management
    #

    proc load-domains {selfns} {
	array unset alldom
	array unset authdom
	set myiddom {}

	set sql "SELECT * FROM dns.domain"
	$db exec $sql tab {
	    set iddom $tab(iddom)
	    set name   $tab(name)
	    set alldom(id:$iddom) $name
	    set alldom(name:$name) $iddom
	}

	set sql "SELECT p.iddom
			FROM dns.p_dom p
			    NATURAL INNER JOIN dns.domain d
			WHERE p.idgrp = $ids(idgrp)
			ORDER BY p.sort ASC, d.name ASC"
	$db exec $sql tab {
	    set iddom $tab(iddom)
	    set authdom($iddom) 1
	    lappend myiddom $tab(iddom)
	}

	set loaded(domains) 1
    }

    method domainname {id} {
	if {! $loaded(domains)} then {
	    load-domains $selfns
	}
	set r -1
	if {[info exists alldom(id:$id)]} then {
	    set r $alldom(id:$id)
	}
	return $r
    }

    method domainid {name} {
	if {! $loaded(domains)} then {
	    load-domains $selfns
	}
	set r ""
	if {[info exists alldom(name:$name)]} then {
	    set r $alldom(name:$name)
	}
	return $r
    }

    method myiddom {} {
	if {! $loaded(domains)} then {
	    load-domains $selfns
	}
	return $myiddom
    }

    method isalloweddom {id} {
	if {! $loaded(domains)} then {
	    load-domains $selfns
	}
	return [info exists authdom($id)]
    }

    #
    # DHCP profile management
    #

    proc load-dhcpprofs {selfns} {
	array unset alldhcpprof
	array unset authdhcpprof
	set myiddhcpprof {}

	set sql "SELECT * FROM dns.dhcpprofile"
	$db exec $sql tab {
	    set iddhcpprof $tab(iddhcpprof)
	    set name       $tab(name)
	    set alldhcpprof(id:$iddhcpprof) $name
	    set alldhcpprof(name:$name)     $iddhcpprof
	}

	set sql "SELECT p.iddhcpprof
			FROM dns.p_dhcpprofile p
			    NATURAL INNER JOIN dns.dhcpprofile d
			WHERE p.idgrp = $ids(idgrp)
			ORDER BY p.sort ASC, d.name ASC"
	$db exec $sql tab {
	    set iddhcpprof $tab(iddhcpprof)
	    set authdhcpprof($iddhcpprof) 1
	    lappend myiddhcpprof $tab(iddhcpprof)
	}

	set loaded(dhcpprofs) 1
    }

    method dhcpprofname {id} {
	if {! $loaded(dhcpprofs)} then {
	    load-dhcpprofs $selfns
	}
	set r -1
	if {[info exists alldhcpprof(id:$id)]} then {
	    set r $alldhcpprof(id:$id)
	}
	return $r
    }

    method dhcpprofid {name} {
	if {! $loaded(dhcpprofs)} then {
	    load-dhcpprofs $selfns
	}
	set r ""
	if {[info exists alldhcpprof(name:$name)]} then {
	    set r $alldhcpprof(name:$name)
	}
	return $r
    }

    method myiddhcpprof {} {
	if {! $loaded(dhcpprofs)} then {
	    load-dhcpprofs $selfns
	}
	return $myiddhcpprof
    }

    method isalloweddhcpprof {id} {
	if {! $loaded(dhcpprofs)} then {
	    load-dhcpprofs $selfns
	}
	return [info exists authdhcpprof($id)]
    }

    #
    # Hinfo management
    #

    proc load-hinfos {selfns} {
	array unset allhinfo
	set myidhinfo {}

	set sql "SELECT * FROM dns.hinfo
			ORDER BY sort ASC, name ASC"
	$db exec $sql tab {
	    set idhinfo $tab(idhinfo)
	    set name    $tab(name)
	    set allhinfo(id:$idhinfo) $name
	    set allhinfo(name:$name)  $idhinfo
	    if {$tab(present)} then {
		lappend myidhinfo $idhinfo
	    }
	}

	set loaded(hinfos) 1
    }

    method hinfoname {id} {
	if {! $loaded(hinfos)} then {
	    load-hinfos $selfns
	}
	set r -1
	if {[info exists allhinfo(id:$id)]} then {
	    set r $allhinfo(id:$id)
	}
	return $r
    }

    method hinfoid {name} {
	if {! $loaded(hinfos)} then {
	    load-hinfos $selfns
	}
	set r ""
	if {[info exists allhinfo(name:$name)]} then {
	    set r $allhinfo(name:$name)
	}
	return $r
    }

    method myidhinfo {} {
	if {! $loaded(hinfos)} then {
	    load-hinfos $selfns
	}
	return $myidhinfo
    }

    method isallowedhinfo {id} {
	if {! $loaded(hinfos)} then {
	    load-hinfos $selfns
	}
	return [info exists allhinfo(id:$id)]
    }

    ###########################################################################
    # logging stuff
    ###########################################################################

    variable subsys "netmagis"
    variable table "global.log"

    method writelog {event msg {date {}} {wlogin {}} {ip {}}} {
	if {$ip eq ""} then {
	    set ip [::scgi::get-header "REMOTE_ADDR"]
	}

	if {$wlogin eq ""} then {
	    set wlogin $rlogin
	}

	foreach v {event wlogin ip msg} {
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
		    VALUES ($dateval $sub, $event, $wlogin, $ip, $msg)"
	$db exec $sql
    }

    ##########################################################################
    # Configuration parameters from database
    ##########################################################################

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

    variable cfinternal -array {}

    constructor {} {
	set cfinternal(class) {}
	foreach class $configspec {

	    set classname [lindex $class 0]
	    lappend cfinternal(class) $classname
	    set cfinternal(class:$classname) {}

	    foreach key [lreplace $class 0 0] {
		lassign $key keyname keyrw keytype

		lappend cfinternal(class:$classname) $keyname
		set cfinternal(key:$keyname:type) $keytype
		set cfinternal(key:$keyname:rw) $keyrw
	    }
	}
    }

    # returns all classes
    method confclass {} {
	return $internal(class)
    }

    # returns textual description of the given class or key
    method confdesc {cork} {
	set r $cork
	if {[info exists cfinternal(class:$cork)]} then {
	    set r [mc "cfg:$cork"]
	} elseif {[info exists cfinternal(key:$cork:type)]} {
	    set r [mc "cfg:$cork:desc"]
	}
	return $r
    }

    # returns all keys associated with a class (default  : all classes)
    method confkeys {{class {}}} {
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
    method confkeyrw {key} {
	set r ""
	if {[info exists cfinternal(key:$key:rw)]} then {
	    set r $internal(key:$key:rw)
	}
	return $r
    }

    # returns key type
    method confkeytype {key} {
	set r ""
	if {[info exists cfinternal(key:$key:type)]} then {
	    set r $internal(key:$key:type)
	}
	return $r
    }

    # returns key help
    method confkeyhelp {key} {
	set r $key
	if {[info exists cfinternal(key:$key:type)]} then {
	    set r [mc "cfg:$key:help"]
	}
	return $r
    }

    # returns key value
    method confget {key} {
	if {[info exists cfinternal(key:$key:type)]} then {
	    set found 0
	    $db exec "SELECT * FROM global.config WHERE key = '$key'" tab {
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
    method confset {key val} {
	if {[info exists cfinternal(key:$key:rw)]} then {
	    if {$internal(key:$key:rw) eq "rw"} then {
		set r ""
		set k [pg_quote $key]
		set v [pg_quote $val]

		set sql "DELETE FROM global.config WHERE key = $k"
		$db exec $sql

		set sql "INSERT INTO global.config (key, value) VALUES ($k, $v)"
		$db exec $sql
	    } else {
		error "Cannot modify read-only key '$key'"
	    }
	} else {
	    error "Unknown configuration key '$key'"
	}

	return $r
    }

  # end of snit class
  }
}
