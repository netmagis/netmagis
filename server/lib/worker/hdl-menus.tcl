#
# Tree structure of Netmagis Web menus
#
# Each list element is either:
#	{menu <title> <cap> <menuitem> <menuitem> ...}
#	{item <title> <cap> <url>}
#

array set menus_links {
    left {
	{menu {DNS} dns
	    {item {Consult}			dns	net}
	    {item {Add}				dns	add}
	    {item {Delete}			dns	del}
	    {item {Modify}			dns	mod}
	    {item {Mail roles}			dns	mail}
	    {item {DHCP ranges}			dns	dhcprange}
	    {item {Password}			pgauth	pgapasswd}
	    {item {Where am I?}			dns	search?q=_}
	    }
	{menu {Topo} topo
	    {item {Equipments}			topo	eq}
	    {item {Vlans}			topo	l2}
	    {item {Networks}			topo	l3}
	    {item {Link number}			topogenl	genl}
	    {item {Status}			admin	topotop}
	    }
	{menu {MAC} mac
	    {item {Index}			mac	macindex}
	    {item {Search}			mac	mac}
	    {item {Inactive addr.}		mac	ipinact}
	    {item {Stats}			mac	macstat}
	    }
	{menu {Admin} admin
	    {item {List MX}			admin	admlmx}
	    {item {List networks}		admin	lnet}
	    {item {List users}			admin	lusers}
	    {item {Connected users}		admin	who?action=now}
	    {item {Last connections}		admin	who?action=last}
	    {item {Modify organizations}	admin	admref?type=org}
	    {item {Modify communities}		admin	admref?type=comm}
	    {item {Modify machine types}	admin	admref?type=hinfo}
	    {item {Modify networks}		admin	admref?type=net}
	    {item {Modify domains}		admin	admref?type=domain}
	    {item {Modify mailhost}		admin	admmrel}
	    {item {Modify MX}			admin	admmx}
	    {item {Modify views}		admin	admref?type=view}
	    {item {Modify zones}		admin	admref?type=zone}
	    {item {Modify rev IPv4 zones}	admin	admref?type=zone4}
	    {item {Modify rev IPv6 zones}	admin	admref?type=zone6}
	    {item {Modify DHCP profiles}	admin	admref?type=dhcpprof}
	    {item {Modify Vlans}		admin	admref?type=vlan}
	    {item {Modify equipment types}	admin	admref?type=eqtype}
	    {item {Modify equipments}		admin	admref?type=eq}
	    {item {Modify configuration commands}	admin	admref?type=confcmd}
	    {item {Modify Graphviz attributes}	admin	admref?type=dotattr}
	    {item {Modify users and groups}	admin	admgrp}
	    {item {Force zone generation}	admin	admzgen}
	    {item {Application parameters}	admin	admpar}
	    {item {Statistics by user}		admin	statuser}
	    {item {Statistics by organization}	admin	statorg}
	    }
	{menu {Auth} pgadmin
	    {item {List accounts}		pgadmin	pgaacc?action=list}
	    {item {Print accounts}		pgadmin	pgaacc?action=print}
	    {item {Add account}			pgadmin	pgaacc?action=add}
	    {item {Modify account}		pgadmin	pgaacc?action=mod}
	    {item {Remove account}		pgadmin	pgaacc?action=del}
	    {item {Change account password}	pgadmin	pgaacc?action=passwd}
	    {item {List realms}			pgadmin	pgarealm?action=list}
	    {item {Add realm}			pgadmin	pgarealm?action=add}
	    {item {Modify realm}		pgadmin	pgarealm?action=mod}
	    {item {Remove realm}		pgadmin	pgarealm?action=del}
	    }
    }
    srch {item {Search} dns search}
    user {menu {%USER%} dns
	    {item {Profile}			dns	profile.html}
	    {item {Sessions}			dns	sessions.html}
	    {separator {}			admin	}
	    {item {Sudo}			admin	sudo.html}
	    {item {Back to my id}		suid	sudo.html}
	    {separator {}			dns	}
	    {item {Disconnect}			dns	logout.html}
    }
    lang {menu {[%LANG%]} dns
	    {item {[en]}			dns	lang?l=en}
	    {item {[fr]}			dns	lang?l=fr}
    }
}

##############################################################################

api-handler get {/menus} yes {
    } {
    global menus_links

    #
    # Get capabilities
    #

    set curcap {dns}

    if {[::config get "topoactive"]} then {
	lappend curcap "topo"
    }
    if {[::config get "macactive"] && [::u cap p_mac]} then {
	lappend curcap "mac"
    }
    if {[::u cap p_genl]} then {
	lappend curcap "topogenl"
    }
    if {[::u cap p_admin]} then {
	lappend curcap "admin"
    }
    if {[::config get "authmethod"] eq "pgsql"} then {
	lappend curcap "pgauth"
	set qlogin [pg_quote [::u login]]
	set sql "SELECT r.admin
			FROM pgauth.realm r, pgauth.member m
			WHERE r.realm = m.realm
			    AND login = $qlogin"
	::dbdns exec $sql tab {
	    if {[::u cap p_admin]} then {
		lappend curcap "pgadmin"
	    }
	}
    }

    #
    # Get links according to capabilities
    #

    set left [get-links $_prefix $menus_links(left) $curcap]
    set srch [get-links $_prefix $menus_links(srch) $curcap]
    set user [get-links $_prefix $menus_links(user) $curcap]
    set lang [get-links $_prefix $menus_links(lang) $curcap]

    regsub {%USER%} $user [::u login] user
    regsub {%LANG%} $lang [mclocale] lang

    set j [format {{"left":%1$s, "search":%2$s, "user":%3$s, "lang":%4$s}} \
			$left $srch $user $lang]

    ::scgi::set-header Content-Type application/json
    ::scgi::set-body $j
}

proc get-links {prefix links curcap} {
    set r {}
    if {[lindex $links 0] in {menu item separator}} then {
	lassign $links type title cap value
	if {$cap in $curcap} then {
	    set mct [mc $title]
	    switch $type {
		menu {
		    set r [get-links $prefix [lreplace $links 0 2] $curcap]
		    if {$r ne {[]}} then {
			set r [format {{"title": "%1$s", "items": %2$s}} \
					$mct $r]
		    }
		}
		item {
		    set url "$prefix/$value"
		    set r [format {{"title": "%1$s", "url": "%2$s"}} \
					$mct $url]
		}
		separator {
		    set r [format {{"title": "", "url": ""}}]
		}
		default {
		    ::scgi::serror 500 {Internal error}
		}
	    }
	}
    } else {
	foreach l $links {
	    set r2 [get-links $prefix $l $curcap]
	    if {$r2 ne {} && $r2 ne {[]}} then {
		lappend r $r2
	    }
	}
	set r [format {[%s]} [join $r ","]]
    }

    return $r
}
