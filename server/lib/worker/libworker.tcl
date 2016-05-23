package require Pgtcl
package require json

#
# Checks if the selected views are authorized for this user
#
# Input:
#   - parameters:
#	- views : list of view ids given by the user
# Output:
#   - return value: empty string or error message
#
# History
#   2012/10/30 : pda/jean : design
#   2012/10/31 : pda/jean : use nmuser class
#

proc check-views {views} {
    set msg ""

    if {[llength $views] == 0} then {
	set msg [mc "No view selected"]

    } else {
	#
	# Check authorized views
	#

	set bad {}
	foreach id $views {
	    if {! [::u isallowedview $id]} then {
		set name [::u viewname $id]
		if {$name eq ""} then {
		    set name $id
		}
		lappend bad $name
	    }
	}

	if {[llength $bad]> 0} then {
	    set bad [join $bad ", "]
	    set msg [mc "You don't have access to these views: %s" $bad]
	}
    }

    return $msg
}

#
# Get all informations associated with a name
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- name : name to search for
#	- iddom : id of the domain in which to search for the name
#	- idview: view id
#	- _trr : empty array
# Output:
#   - return value: 1 if ok, 0 if not found
#   - _trr parameter : see read-rr-by-id
#
# History
#   2002/04/11 : pda/jean : design
#   2002/04/19 : pda/jean : add name and iddom
#   2002/04/19 : pda/jean : use read-rr-by-id
#   2010/11/29 : pda      : i18n
#   2013/04/05 : pda/jean : add view
#

proc read-rr-by-name {dbfd name iddom idview _trr} {
    upvar $_trr trr

    set qname [pg_quote $name]
    set where "name = $qname AND iddom = $iddom AND idview = $idview"
    return [read-rr $dbfd trr $where]
}

proc read-rr-by-id {dbfd idrr _trr} {
    upvar $_trr trr

    return [read-rr $dbfd trr "idrr = $idrr"]
}

#
# Get all informations associated with a RR.
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- idrr : RR id to search for
#	- _trr : empty array
# Output:
#   - return value: 1 if ok, 0 if not found
#   - parameter _trr : (see dns.full_rr_id SQL view)
#
# History
#   2002/04/19 : pda/jean : design
#   2002/06/02 : pda/jean : hinfo becomes an index in a table
#   2004/02/06 : pda/jean : add mailrole, mailaddr and roleweb
#   2004/08/05 : pda/jean : simplification and add mac
#   2005/04/08 : pda/jean : add dhcpprofil
#   2008/07/24 : pda/jean : add sendsmtp
#   2010/10/31 : pda      : add ttl
#   2010/11/29 : pda      : i18n
#   2012/10/08 : pda/jean : views
#   2013/04/05 : pda/jean : temporary hack for views
#   2013/04/10 : pda/jean : remove roleweb
#   2016/05/13 : pda/jean : use SQL view
#

proc read-rr {dbfd _trr where} {
    upvar $_trr trr

    catch {unset trr}
    set found 0
    set sql "SELECT row_to_json (r) FROM dns.full_rr_id r WHERE $where"
    $dbfd exec $sql tab {
	array set trr [::json::json2dict $tab(row_to_json)]
	set found 1
    }

    if {! $found} then {
	set l {idrr name iddom domain domainlink
		idview view viewlink mac
		idhinfo hinfo hinfolink
		comment respname respmail
		dhcpprof dhcpproflink iddhcpprof
		sendsmtp ttl
		user userlink idcor
		lastmod
		idcname cname cnamelink
		aliases
		idmboxhost idmboxhostview mboxhost mboxhostlink
		mailaddr
		mx mxtarg
		ip
		}
	foreach c $l {
	    set trr($c) {}
	}
    }

    return $found
}

#
# Get RR information filtered for a view
#
# XXX: remove view
#
# Input:
#   - parameters:
#       - _trr : see read-rr-by-id
#	- idview : view
# Output:
#   - return value: list of IP addresses
#
# History
#   2012/10/08 : pda/jean : design
#

proc rr-ip-by-view {_trr idview} {
    upvar $_trr trr

    return $trr(ip)
}

proc rr-cname-by-view {_trr idview} {
    upvar $_trr trr

    return $trr(cname)
}

proc rr-aliases-by-view {_trr idview} {
    upvar $_trr trr

    set laliases {}
    if [
    foreach a $trr(aliases) {
	lappend laliases [dict get $a idalias]
    }
    return $laliases
}

proc rr-mx-by-view {_trr idview} {
    upvar $_trr trr

    set lmx {}
    foreach m $trr(mx) {
	set prio [dict get $m prio]
	set idrr [dict get $m idmx]
	lappend lmx [list $prio $idrr]
    }
    return $lmx
}

proc rr-mxtarg-by-view {_trr idview} {
    upvar $_trr trr

    set lmxt {}
    foreach m $trr(mxtarg) {
	lappend lmxt [dict get $m idmxtarg]
    }
    return $lmxt
}

proc rr-mailrole-by-view {_trr idview} {
    upvar $_trr trr

    set lmr {}
    if {$trr(mboxhost) ne ""} then {
	set lmr [list $trr(idmboxhost) $trr(idmboxhostview)]
    }
    return $lmr
}

proc rr-mailaddr-by-view {_trr idview} {
    upvar $_trr trr

    set lma {}
    foreach ma $trr(mailaddr) {
	set idrr [dict get $ma idmailaddr]
	set idv  [dict get $ma idmailaddrview]
	if {$idv == $idview} then {
	    lappend lma [list $idrr $idv]
	}
    }
    return $lma
}


#
# Search for a domain name in the database
#
# Input:
#   - parameters:
#       - dbfd : database handle
#	- domain : domain to search (not terminated by a ".")
# Output:
#   - return value: id of domain if found, -1 if not found
#
# History
#   2002/04/11 : pda/jean : design
#   2010/11/29 : pda      : i18n
#

proc read-domain {dbfd domain} {
    set domain [pg_quote $domain]
    set iddom -1
    $dbfd exec "SELECT iddom FROM dns.domain WHERE name = $domain" tab {
	set iddom $tab(iddom)
    }
    return $iddom
}

#
# Checks if the domain is authorized for this user
#
# Input:
#   - parameters:
#       - dbfd : database handle
#	- idcor : user id
#	- _iddom : domain id or -1 to read from domain
#	- _domain : domain, or "" to read from iddom
#	- roles : roles to test (column names in p_dom)
# Output:
#   - return value: empty string or error message
#   - parameters _iddom and _domain : fetched values
#
# History
#   2002/04/11 : pda/jean : design
#   2002/05/06 : pda/jean : use groups
#   2004/02/06 : pda/jean : add roles
#   2010/11/29 : pda      : i18n
#

proc check-domain {dbfd idcor _iddom _domain roles} {
    upvar $_iddom iddom
    upvar $_domain domain

    set msg ""

    #
    # Read domain if needed
    #
    if {$iddom == -1} then {
	set iddom [read-domain $dbfd $domain]
	if {$iddom == -1} then {
	    set msg [mc "Domain '%s' not found" $domain]
	}
    } elseif {$domain eq ""} then {
	set sql "SELECT name FROM dns.domain WHERE iddom = $iddom"
	$dbfd exec $sql tab {
	    set domain $tab(name)
	}
	if {$domain eq ""} then {
	    set msg [mc "Domain-id '%s' not found" $iddom]
	}
    }

    #
    # Check if we have rights on this domain
    #
    if {$msg eq ""} then {
	set where ""
	foreach r $roles {
	    append where "AND p_dom.$r > 0 "
	}

	set found 0
	set sql "SELECT p_dom.iddom FROM dns.p_dom, global.nmuser
			    WHERE nmuser.idcor = $idcor
				    AND nmuser.idgrp = p_dom.idgrp
				    AND p_dom.iddom = $iddom
				    $where
				    "
	$dbfd exec $sql tab {
	    set found 1
	}
	if {! $found} then {
	    set msg [mc "You don't have rights on domain '%s'" $domain]
	}
    }

    return $msg
}

#
# Check if the IP address is authorized for this user
#
# Input:
#   - parameters:
#       - dbfd : database handle
#	- idcor : user id
#	- addr : IP address to test
# Output:
#   - return value: 1 if ok, 0 if error
#
# History
#   2002/04/11 : pda/jean : design
#   2002/05/06 : pda/jean : use groups
#   2004/01/14 : pda/jean : add IPv6
#   2010/11/29 : pda      : i18n
#

proc check-authorized-ip {dbfd idcor addr} {
    set r 0
    set sql "SELECT dns.check_ip_cor ('$addr', $idcor) AS ok"
    $dbfd exec $sql tab {
	set r [string equal $tab(ok) "t"]
    }
    return $r
}

#
# Check if the user has adequate rights to a machine, by checking
# that he own all IP addresses
#
# Input:
#   - parameters:
#       - dbfd : database handle
#	- idcor : user id
#	- idrr : RR id to search for, or -1 if _trr is already initialized
#	- _trr : see read-rr-by-name
# Output:
#   - return value: 1 if ok, 0 if error
#
# History
#   2002/04/19 : pda/jean : design
#   2010/11/29 : pda      : i18n
#   2012/10/30 : pda/jean : add views
#

proc check-name-by-addresses {dbfd idcor idrr _trr} {
    upvar $_trr trr

    set ok 1

    #
    # Read RR if needed
    #

    if {$idrr != -1} then {
	read-rr-by-id $dbfd $idrr trr
    }

    if {$trr(idview) ne "" && ! [::u isallowedview $trr(idview)]} then {
	return 0
    }

    #
    # Check all addresses and views
    #

    foreach ip [rr-ip-by-view trr "NOT USED"] {
	if {! [check-authorized-ip $dbfd $idcor $ip]} then {
	    set ok 0
	    break
	}
    }

    return $ok
}

#
# Check if the user as the right to add/modify/delete a given name
# according to a given context.
#
# Input:
#   - parameters:
#       - dbfd : database handle
#	- idcor : user id
#	- name : name to test (first component of FQDN)
#	- domain : domain to test (the n-1 last components of FQDN)
#	- idview : view id in which this FQDN must be tested
#	- trr : in return, information on the host (see read-rr-by-id)
#	- context : the context to check
# Output:
#   - return value: empty string or error message
#   - parameter trr : contains informations on the RR found, or if the RR
#	doesn't exist, trr(idrr) = "" and trr(iddom) = domain id
#
# Detail of tests:
#    According to context:
#	"host"
#	    check-domain (domain, idcor, "") and views
#	    if name.domain is ALIAS then error
#	    if name.domain is MX then error
#	    if name.domain is ADDRMAIL
#		then check-all-IP-addresses (mail host, idcor)
#		      check-domain (domain, idcor, "")
#	    if name.domain has IP addresses
#		then check-all-IP-addresses (machine, idcor)
#	    if no test is false, then OK
#	"existing-host"
#	    identical to "host", but the name must have at least one IP address
#	"del-name"
#	    check-domain (domain, idcor, "") and views
#	    if name.domain is ALIAS
#		then check-all-IP-addresses (pointed host, idcor)
#	    if name.domain is MX then error
#	    if name.domain has IP addresses
#		then check-all-IP-addresses (machine, idcor)
#	    if name.domain is ADDRMAIL
#		then check-all-IP-addresses (mail host, idcor)
#		      check-domain (domain, idcor, "")
#	    if no test is false, then OK
#	"alias"
#	    check-domain (domain, idcor, "") and views
#	    if name.domain is ALIAS then error
#	    if name.domain is MX then error
#	    if name.domain is target of a MX then error
#	    if name.domain is ADDRMAIL then error
#	    if name.domain has IP addresses then error
#	    if no test is false, then OK
#	"mx"
#	    check-domain (domain, idcor, "") and views
#	    if name.domain is ALIAS then error
#	    if name.domain is MX
#		then check-all-IP-addresses (mail exchangers, idcor)
#	    if name.domain is ADDRMAIL then error
#	    if no test is false, then OK
#	"add-mailaddr"
#	    check-domain (domain, idcor, "mailrole") and views
#	    if name.domain is ALIAS then error
#	    if name.domain is MX then error
#	    if name.domain is ADDRMAIL then error
#	    if name.domain is MAILHOST then error
#	    if name.domain has IP addresses
#		check-all-IP-addresses (name.domain, idcor)
#	    if no test is false, then OK
#	"del-mailaddr"
#	    check-domain (domain, idcor, "mailrole") and views
#	    if name.domain is ALIAS then error
#	    if name.domain is MX then error
#	    if name.domain is target of a MX then error
#	    if name.domain is NOT ADDRMAIL then error
#	    if name.domain is ADDRMAIL
#		check-all-IP-addresses (mail host, idcor)
#		check-domain (domain, idcor, "")
#	    if name.domain has IP addresses
#		check-all-IP-addresses (name.domain, idcor)
#	    if no test is false, then OK
#
#    check-IP-addresses (host, idcor)
#	if there is no address
#	    then error
#	    else check that all IP addresses are mine (with an AND)
#	end if
#
# Bug: this procedure is never called with the "mx" parameter
#
# History
#   2004/02/27 : pda/jean : specification
#   2004/02/27 : pda/jean : coding
#   2004/03/01 : pda/jean : use trr(iddom) instead of iddom
#   2010/11/29 : pda      : i18n
#   2012/10/30 : pda/jean : add views
#   2013/04/10 : pda/jean : accept only one view
#

proc check-authorized-host {dbfd idcor name domain idview _trr context} {
    upvar $_trr trr

    array set testrights {
	host	{
		    {domain	{}}
		    {alias	REJECT}
		    {mx		REJECT}
		    {ip		CHECK}
		    {mailaddr	CHECK}
		}
	existing-host	{
		    {domain	{}}
		    {alias	REJECT}
		    {mx		REJECT}
		    {ip		CHECK}
		    {ip		EXISTS}
		    {mailaddr	CHECK}
		}
	alias	{
		    {domain	{}}
		    {alias	REJECT}
		    {mx		REJECT}
		    {ip		REJECT}
		    {mailaddr	REJECT}
		}
	del-name	{
		    {domain	{}}
		    {alias	CHECK}
		    {mx		REJECT}
		    {ip		CHECK}
		    {mailaddr	CHECK}
		}
	mx	{
		    {domain	{}}
		    {alias	REJECT}
		    {mx		CHECK}
		    {ip		CHECK}
		    {mailaddr	REJECT}
		}
	add-mailaddr	{
		    {domain	mailrole}
		    {alias	REJECT}
		    {mx		REJECT}
		    {mailaddr	REJECT}
		    {mailhost	REJECT}
		    {ip		CHECK}
		}
	del-mailaddr	{
		    {domain	mailrole}
		    {alias	REJECT}
		    {mx		REJECT}
		    {mailaddr	CHECK}
		    {mailaddr	EXISTS}
		    {ip		CHECK}
		}
    }


    #
    # Get the list of actions associated with the context
    #

    if {! [info exists testrights($context)]} then {
	return [mc "Internal error: invalid context '%s'" $context]
    }

    #
    # For each view, process tests in the given order, and break as
    # soon as a test fails
    #

    set fqdn "$name.$domain"

    foreach a $testrights($context) {
	set parm [lindex $a 1]
	switch [lindex $a 0] {
	    domain {
		set msg [check-views [list $idview]]
		if {$msg ne ""} then {
		    return $msg
		}
		set viewname [::u viewname $idview]

		set iddom -1
		set msg [check-domain $dbfd $idcor iddom domain $parm]
		if {$msg ne ""} then {
		    return $msg
		}

		if {! [read-rr-by-name $dbfd $name $iddom $idview trr]} then {
		    set trr(iddom) $iddom
		}
	    }
	    alias {
		set idcname [rr-cname-by-view trr $idview]
		if {$idcname ne ""} then {
		    read-rr-by-id $dbfd $idcname t
		    set fqdnref "$t(name).$t(domain)"
		    switch $parm {
			REJECT {
			    return [mc {%1$s is an alias of host %2$s in view %3$s} $fqdn $fqdnref $viewname]
			}
			CHECK {
			    set ok [check-name-by-addresses $dbfd $idcor -1 t]
			    if {! $ok} then {
				return [mc {You don't have rights on some IP addresses of '%1$s' referenced by alias '%2$s'} $fqdnref $fqdn]
			    }
			}
			default {
			    return [mc {Internal error: invalid parameter '%1$s' for '%2$s'} $parm "$context/$a"]
			}
		    }
		}
	    }
	    mx {
		set lmx [rr-mx-by-view trr $idview]
		foreach mx $lmx {
		    switch $parm {
			REJECT {
			    return [mc "'%s' is a MX" $fqdn]
			}
			CHECK {
			    set idrr [lindex $mx 1]
			    set ok [check-name-by-addresses $dbfd $idcor $idrr t]
			    if {! $ok} then {
				set fqdnmx "$t(name).$t(domain)"
				return [mc {You don't have rights on some IP addresses of '%1$s' referenced by MX '%2$s'} $fqdnmx $fqdn]
			    }
			}
			default {
			    return [mc {Internal error: invalid parameter '%1$s' for '%2$s'} $parm "$context/$a"]
			}
		    }
		}
	    }
	    mailaddr {
		# get mailbox host for this address
		set rm [rr-mailrole-by-view trr $idview]
		if {$rm ne ""} then {
		    lassign $rm idrr idviewmbx
		    # get mbox host
		    if {! [read-rr-by-id $dbfd $idrr trrh]} then {
			return [mc "Internal error: id '%s' doesn't exists for a mail host" $idrr]
		    }
		    switch $parm {
			REJECT {
			    # This name is already a mail address
			    # (it already has a mailbox host)
			    set fqdnm "$trrh(name).$trrh(domain)"
			    return [mc {%1$s in view %2$s is a mail address hosted by %3$s in view %4$s} $fqdn $viewname $fqdnm [::u viewname $idviewmbx]]
			}
			CHECK {

			    # IP address check
			    set ok [check-name-by-addresses $dbfd $idcor -1 trrh]
			    if {! $ok} then {
				return [mc "You don't have rights on host holding mail for '%s'" $fqdn]
			    }

			    # Mail host checking
			    set bidon -1
			    set msg [check-domain $dbfd $idcor bidon trrh(domain) ""]
			    if {$msg ne ""} then {
				set r [mc "You don't have rights on host holding mail for '%s'" $fqdn]
				append r "\n$msg"
				return $r
			    }
			}
			EXISTS {
			    # nothing
			}
			default {
			    return [mc {Internal error: invalid parameter '%1$s' for '%2$s'} $parm "$context/$a"]
			}
		    }
		} else {
		    # this address has no mailbox host, so it is
		    # not a mail role
		    switch $parm {
			REJECT -
			CHECK {
			    # nothing
			}
			EXISTS {
			    return [mc {'%1$s' is not a mail role in view '%2$s'} $fqdn $viewname]
			}
			default {
			    return [mc {Internal error: invalid parameter '%1$s' for '%2$s'} $parm "$context/$a"]
			}
		    }
		}
	    }
	    mailhost {
		set laddr [rr-mailaddr-by-view trr $idview]
		switch $parm {
		    REJECT {
			# remove the name (in all views) from the list
			# of mail domains hosted on this host
			while {[set pos [lsearch -exact -index 0 \
					    $laddr $trr(idrr)]] != -1} {
			    set laddr [lreplace $laddr $pos $pos]
			}
			if {[llength $laddr] > 0} then {
			    return [mc "'%s' is a mail host for mail domains" $fqdn]
			}
		    }
		    default {
			return [mc {Internal error: invalid parameter '%1$s' for '%2$s'} $parm "$context/$a"]
		    }
		}
	    }
	    ip {
		set lip [rr-ip-by-view trr $idview]
		switch $parm {
		    REJECT {
			if {[llength $lip] > 0} then {
			    return [mc {'%1$s' has IP addresses in view '%2$s'} $fqdn $viewname]
			}
		    }
		    EXISTS {
			if {[llength $lip] == 0} then {
			    return [mc {Name '%1$s' is not a host in view '%2$s'} $fqdn $viewname]
			}
		    }
		    CHECK {
			set ok [check-name-by-addresses $dbfd $idcor -1 trr]
			if {! $ok} then {
			    return [mc "You don't have rights on some IP addresses of '%s1$'" $fqdn]
			}
		    }
		    default {
			return [mc {Internal error: invalid parameter '%1$s' for '%2$s'} $parm "$context/$a"]
		    }
		}
	    }
	}
    }

    return ""
}

