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
	lappend filter "r.name = $qname"
    }

    if {$domain ne ""} then {
	set qdomain [pg_quote $domain]
	lappend filter "domain.name = $qdomain"
    }

    if {$addr ne ""} then {
	set qaddr [pg_quote $addr]
	lappend filter "rr_ip.addr <<= $qaddr"
	set wip "AND (addr <<= $qaddr OR addr >>= $qaddr)"
    }

    #
    # Append group permissions
    #

    set idgrp [::n idgrp]

    lappend filter "r.idview IN (SELECT idview
				    FROM dns.p_view WHERE idgrp = $idgrp)"
    lappend filter "r.iddom IN (SELECT iddom
				    FROM dns.p_dom WHERE idgrp = $idgrp)"
    lappend filter "rr_ip.addr <<= ANY (
			    SELECT addr FROM dns.p_ip
				WHERE idgrp = $idgrp AND allow_deny = 1 $wip)"
    lappend filter "NOT rr_ip.addr <<= ANY (
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
			DISTINCT ON (r.idrr)
			r.idrr,
			r.name,
			r.iddom,
			domain.name AS domain,
			r.idview,
			view.name AS view
		    FROM dns.rr r
			INNER JOIN dns.domain USING (iddom)
			INNER JOIN dns.view USING (idview)
			INNER JOIN dns.rr_ip USING (idrr)
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
    set idgrp [::n idgrp]
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
    # Check syntax
    #

    set msg [check-name-syntax $name]
    if {$msg ne ""} then {
	::scgi::serror 412 $msg
    }
    set name [string tolower $name]

    #
    # Check addresses
    #

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
    # Check if IP addresses are already allocated
    #

    set sql "SELECT DISTINCT jaddr
		FROM (VALUES $vaddr) AS vaddr (jaddr)
		    INNER JOIN dns.rr_ip ON (addr = jaddr)
		    NATURAL INNER JOIN dns.rr
		WHERE rr.idview = $idview
		"
    set lbad {}
    ::dbdns exec $sql tab {
	lappend lbad $tab(jaddr)
    }
    if {[llength $lbad] > 0} then {
	::scgi::serror 403 [mc "IP addresses already exist (%s)" [join $lbad ", "]]
    }

    #
    # Check if host name/domain/idview are authorized
    #

    set idcor [::n idcor]
    set domain [::n domainname $iddom]

    set msg [check-authorized-host ::dbdns $idcor $name $domain $idview rr "host"]
    if {$msg ne ""} then {
	::scgi::serror 412 $msg
    }

    #
    # Check MAC address
    #

    if {$mac ne ""} then {
	set msg [check-mac-syntax-dhcp $mac $addr]
	if {$msg ne ""} then {
	    ::scgi::serror 412 $msg
	}
    }

    #
    # Check TTL and sendsmtp
    #

    if {"ttl" in [::n capabilities]} then {
	set msg [check-ttl $ttl]
	if {$msg ne ""} then {
	    ::scgi::serror 412 $msg
	}
    } else {
	set ttl -1
    }

    if {"smtp" in [::n capabilities]} then {
	set sendsmtp [expr $sendsmtp != 0]
    } else {
	set sendsmtp 0
    }

    #
    # Check if host already exists,
    # and create RR if needed
    #

    set qmac NULL
    if {$mac ne ""} then {
	set qmac [pg_quote $mac]
    }
    set qname     [pg_quote $name]
    set qcomment  [pg_quote $comment]
    set qrespname [pg_quote $respname]
    set qrespmail [pg_quote $respmail]
    set qiddhcpprof NULL
    if {$iddhcpprof != -1} then {
	set qiddhcpprof $iddhcpprof
    }

    if {[::rr::found $rr]} then {
	#
	# Check if host already exists
	#

	set idrr [::rr::get-idrr $rr]
	set sql "SELECT COUNT (addr) AS cnt
		    FROM dns.rr_ip
		    WHERE idrr = $idrr"
	set cnt 0
	::dbdns exec $sql tab {
	    set cnt $tab(cnt)
	}
	if {$cnt > 0} then {
	    ::scgi::serror 412 [mc "Host '%s' already exists" $name]
	}

	#
	# Update RR and add addresses
	#

	set sql "BEGIN WORK ;
		UPDATE dns.rr
		    SET mac = $qmac,
			iddhcpprof = $qiddhcpprof,
			idhinfo = $idhinfo
			sendsmtp = $sendsmtp,
			ttl = $ttl,
			comment = $qcomment,
			respname = $respname,
			respmail = $respmail,
			idcor = $idcor
		    WHERE idrr = $idrr
		    ;
		INSERT INTO dns.rr_ip (idrr, addr)
		    SELECT $idrr, vaddr.jaddr
			FROM (VALUES $vaddr) AS vaddr (jaddr)
		    ;
		COMMIT WORK
		"
	::dbdns exec $sql

    } else {
	#
	# Create RR and associated addresses
	# 

	set sql "WITH insrr AS (
			INSERT INTO dns.rr
			    (name, iddom, idview, mac, iddhcpprof,
				idhinfo, sendsmtp, ttl,
				comment, respname, respmail,
				idcor)
			VALUES
			    ($qname, $iddom, $idview, $qmac, $qiddhcpprof,
				$idhinfo, $sendsmtp, $ttl,
				$qcomment, $qrespname, $qrespmail,
				$idcor)
			RETURNING idrr
		    )
		    INSERT INTO dns.rr_ip (idrr, addr)
			SELECT insrr.idrr, vaddr.jaddr
			    FROM insrr, (VALUES $vaddr) AS vaddr (jaddr)
			RETURNING idrr
		    "
	set idrr -1
	::dbdns exec $sql tab {
	    # This request may return more than one line. We don't
	    # break this loop to avoid cancelling the request.
	    set idrr $tab(idrr)
	}
    }

    set j [get-host $idrr]

    ::scgi::set-header Content-Type application/json
    ::scgi::set-body $j
}


##############################################################################

api-handler get {/hosts/([0-9]+:idrr)} logged {
    } {
    existing-host $idrr
    set j [get-host $idrr]

    ::scgi::set-header Content-Type application/json
    ::scgi::set-body $j
}

##############################################################################

api-handler put {/hosts/([0-9]+:idrr)} logged {
    } {
    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXxx
    set idgrp [::n idgrp]
#    set j [dhcp-new $iddhcprange $idgrp $_parm]
    set j [names-get $idrr $idgrp]
    ::scgi::set-header Content-Type application/json
    ::scgi::set-body $j
}

##############################################################################

api-handler delete {/hosts/([0-9]+:idrr)} logged {
    } {
    existing-host $idrr
    set sql "SELECT r.name, d.name AS domain
		FROM dns.mail_role m
		    INNER JOIN dns.rr r ON (m.mailaddr = r.idrr)
		    INNER JOIN dns.domain d USING (iddom)
		WHERE m.mboxhost = $idrr
		ORDER BY domain ASC, r.name ASC
		"
    set lmbox {}
    ::dbdns exec $sql tab {
	lappend lmbox "$tab(name).$tab(domain)"
    }
    if {[llength $lmbox] > 0} then {
	::scgi::serror 412 [mc "Host is a mailbox host for domains: %s" [join $lmbox ", "]]
    }

    set sql "SELECT d.name AS domain
		FROM dns.relay_dom r
		    INNER JOIN dns.domain d USING (iddom)
		WHERE r.mx = $idrr
		ORDER BY domain ASC
		"
    set lrel {}
    ::dbdns exec $sql tab {
	lappend lrel $tab(domain)
    }
    if {[llength $lrel] > 0} then {
	::scgi::serror 412 [mc "Host is a mail relay for domains: %s" [join $lrel ", "]]
    }

    #
    # Delete IP addresses and aliases pointing to this host
    # as well as the given RR.
    #

    set sql "BEGIN WORK ;
		DELETE FROM dns.rr_ip WHERE idrr = $idrr ;
		WITH aliases AS (
			DELETE FROM dns.rr_cname
			    WHERE cname = $idrr
			    RETURNING idrr
		    )
		    DELETE FROM dns.rr
			USING aliases
			WHERE rr.idrr = aliases.idrr
		    ;
		DELETE FROM dns.rr
		    WHERE idrr = $idrr
		    ;
		COMMIT WORK"
    ::dbdns exec $sql

    ::scgi::set-header Content-Type text/plain
    ::scgi::set-body "OK"
}

##############################################################################
# Utility functions
##############################################################################

proc get-host {idrr} {
    set sql "SELECT row_to_json (t.*) AS j FROM (
		SELECT
		    r.idrr,
		    r.name,
		    r.iddom,
		    r.idview,
		    COALESCE (CAST (r.mac AS text), '') AS mac,
		    r.idhinfo,
		    COALESCE (r.comment, '') AS comment,
		    COALESCE (r.respname, '') AS respname,
		    COALESCE (r.respmail, '') AS respmail,
		    COALESCE (iddhcpprof, -1) AS iddhcpprof,
		    r.sendsmtp,
		    r.ttl,
		    COALESCE (sreq.addr, '{}') AS addr
		FROM dns.rr r,
		    (
			SELECT array_agg (addr) AS addr
			    FROM dns.rr_ip
			    WHERE rr_ip.idrr = $idrr
			) AS sreq
		WHERE r.idrr = $idrr
	    ) AS t
		"
    set found 0
    ::dbdns exec $sql tab {
	set j $tab(j)
	set found 1
    }
    if {! $found} then {
	::scgi::serror 404 [mc "Name not found"]
    }
    return $j
}

proc existing-host {idrr} {
    set sql "SELECT rr.name, domain.name AS domain, rr.idview
		FROM dns.rr
		    INNER JOIN dns.domain USING (iddom)
		WHERE idrr = $idrr
		"
    set found 0
    ::dbdns exec $sql tab {
	set found 1
	set name $tab(name)
	set domain $tab(domain)
	set idview $tab(idview)
    }

    if {! $found} then {
	::scgi::serror 404 [mc "Host not found"]
    }

    set msg [check-authorized-host ::dbdns [::n idcor] $name $domain $idview rr "existing-host"]
    if {$msg ne ""} then {
	::scgi::serror 412 $msg
    }
}















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


