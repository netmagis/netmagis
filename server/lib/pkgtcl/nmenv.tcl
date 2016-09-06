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

  # end of snit class
  }
}
