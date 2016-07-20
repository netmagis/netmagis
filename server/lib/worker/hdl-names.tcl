##############################################################################

api-handler get {/names} logged {
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

api-handler post {/names} logged {
    } {
    set idgrp [::n idgrp]
    # get body just to check it's a JSON body
    ::scgi::get-body-json $_parm

    set dbody [dict get $_parm "_bodydict"]

    set spec {
		{min inet4}
		{max inet4}
		{iddom int -1}
		{default_lease_time int 0}
		{max_lease_time int 0}
		{iddhcpprof int -1}
	    }
    if {! [::scgi::check-json-attr $dbody $spec]} then {
	::scgi::serror 412 [mc "Invalid JSON input"]
    }

    set min_lease_time [::config get "min_lease_time"]

    #
    # Check iddom
    #

    if {! [::n isalloweddom $iddom]} then {
	::scgi::serror 412 [mc "Invalid domain '%s'" $iddom]
    }

    #
    # Check dhcpprofile
    #

    if {$iddhcpprof == -1} then {
	# for SQL insert/update below
	set iddhcpprof "NULL"
    } else {
	set sql "SELECT iddhcpprof
		    FROM dns.p_dhcpprofile
		    WHERE iddhcpprof = $iddhcpprof"
	set found 0
	::dbdns exec $sql tab {
	    set found 1
	}
	if {! $found} then {
	    ::scgi::serror 412 [mc {Invalid profile}]
	}
    }

    #
    # Check *_lease_time values
    #

    if {$default_lease_time != 0 && $default_lease_time < $min_lease_time} then {
	::scgi::serror 404 [mc "Default_lease_time value less than '%s'" $min_lease_time]
    }

    if {$max_lease_time != 0 && $max_lease_time < $min_lease_time} then {
	::scgi::serror 404 [mc "Max_lease_time value less than '%s'" $min_lease_time]
    }

    #
    # Check min <= max
    #

    set qmin [pg_quote $min]
    set qmax [pg_quote $max]

    set sql "SELECT (inet $qmin <= inet $qmax) AS r"
    ::dbdns exec $sql tab {
	set r $tab(r)
    }
    if {$r eq "f"} then {
	::scgi::serror 412 [mc {Invalid address range (%1$s > %2$s)} $min $max]
    }

    #
    # Check old range, if any
    #

    if {$iddhcprange != -1} then {
	if {! [dhcp-is-editable $idgrp $iddhcprange]} then {
	    ::scgi::serror 412 [mc {Unauthorized existing range}]
	}
    }

    #
    # Check network ownership
    #

    set sql "SELECT count(*) AS c
		FROM dns.network n
		    INNER JOIN dns.p_network p USING (idnet)
		WHERE p.idgrp = $idgrp
		    AND n.dhcp != 0
		    AND (inet $qmin) <<= n.addr4
		    AND (inet $qmax) <<= n.addr4
	    "
    ::dbdns exec $sql tab {
	set c $tab(c)
    }
    if {$c == 0} then {
	::scgi::serror 412 [mc {Range (%1$s...%2$s) is not in an allowed network} $min $max]
    }

    #
    # Check individual addresses permissions
    #

    set sql "SELECT BOOL_AND (allow_deny = 1) AS editable
		FROM dns.p_ip
		WHERE idgrp = $idgrp
		    AND NOT (host (broadcast (addr))::inet < (inet $qmin)
			    OR host (network (addr))::inet > (inet $qmax))
	    "
    set editable 0
    ::dbdns exec $sql tab {
	switch $tab(editable) {
	    {}  { set editable 0 }
	    {t} { set editable 1 }
	    {f} { set editable 0 }
	}
    }
    if {$editable == 0} then {
	::scgi::serror 412 [mc {Range (%1$s...%2$s) holds unauthorized addresses} $min $max]
    }

    #
    # Check overlap with other dynamic ranges
    #

    set notme ""
    if {$iddhcprange != -1} then {
	set notme "AND iddhcprange != $iddhcprange"
    }

    set sql "SELECT count(*) AS c
		FROM dns.dhcprange
		    WHERE
			(inet $qmax) >= min AND (inet $qmin) <= max
			$notme"
    ::dbdns exec $sql tab {
	set c $tab(c)
    }
    if {$c != 0} then {
	::scgi::serror 412 [mc {Range (%1$s...%2$s) overlaps another range} $min $max]
    }

    #
    # Check overlap with static DHCP hosts
    #

    set sql "SELECT count(*) AS c
		FROM dns.rr
		    INNER JOIN dns.rr_ip USING (idrr)
		WHERE rr.mac IS NOT NULL
		    AND rr_ip.addr >= $qmin
		    AND rr_ip.addr <= $qmax
		    "
    ::dbdns exec $sql tab {
	set c $tab(c)
    }
    if {$c > 0} then {
	:scgi::serror 412 [mc {Conflict between dynamic range (%1$s...%2$s) and %3$s IP address(es) declared with a MAC address} $min $max $c]
    }

    #
    # Insert or update
    #

    if {$iddhcprange == -1} then {
	set sql "INSERT INTO dns.dhcprange
			(min, max, iddom, iddhcpprof,
			    default_lease_time, max_lease_time)
		    VALUES ($qmin, $qmax, $iddom, $iddhcpprof,
			   $default_lease_time, $max_lease_time)
		    RETURNING iddhcprange
		"
    } else {
	set sql "UPDATE dns.dhcprange
		    SET 
			min = $qmin,
			max = $qmax,
			iddom = $iddom,
			iddhcpprof = $iddhcpprof,
			default_lease_time = $default_lease_time,
			max_lease_time = $max_lease_time
		    WHERE iddhcprange = $iddhcprange
		    RETURNING iddhcprange
		    "
    }
    ::dbdns exec $sql tab {
	set iddhcprange $tab(iddhcprange)
    }

    set j [dhcp-get $iddhcprange $idgrp]
    ::scgi::set-header Content-Type application/json
    ::scgi::set-body $j
}

##############################################################################

api-handler get {/names/([0-9]+:idrr)} logged {
    } {
    set j [names-get $idrr [::n idgrp]]
    ::scgi::set-header Content-Type application/json
    ::scgi::set-body $j
}

##############################################################################

api-handler put {/names/([0-9]+:idrr)} logged {
    } {
    set idgrp [::n idgrp]
#    set j [dhcp-new $iddhcprange $idgrp $_parm]
    set j [names-get $idrr $idgrp]
    ::scgi::set-header Content-Type application/json
    ::scgi::set-body $j
}

##############################################################################

api-handler delete {/names/([0-9]+:idrr)} logged {
    } {
    ::scgi::set-header Content-Type text/plain
    ::scgi::set-body "OK"
}

##############################################################################
# Utility functions
##############################################################################

proc names-get {idrr idgrp} {
    set sql "SELECT row_to_json (t.*) AS j FROM (
		SELECT
		    r.idrr,
		    r.name,
		    r.iddom,
		    domain.name AS domain,
		    r.idview,
		    view.name AS view,
		    COALESCE (CAST (r.mac AS text), '') AS mac,
		    r.idhinfo,
		    hinfo.name AS hinfo,
		    COALESCE (r.comment, '') AS comment,
		    COALESCE (r.respname, '') AS respname,
		    COALESCE (r.respmail, '') AS respmail,
		    COALESCE (iddhcpprof, -1) AS iddhcpprof,
		    COALESCE (dhcpprofile.name, '') AS dhcpprofile,
		    r.sendsmtp,
		    r.ttl,
		    nmuser.login AS user,
		    r.idcor AS idcor,
		    r.date AS lastmod,
		    COALESCE (f1.idrr, -1) AS idcname,
		    COALESCE (f1.name, '') AS cname,
		    COALESCE (sreq_aliases.aliases, '{}') AS aliases,
		    COALESCE (f2.idrr, -1) AS idmboxhost,
		    COALESCE (f2.idview, -1) AS idmboxhostview,
		    COALESCE (f2.name, '') AS mboxhost,
		    COALESCE (sreq_mailaddr.mailaddr, '{}') AS mailaddr,
		    COALESCE (sreq_mx.mx, '{}') AS mx,
		    COALESCE (sreq_mxtarg.mxtarg, '{}') AS mxtarg,
		    COALESCE (sreq_ip.ip, '{}') AS ip
		FROM dns.rr r
		    INNER JOIN dns.domain USING (iddom)
		    INNER JOIN dns.view USING (idview)
		    INNER JOIN dns.hinfo USING (idhinfo)
		    LEFT OUTER JOIN dns.dhcpprofile USING (iddhcpprof)
		    INNER JOIN global.nmuser USING (idcor)
		    LEFT OUTER JOIN dns.rr_cname USING (idrr)
		    LEFT OUTER JOIN dns.fqdn f1 ON rr_cname.cname = f1.idrr
		    LEFT OUTER JOIN dns.mail_role mr ON r.idrr = mr.mailaddr
		    LEFT OUTER JOIN dns.fqdn f2 ON mr.mboxhost = f2.idrr
		    , LATERAL (
			SELECT array_agg (addr) AS ip
			    FROM dns.rr_ip
			    WHERE rr_ip.idrr = r.idrr
			) AS sreq_ip
		    , LATERAL (
			SELECT array_agg (json_build_object (
					'idalias', fqdn.idrr,
				    'alias', fqdn.name,
				    'aliaslink', global.mklink ('/names/', fqdn.idrr)
				)) AS aliases
			    FROM dns.rr_cname
				INNER JOIN dns.fqdn USING (idrr)
			    WHERE rr_cname.cname = r.idrr
			) AS sreq_aliases
		    , LATERAL (
			SELECT array_agg (json_build_object (
					'idmailaddr', fqdn.idrr,
					'idmailaddrview', fqdn.idview,
				    'mailaddr', fqdn.name,
				    'mailaddrlink', global.mklink ('/names/', fqdn.idrr)
				)) AS mailaddr
			    FROM dns.mail_role
				INNER JOIN dns.fqdn ON fqdn.idrr = mail_role.mailaddr
			    WHERE mboxhost = r.idrr
			) AS sreq_mailaddr
		    , LATERAL (
			SELECT array_agg (json_build_object (
					'idmx', fqdn.idrr,
				    'prio', prio,
				    'mx', fqdn.name,
				    'mxlink', global.mklink ('/names/', fqdn.idrr)
				)) AS mx
			    FROM dns.rr_mx
				INNER JOIN dns.fqdn ON rr_mx.mx = fqdn.idrr
			    WHERE rr_mx.idrr = r.idrr
			) AS sreq_mx
		    , LATERAL (
			SELECT array_agg (json_build_object (
					'idmxtarg', fqdn.idrr,
				    'mxtarg', fqdn.name,
				    'mxtarglink', global.mklink ('/names/', fqdn.idrr)
				)) AS mxtarg
			    FROM dns.rr_mx
				INNER JOIN dns.fqdn ON rr_mx.idrr = fqdn.idrr
			    WHERE rr_mx.mx = r.idrr
			) AS sreq_mxtarg
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
