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
		    INNER JOIN dns.addr ON (addr = jaddr)
		    NATURAL INNER JOIN dns.host h
		    NATURAL INNER JOIN dns.name n
		WHERE n.idview = $idview
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
    # Insert host in database
    #

    ::dbdns lock {dns.name dns.host dns.addr} {
	if {[::rr::found $rr]} then {
	    set idname [::rr::get-idname $rr]
	    set idhost [::rr::get-idhost $rr]
	} else {
	    set idname [::rr::add-name ::dbdns $name $iddom $idview]
	    set idhost -1
	}

	if {$idhost == -1} then {
	    set idhost [::rr::add-host ::dbdns $idname \
	    				$mac $iddhcpprof $idhinfo \
					$comment $respname $respmail \
					$sendsmtp $ttl]
	} else {
	    ::scgi::serror 412 [mc "Host '%s' already exists" $name]
	}

	set sql "INSERT INTO dns.addr (idhost, addr)
		    SELECT $idhost, vaddr.addr
			FROM (VALUES $vaddr) AS vaddr (addr)
		    "
	# don't catch the error: if it fails, it will be trapped by
	# the scgi.tcl package
	::dbdns exec $sql
    }

    ::scgi::set-header Content-Type text/plain
    ::scgi::set-body $idhost
}


##############################################################################

api-handler get {/hosts/([0-9]+:idhost)} logged {
    } {
    set rrh [::rr::read-by-idhost ::dbdns $idhost]
    if {! [::rr::found $rrh]} then {
	::scgi::serror 404 [mc "Host not found"]
    }

    set name   [::rr::get-name $rrh]
    set domain [::rr::get-domain $rrh]
    set idview [::rr::get-idview $rrh]

    set msg [check-authorized-host ::dbdns [::n idcor] $name $domain $idview rr "existing-host"]
    if {$msg ne ""} then {
	::scgi::serror 412 $msg
    }

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

    ::scgi::set-header Content-Type application/json
    ::scgi::set-body $j
}

##############################################################################

api-handler put {/hosts/([0-9]+:idrr)} logged {
    } {
    set rrh [::rr::read-by-idhost ::dbdns $idhost]
    if {! [::rr::found $rrh]} then {
	::scgi::serror 404 [mc "Host not found"]
    }

    set name   [::rr::get-name $rrh]
    set domain [::rr::get-domain $rrh]
    set idview [::rr::get-idview $rrh]

    set msg [check-authorized-host ::dbdns [::n idcor] $name $domain $idview rr "existing-host"]
    if {$msg ne ""} then {
	::scgi::serror 412 $msg
    }

    set orr [::rr::read-by-id ::dbdns $idrr]
    if {! [::rr::found $orr]} then {
	::scgi::serror 404 [mc "Host-id %d not found" $idrr]
    }

    set on [::rr::get-name $rr]
    set od  [::rr::get-domain $rr]
    set ov [::rr::get-idview $rr]
    set msg [check-authorized-host ::dbdns $idcor $on $od $ov dummyrr "del-name"]
    if {$msg ne ""} then {
	::scgi::serror 412 $msg
    }

    hosts-new-and-mod $_parm $orr
}

#
# Create a new host, or modify an existing host
#
# Input:
#   - _parm: JSON for new values
#   - for a new host: orr is empty
#   - to modify an existing host: orr contains the existing rr
# Output:
#   - new idrr (or old one if no id modification)
#
# This procedure handles the following cases:
#   - notations:
#	rr = new values
#	nrr = RR found for the new name
#	orr = RR found for the existing name
#	MA/MX : the name is a mail address (pointing to a mboxhost) or
#		a MX (pointing to a MX target)
#
#   1- new host with a new name (orr = empty)
#	orr = empty, nrr = empty
#	=> create the new rr and add IP addresses
#	=> return new rr(idrr)
#
#   2- new host, with an existing name (e.g. MA/MX)
#	orr = empty, nrr not empty but without IP addresses
#	=> add IP addresses to nrr
#	=> return nrr(idrr)
#
#   3- new host, with an existing name which is already a host
#	orr = empty, nrr not empty and with IP addresses
#	=> error
#
#   4- modify host with only IP addresses/MAC/etc.
#	orr(idrr) = nrr(idrr)
#	=> update orr with rr, and replace IP addresses
#	=> return orr(idrr)
#
#   5- rename host to a non-existing name, old name was MA/MX
#	orr = not empty (with mx or mailaddr), nrr = empty
#	=> create a new rr for the new host name, migrate all refs to the host
#	    (e.g. if this host is a mailbox host or a MX target)
#	=> return new rr(idrr)
#	
#   6- rename host to a non-existing name, old name was only a host
#	orr = not empty (without mx or mailaddr), nrr = empty
#	=> update orr with rr, and replace IP addresses
#	=> return orr(idrr)
#	
#   7- rename host to an existing name without IP address, new name is MA/MX,
#		old name was a host with MA/MX
#	orr = not empty (with mx or mailaddr), nrr = not empty (with MX/MA)
#	=> update nrr with rr, add IP address to nrr, migrate refs to the host
#	=> return nrr(idrr)
#	
#   8- rename host to an existing name without IP address, new name is MA/MX,
#		old name was just a host (without MA/MX)
#	orr = not empty (without mx or mailaddr), nrr = not empty (with MX/MA)
#	=> update nrr with rr, add IP address to nrr, migrate refs to the host
#	=> remove orr
#	=> return nrr(idrr)
#	
#   9- rename host to an existing name with IP address (existing host)
#	=> error
#

proc hosts-new-and-mod {_parm orr} {

    #
    # Use oidrr == -1 as the test for a new host (vs host modification)
    #

    set oidrr -1
    if {[::rr::found $orr]} then {
	set oidrr [::rr::get-idrr $orr]
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
    # Check new IP addresses
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
    # Check if new IP addresses are already allocated to some other hosts
    # (but don't check our existing addresses if oidrr != -1)
    #

    set sql "SELECT DISTINCT jaddr
		FROM (VALUES $vaddr) AS vaddr (jaddr)
		    INNER JOIN dns.rr_ip ON (addr = jaddr)
		    NATURAL INNER JOIN dns.rr
		WHERE rr.idview = $idview AND rr.idrr != $oidrr
		"
    set lbad {}
    ::dbdns exec $sql tab {
	lappend lbad $tab(jaddr)
    }
    if {[llength $lbad] > 0} then {
	::scgi::serror 403 [mc "IP addresses already exist (%s)" [join $lbad ", "]]
    }

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
	set ttl -1
    }

    if {"smtp" in [::n capabilities]} then {
	set sendsmtp [expr $sendsmtp != 0]
    } else {
	set sendsmtp 0
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

    ######################################################################
    # Prepare variables
    ######################################################################


    set nidrr -1
    if {[::rr::found $nrr]} then {
	set nidrr [::rr::get-idrr $nrr]
    }

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

    ######################################################################
    # Test all cases (see proc header comments for case numbers)
    ######################################################################

    set sameid [expr $oidrr == $nidrr]

    set oldisother 0
    if {$oidrr != -1} then {
	set oldisother [::rr::is-other-than-host $orr]
    }

    set newishost 0
    if {$nidrr != -1} then {
	set newishost [expr [llength [::rr::get-ip $nrr]] > 0]
    }

    set selector "$oidrr:$nidrr:$sameid:$oldisother:$newishost"

    switch -glob -- $selector {
	-1:-1:*:*:* {
	    # case 1: new host with a new name

	    TODO
	}
	-1:*:*:*:0 {
	    # case 2: new host with an existing name (e.g. mailaddr or mx)

	    TODO
	}
	-1:*:*:*:1 {
	    # case 3: new host with an existing name which is already a host
	    ::scgi::serror 412 [mc {Host '%s' already exists} $name]
	}
	*:-1:*:1:* {
	    # case 5: rename to a non existing name, old name is still a MA/MX

	    TODO
	}
	*:-1:*:0:* {
	    # case 6: rename to a non existing name, old name was only a host

	    TODO
	}
	*:*:1:*:* {
	    # case 4: just modify the existing host

	    TODO
	}
	*:*:0:*:1 {
	    # case 9: rename to an existing name, new is already a host
	    ::scgi::serror 412 [mc {Host '%s' already exists} $name]
	}
	*:*:0:1:0 {
	    # case 7: rename to an existing name, old was MA/MX, new is MA/MX

	    TODO
	}
	*:*:0:0:0 {
	    # case 8: rename to an existing name, old was host, new is MA/MX

	    TODO
	}
    }

##############################################################################

    #
    # Check if host already exists,
    # and create RR if needed
    #

    if {[::rr::found $nrr]} then {
	#
	# Check if host already exists
	#

	set idrr [::rr::get-idrr $nrr]
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

    ::scgi::set-header Content-Type text/plain
    ::scgi::set-body $idrr
}

##############################################################################

api-handler delete {/hosts/([0-9]+:idhost)} logged {
    } {
    set rrh [::rr::read-by-idhost ::dbdns $idhost]
    if {! [::rr::found $rrh]} then {
	::scgi::serror 404 [mc "Host not found"]
    }

    set name   [::rr::get-name $rrh]
    set domain [::rr::get-domain $rrh]
    set idview [::rr::get-idview $rrh]

    set msg [check-authorized-host ::dbdns [::n idcor] $name $domain $idview rr "existing-host"]
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


