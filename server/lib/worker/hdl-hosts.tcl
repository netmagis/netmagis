##############################################################################

api-handler get {/hosts} logged {
	view	0
	name	0
	domain	0
	addr	0
    } {
    #
    # Prepare filter clauses
    #

    set filter {}
    set wip ""

    if {$view ne ""} then {
	set qview [pg_quote $view]
	lappend filter "view.name = $qview"
    }

    if {$name ne ""} then {
	set qname [pg_quote $name]
	lappend filter "n.name = $qname"
    }

    if {$domain ne ""} then {
	set qdomain [pg_quote $domain]
	lappend filter "domain.name = $qdomain"
    }

    if {$addr ne ""} then {
	set qaddr [pg_quote $addr]
	lappend filter "addr.addr <<= $qaddr"
	set wip "AND (addr <<= $qaddr OR addr >>= $qaddr)"
    }

    #
    # Append group permissions
    #

    set idgrp [::n idgrp]

    lappend filter "n.idview IN (SELECT idview
				    FROM dns.p_view WHERE idgrp = $idgrp)"
    lappend filter "n.iddom IN (SELECT iddom
				    FROM dns.p_dom WHERE idgrp = $idgrp)"
    lappend filter "addr.addr <<= ANY (
			    SELECT addr FROM dns.p_ip
				WHERE idgrp = $idgrp AND allow_deny = 1 $wip)"
    lappend filter "NOT addr.addr <<= ANY (
			    SELECT addr FROM dns.p_ip
				WHERE idgrp = $idgrp AND allow_deny = 0 $wip)"

    #
    # Order clause
    #

#    global names_sortcrit
#
#    set order {}
#    foreach c [split $sort ","] {
#	if {! [info exists names_sortcrit($c)]} then {
#	    ::scgi::serror 412 [mc "Invalid sort criterion '%s'" $c]
#	}
#	lappend order $names_sortcrit($c)
#    }
#    if {[llength $order] == 0} then {
#	set order ""
#    } else {
#	set order [join $order ", "]
#	set order "ORDER BY $order"
#    }

    #
    # Create SQL request
    #

    set filter [join $filter " AND "]

    set sql "SELECT COALESCE (json_agg (t), '\[\]') AS j FROM (
		SELECT
			DISTINCT ON (h.idhost)
			h.idhost,
			n.name,
			n.iddom,
			domain.name AS domain,
			n.idview,
			view.name AS view
		    FROM dns.name n
			INNER JOIN dns.host h USING (idname)
			INNER JOIN dns.domain USING (iddom)
			INNER JOIN dns.view USING (idview)
			INNER JOIN dns.addr USING (idhost)
		    WHERE $filter
		) AS t"

    ::dbdns exec $sql tab {
	set j $tab(j)
    }
    ::scgi::set-header Content-Type application/json
    ::scgi::set-body $j
}

##############################################################################

api-handler post {/hosts} logged {
    } {
    hosts-new-and-mod $_parm [::rr::not-a-rr]
}


##############################################################################

api-handler get {/hosts/([0-9]+:idhost)} logged {
    } {
    set rr [::rr::read-by-idhost ::dbdns $idhost]
    if {! [::rr::found $rr]} then {
	::scgi::serror 404 [mc "Host not found"]
    }
    set msg [check-authorized-rr ::dbdns [::n idcor] $rr "existing-host"]
    if {$msg ne ""} then {
	::scgi::serror 412 $msg
    }

    set j [host-get-json $idhost]

    ::scgi::set-header Content-Type application/json
    ::scgi::set-body $j
}

proc host-get-json {idhost} {
    set sql "SELECT row_to_json (t.*) AS j FROM (
		SELECT
		    n.name,
		    n.iddom,
		    n.idview,
		    COALESCE (CAST (h.mac AS text), '') AS mac,
		    h.idhinfo,
		    COALESCE (h.comment, '') AS comment,
		    COALESCE (h.respname, '') AS respname,
		    COALESCE (h.respmail, '') AS respmail,
		    COALESCE (iddhcpprof, -1) AS iddhcpprof,
		    h.sendsmtp,
		    h.ttl,
		    COALESCE (sreq.addr, '{}') AS addr
		FROM dns.host h
		    NATURAL INNER JOIN dns.name n,
		    (
			SELECT array_agg (addr) AS addr
			    FROM dns.addr
			    WHERE addr.idhost = $idhost
			) AS sreq
		WHERE h.idhost = $idhost
	    ) AS t
		"
    set found 0
    ::dbdns exec $sql tab {
	set j $tab(j)
	set found 1
    }
    if {! $found} then {
	::scgi::serror 404 [mc "Host not found"]
    }
    return $j
}

##############################################################################

api-handler put {/hosts/([0-9]+:idhost)} logged {
    } {
    set orr [::rr::read-by-idhost ::dbdns $idhost]
    if {! [::rr::found $orr]} then {
	::scgi::serror 404 [mc "Host not found"]
    }

    #
    # Check that we have rights to modify this host before any other test
    #

    set msg [check-authorized-rr ::dbdns [::n idcor] $orr "existing-host"]
    if {$msg ne ""} then {
	::scgi::serror 412 $msg
    }

    hosts-new-and-mod $_parm $orr
}

##############################################################################
# Huge function to create or update a specific host
##############################################################################

#
# Create a new host, or modify an existing host
#
# Input:
#   - _parm: JSON for new values
#   - for a new host: orr is empty
#   - to modify an existing host: orr contains the existing rr
# Output:
#   - new idhost (or old one if no id modification)
#
# This procedure checks the following cases:
#   - notations:
#	oidname = idname from orr (or -1)
#	oidhost = idhost from orr (or -1)
#	nidname = idname of existing rr for new name (or -1)
#	nidhost = idhost of existing rr for new name (or -1)
#
#   oidname oidhost nidname nidhost	comment
#     -1      -1      -1      -1	host creation with a new name
#     -1      -1      -1     valid	<cannot happen>
#     -1      -1     valid    -1	host creation with an existing name
#     -1      -1     valid   valid	error: host already exists
#     -1     valid     *       *	<cannot happen>
#    valid    -1       *       *	<cannot happen (existing host exists!)>
#    valid   valid    -1      -1	host renaming with a new name
#    valid   valid    -1     valid	<cannot happen>
#    valid   valid   valid    -1	host renaming with an existing name
#    valid   valid     n     m == n	host update
#    valid   valid     n     m != n	error: host already exists
#

proc hosts-new-and-mod {_parm orr} {
    set idgrp [::n idgrp]

    #
    # Use oidname == -1 as the test for a new host (vs host modification)
    #

    set oidname -1
    set oidhost -1
    if {[::rr::found $orr]} then {
	set oidname [::rr::get-idname $orr]
	set oidhost [::rr::get-idhost $orr]
    }

    ######################################################################
    # Check input parameters
    ######################################################################

    # get body just to check it's a JSON body
    ::scgi::get-body-json $_parm

    set dbody [dict get $_parm "_bodydict"]

    set spec {
		{name text}
		{iddom int -1}
		{idview int -1}
		{mac text}
		{idhinfo int -1}
		{comment text}
		{respname text}
		{respmail text}
		{iddhcpprof int -1}
		{sendsmtp int 0}
		{ttl int 0}
		{addr {}}
	    }
    if {! [::scgi::check-json-attr $dbody $spec]} then {
	::scgi::serror 412 [mc "Invalid JSON input"]
    }

    #
    # Check various ids
    #

    if {! [::n isalloweddom $iddom]} then {
	::scgi::serror 412 [mc "Invalid domain id '%s'" $iddom]
    }

    if {! [::n isallowedview $idview]} then {
	::scgi::serror 412 [mc "Invalid view id '%s'" $idview]
    }

    if {$iddhcpprof != -1 && ! [::n isalloweddhcpprof $iddhcpprof]} then {
	::scgi::serror 412 [mc "Invalid dhcpprofile id '%s'" $iddhcpprof]
    }

    if {! [::n isallowedhinfo $idhinfo]} then {
	::scgi::serror 412 [mc "Invalid hinfo id '%s'" $idhinfo]
    }

    #
    # Check syntax of new host name
    #

    set msg [check-name-syntax $name]
    if {$msg ne ""} then {
	::scgi::serror 412 $msg
    }
    set name [string tolower $name]

    #
    # Check new MAC address
    #

    if {$mac ne ""} then {
	set msg [check-mac-syntax-dhcp $mac $addr]
	if {$msg ne ""} then {
	    ::scgi::serror 412 $msg
	}
    }

    #
    # Check new TTL and sendsmtp
    #

    if {"ttl" in [::n capabilities]} then {
	set msg [check-ttl $ttl]
	if {$msg ne ""} then {
	    ::scgi::serror 412 $msg
	}
    } else {
	if {$oidhost == -1} then {
	    set ttl -1
	} else {
	    set ttl [::rr::get-ttlhost $orr]
	}
    }

    if {"smtp" in [::n capabilities]} then {
	set sendsmtp [expr $sendsmtp != 0]
    } else {
	if {$oidhost == -1} then {
	    set sendsmtp 0
	} else {
	    set sendsmtp [::rr::get-sendsmtp $orr]
	}
    }

    ######################################################################
    # Check if we are authorized to add the new host
    ######################################################################

    set idcor [::n idcor]
    set domain [::n domainname $iddom]

    set msg [check-authorized-host ::dbdns $idcor $name $domain $idview nrr "host"]
    if {$msg ne ""} then {
	::scgi::serror 412 $msg
    }

    set nidname -1
    set nidhost -1
    if {[::rr::found $nrr]} then {
	set nidname [::rr::get-idname $nrr]
	set nidhost [::rr::get-idhost $nrr]
    }

    #
    # Check if new host already exists
    #

    if {$oidname == -1 && $nidhost != -1} then {
	# host creation ("post" request), but new host already exists
	::scgi::serror 403 [mc "Host already exists"]
    }

    if {$oidname != -1 && $nidhost != -1 && $oidhost != $nidhost} then {
	# host modification ("put" request)
	::scgi::serror 403 [mc "Host already exists"]
    }

    ######################################################################
    # Check new IP addresses
    ######################################################################

    if {[llength $addr] == 0} then {
	::scgi::serror 412 [mc "Empty address list"]
    }

    set vaddr {}
    set lbad {}
    foreach a $addr {
	if {[::ip::version $a] == 0} then {
	    lappend lbad $a
	} else {
	    set qa [pg_quote $a]
	    lappend vaddr "(${qa}::inet)"
	}
    }
    if {[llength $lbad] > 0} then {
	::scgi::serror 403 [mc "Invalid address syntax (%s)" [join $lbad ", "]]
    }

    set lbad {}
    set vaddr [join $vaddr ","]
    set sql "SELECT DISTINCT jaddr
		FROM (VALUES $vaddr) AS vaddr (jaddr)
		    LEFT JOIN dns.p_ip p ON
			(idgrp = $idgrp AND p.addr >>= vaddr.jaddr)
		WHERE allow_deny IS NULL OR allow_deny = 0
		"
    ::dbdns exec $sql tab {
	lappend lbad $tab(jaddr)
    }
    if {[llength $lbad] > 0} then {
	::scgi::serror 403 [mc "Unauthorized address(es): %s" [join $lbad ", "]]
    }

    #
    # Check if new IP addresses are already allocated to some other hosts
    # (but don't check our existing addresses if oidname != -1)
    #

    set sql "SELECT DISTINCT jaddr
		FROM (VALUES $vaddr) AS vaddr (jaddr)
		    INNER JOIN dns.addr ON (addr = jaddr)
		    NATURAL INNER JOIN dns.host h
		    NATURAL INNER JOIN dns.name n
		WHERE n.idview = $idview AND h.idhost != $oidhost
		"
    set lbad {}
    ::dbdns exec $sql tab {
	lappend lbad $tab(jaddr)
    }
    if {[llength $lbad] > 0} then {
	::scgi::serror 403 [mc "IP addresses already exist (%s)" [join $lbad ", "]]
    }

    ######################################################################
    # Prepare variables
    ######################################################################

    #
    # Insert/update host in database
    #
    # Remaining cases to analyze:
    #   oidname oidhost nidname nidhost     comment
    #     -1      -1      -1      -1        host creation with a new name
    #     -1      -1     valid    -1        host creation with an existing name
    #    valid   valid    -1      -1        host renaming with a new name
    #    valid   valid   valid    -1        host renaming with an existing name
    #    valid   valid     n     m == n     host update
    #

    ::dbdns lock {dns.name dns.host dns.addr} {
	#
	# Add new name for the host since it did not pre-exist
	#
	if {$nidname == -1} then {
	    set nidname [::rr::add-name ::dbdns $name $iddom $idview]
	}
	# At this point, nidname exists (but not necessarily the nidhost):
	#   oidname oidhost nidname nidhost     comment
	#     -1      -1     valid    -1    host creation with an existing name
	#    valid   valid   valid    -1    host renaming with an existing name
	#    valid   valid     n     m == n host update

	if {$oidhost == -1 && $nidhost == -1} then {
	    #
	    # Create new host
	    #
	    set nidhost [::rr::add-host ::dbdns $nidname \
	    				$mac $iddhcpprof $idhinfo \
					$comment $respname $respmail \
					$sendsmtp $ttl]

	} elseif {$oidhost != -1} then {
	    #
	    # Update host attributes (with renaming if $oidname != $nidname)
	    #

	    set qmac NULL
	    if {$mac ne ""} then {
		set qmac [pg_quote $mac]
	    }
	    set qcomment  [pg_quote $comment]
	    set qrespname [pg_quote $respname]
	    set qrespmail [pg_quote $respmail]
	    set qiddhcpprof NULL
	    if {$iddhcpprof != -1} then {
		set qiddhcpprof $iddhcpprof
	    }

	    set sql "UPDATE dns.host
			    SET
				idname = $nidname,
				mac = $qmac,
				comment = $qcomment,
				respname = $qrespname,
				respmail = $qrespmail,
				iddhcpprof = $qiddhcpprof,
				sendsmtp = $sendsmtp,
				ttl = $ttl
			    WHERE idhost = $oidhost
			    "
	    ::dbdns exec $sql

	    #
	    # Delete old IP addresses
	    #

	    set sql "DELETE FROM dns.addr WHERE idhost = $oidhost"
	    ::dbdns exec $sql

	    set nidhost $oidhost

	} else {
	    set msg "oidname=$oidname, oidhost=$oidhost, nidname=$nidname, nidhost=$nidhost"
	    ::scgi::serror 403 [mc "Internal error (%s)" $msg]
	}

	#
	# Add new IP addresses
	#
	set sql "INSERT INTO dns.addr (idhost, addr)
		    SELECT $nidhost, vaddr.addr
			FROM (VALUES $vaddr) AS vaddr (addr)
		    "
	::dbdns exec $sql
    }

    #
    # Add a log
    #

    set ndom [::n domainname $iddom]
    set nfqdn "$name.$ndom"
    set nview [::n viewname $idview]

    if {$oidname == -1} then {
	set logevent "addhost"
	set logmsg "add host $nfqdn/$nview"
	set jbefore null
    } else {
	set logevent "modhost"
	set ofqdn [::rr::get-fqdn $orr]
	set oview [::n viewname [::rr::get-idview $orr]]
	if {$oidname == $nidname} then {
	    set logmsg "mod host $ofqdn/$oview"
	} else {
	    set logmsg "mod host $ofqdn/$oview -> $nfqdn/$nview"
	}
	set jbefore [::rr::json-host $orr]
    }
    set jafter [host-get-json $nidhost]
    ::n writelog "$logevent" "$logmsg" $jbefore $jafter

    #
    # Return idhost
    #

    ::scgi::set-header Content-Type text/plain
    ::scgi::set-body $nidhost
}

##############################################################################

api-handler delete {/hosts/([0-9]+:idhost)} logged {
    } {
    set rr [::rr::read-by-idhost ::dbdns $idhost]
    if {! [::rr::found $rr]} then {
	::scgi::serror 404 [mc "Host not found"]
    }
    set msg [check-authorized-rr ::dbdns [::n idcor] $rr "existing-host"]
    if {$msg ne ""} then {
	::scgi::serror 412 $msg
    }

    #
    # Is this host a mboxhost for some mail addresses?
    #

    if {[llength [::rr::get-mailaddr $rr]] > 0} then {
	set sql "SELECT n.name, d.name AS domain
		    FROM dns.mailrole m,
			INNER JOIN dns.name n ON (mailaddr = idname)
			NATURAL INNER JOIN dns.domain d
		    WHERE m.mboxhost = $idhost
		    ORDER BY domain ASC, n.name ASC
		    "
	set lmbox {}
	::dbdns exec $sql tab {
	    lappend lmbox "$tab(name).$tab(domain)"
	}
	::scgi::serror 412 [mc "Host is a mailbox host for addresses: %s" [join $lmbox ", "]]
    }

    #
    # Is this host a mail relay for some domains?
    #

    if {[llength [::rr::get-relay $rr]] > 0} then {
	set sql "SELECT d.name AS domain
		    FROM dns.relaydom rd
			NATURAL INNER JOIN dns.domain d
		    WHERE rd.idhost = $idhost
		    ORDER BY d.name ASC
		    "
	set lrel {}
	::dbdns exec $sql tab {
	    lappend lrel $tab(domain)
	}
	::scgi::serror 412 [mc "Host is a mail relay for domains: %s" [join $lrel ", "]]
    }

    #
    # Is this host a MX for some fqdn?
    #

    if {[llength [::rr::get-mxname $rr]] > 0} then {
	set sql "SELECT n.name, d.name AS domain
		    FROM dns.mx x
			NATURAL INNER JOIN dns.name n
			NATURAL INNER JOIN dns.domain d
		    WHERE x.idhost = $idhost
		    ORDER BY domain ASC, n.name ASC
		    "
	set lmx {}
	::dbdns exec $sql tab {
	    lappend lmx "$tab(name).$tab(domain)"
	}
	::scgi::serror 412 [mc "Host is a MX for names: %s" [join $lmx ", "]]
    }

    #
    # Do aliases reference this host?
    #

    if {[llength [::rr::get-aliases $rr]] > 0} then {
	set sql "SELECT n.name, d.name AS domain
		    FROM dns.alias a
			NATURAL INNER JOIN dns.name n
			NATURAL INNER JOIN dns.domain d
		    WHERE a.idhost = $idhost
		    ORDER BY domain ASC, n.name ASC
		    "
	set lal {}
	::dbdns exec $sql tab {
	    lappend lal "$tab(name).$tab(domain)"
	}
	::scgi::serror 412 [mc "Host is referenced by aliases: %s" [join $lal ", "]]
    }

    #
    # Delete the host (as well as addresses by cascade)
    # and don't trap errors, they will be reported by the caller
    #

    set sql "DELETE FROM dns.host WHERE idhost = $idhost"
    ::dbdns exec $sql

    #
    # Add a log
    #

    set view [::n viewname [::rr::get-idview $rr]]
    set fqdn [::rr::get-fqdn $rr]
    set jbefore [::rr::json-host $rr]
    ::n writelog "delhost" "delete host $fqdn/$view" $jbefore "null"

    ::scgi::set-header Content-Type text/plain
    ::scgi::set-body "OK"
}

##############################################################################
# Utility functions
##############################################################################


#
# Check MAC against syntax errors and DHCP ranges
#
# Input:
#   - parameters:
#       - dbfd: database handle
#	- mac: non-empty MAC address
#	- lip: list of IP addresses for this host
# Output:
#   - return value: empty string or error message
#
# History
#   2013/04/05 : pda/jean : design
#

proc check-mac-syntax-dhcp {mac lip} {
    set msg [check-addr-syntax ::dbdns $mac "macaddr"]
    if {$msg ne ""} then {
	return $msg
    }

    #
    # Check that no static DHCP association (IP address with an associate
    # non null MAC address) is within a DHCP range
    #

    foreach ip $lip {
	set sql "SELECT min, max
			FROM dns.dhcprange
			WHERE '$ip' >= min AND '$ip' <= max"
	::dbdns exec $sql tab {
	    set msg [mc {Impossible to use MAC address '%1$s' because IP address '%2$s' is in DHCP dynamic range [%3$s..%4$s]} $mac $ip $tab(min) $tab(max)]
	}
	if {$msg ne ""} then {
	    return $msg
	}
    }

    return ""
}

#
# Check possible values for a TTL (see RFC 2181)
#
# Input:
#   - parameters:
#	- ttl : value to check
# Output:
#   - return value: empty string or error message
#
# History
#   2010/11/02 : pda/jean : design, from jean's code
#   2010/11/29 : pda      : i18n
#

proc check-ttl {ttl} {
    set r ""
    # 2^31-1
    set maxttl [expr 0x7fffffff]
    if {! [regexp {^\d+$} $ttl]} then {
	set r [mc "Invalid TTL: must be a positive integer"]
    } else {
	if {$ttl > $maxttl} then {
	    set r [mc "Invalid TTL: must be less than %s" $maxttl]
	}
    }
    return $r
}


