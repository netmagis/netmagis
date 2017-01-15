##############################################################################

api-handler get {/dhcpranges} logged {
	cidr 1
    } {

    if {! [::ip::is "ipv4" $cidr]} then {
	::scgi::serror 412 [mc {Invalid query parameter (%1$s=%2$s)} cidr $cidr]
    }

    set qcidr [pg_quote $cidr]
    set idgrp [::n idgrp]

    #
    # In order to be viewed, a DHCP range must be:
    # - inside the given CIDR
    # - the given CIDR itself must be inside a DHCP-enabled network
    #	which is allowed for our group
    # In order to be "editable", in addition to previous conditions,
    # a DHCP range must:
    # - reference an allowed domain
    # - reference an allowed DHCP profile (or not reference any DHCP profile)
    # - have all its addresses (between min and max) as allowed
    #

    set sql "SELECT COALESCE (json_agg (t), '\[\]') AS j FROM (
		SELECT d.iddhcprange, d.min, d.max, d.iddom,
			dom.name AS domain,
			d.default_lease_time, d.max_lease_time,
			d.iddhcpprof, dh.name AS dhcpprofile,
			BOOL_AND (pd.iddom IS NOT NULL
				    AND pip.allow_deny = 1
				    AND (d.iddhcpprof IS NULL
					OR pdh.iddhcpprof IS NOT NULL)
				    ) AS editable
		    FROM dns.dhcprange d
			INNER JOIN dns.domain dom USING (iddom)
			INNER JOIN dns.network n ON ($qcidr <<= n.addr4)
			INNER JOIN dns.p_network pn USING (idnet)
			LEFT OUTER JOIN dns.p_dom pd
			    ON (pd.idgrp = $idgrp AND pd.iddom = d.iddom)
			LEFT OUTER JOIN dns.dhcpprofile dh USING (iddhcpprof)
			LEFT OUTER JOIN dns.p_dhcpprofile pdh
			    ON (pdh.idgrp = $idgrp
				AND pdh.iddhcpprof = d.iddhcpprof)
			INNER JOIN dns.p_ip pip
			    ON (pip.idgrp = $idgrp
			    -- select IP permissions overlapping this range
			    AND NOT (host (broadcast (pip.addr))::inet < d.min
				    OR host (network (pip.addr))::inet > d.max)
			    )
		    WHERE d.min <<= $qcidr AND d.max <<= $qcidr
			AND n.dhcp != 0
			AND pn.dhcp != 0
		    GROUP BY d.iddhcprange, d.min, d.max, d.iddom, dom.name,
			d.default_lease_time, d.max_lease_time,
			d.iddhcpprof, dh.name
		    ORDER BY d.min
		) AS t
		"
    ::dbdns exec $sql tab {
	set j $tab(j)
    }
    ::scgi::set-header Content-Type application/json
    ::scgi::set-body $j
}

##############################################################################

api-handler post {/dhcpranges} logged {
    } {
    set idgrp [::n idgrp]
    set iddhcprange [dhcp-new -1 $idgrp $_parm]
    set j [dhcp-get $iddhcprange $idgrp]
    ::scgi::set-header Content-Type application/json
    ::scgi::set-body $j
}

##############################################################################

api-handler get {/dhcpranges/([0-9]+:iddhcprange)} logged {
    } {
    set j [dhcp-get $iddhcprange [::n idgrp]]
    ::scgi::set-header Content-Type application/json
    ::scgi::set-body $j
}

##############################################################################

api-handler put {/dhcpranges/([0-9]+:iddhcprange)} logged {
    } {
    set idgrp [::n idgrp]
    set j [dhcp-new $iddhcprange $idgrp $_parm]
    set j [dhcp-get $iddhcprange $idgrp]
    ::scgi::set-header Content-Type application/json
    ::scgi::set-body $j
}

##############################################################################

api-handler delete {/dhcpranges/([0-9]+:iddhcprange)} logged {
    } {
    if {! [dhcp-is-editable $iddhcprange [::n idgrp]]} then {
	::scgi::serror 404 [mc "DHCP range not found or unauthorized"]
    }

    set sql "DELETE FROM dns.dhcprange WHERE iddhcprange = $iddhcprange"
    ::dbdns exec $sql

    ::scgi::set-header Content-Type text/plain
    ::scgi::set-body "OK"
}

##############################################################################
# Utility functions
##############################################################################

proc dhcp-is-editable {iddhcprange idgrp} {
    set sql "SELECT d.iddhcprange, BOOL_AND (pd.iddom IS NOT NULL
				    AND pip.allow_deny = 1
				    AND (d.iddhcpprof IS NULL
					OR pdh.iddhcpprof IS NOT NULL)
				    ) AS editable
		    FROM dns.dhcprange d
			INNER JOIN dns.network n
			    ON (d.min <<= n.addr4 AND d.max <<= n.addr4)
			INNER JOIN dns.p_network pn USING (idnet)
			LEFT OUTER JOIN dns.p_dom pd
			    ON (pd.idgrp = $idgrp AND pd.iddom = d.iddom)
			LEFT OUTER JOIN dns.p_dhcpprofile pdh
			    ON (pdh.idgrp = $idgrp
				AND pdh.iddhcpprof = d.iddhcpprof)
			INNER JOIN dns.p_ip pip
			    ON (pip.idgrp = $idgrp
			    -- select IP permissions overlapping this range
			    AND NOT (host (broadcast (pip.addr))::inet < d.min
				    OR host (network (pip.addr))::inet > d.max)
			    )
		    WHERE iddhcprange = $iddhcprange
			AND n.dhcp != 0
			AND pn.dhcp != 0
		    GROUP BY d.iddhcprange
		    "
    set editable 0
    ::dbdns exec $sql tab {
	if {$tab(editable) eq "t"} then {
	    set editable 1
	}
    }
    return $editable
}

proc dhcp-get {iddhcprange idgrp} {
    set sql "SELECT row_to_json (t.*) AS j FROM (
		SELECT d.iddhcprange, d.min, d.max, d.iddom,
			dom.name AS domain,
			d.default_lease_time, d.max_lease_time,
			d.iddhcpprof, dh.name AS dhcpprofile,
			BOOL_AND (pd.iddom IS NOT NULL
				    AND pip.allow_deny = 1
				    AND (d.iddhcpprof IS NULL
					OR pdh.iddhcpprof IS NOT NULL)
				    ) AS editable
		    FROM dns.dhcprange d
			INNER JOIN dns.domain dom USING (iddom)
			INNER JOIN dns.network n
			    ON (d.min <<= n.addr4 AND d.max <<= n.addr4)
			INNER JOIN dns.p_network pn USING (idnet)
			LEFT OUTER JOIN dns.p_dom pd
			    ON (pd.idgrp = $idgrp AND pd.iddom = d.iddom)
			LEFT OUTER JOIN dns.dhcpprofile dh USING (iddhcpprof)
			LEFT OUTER JOIN dns.p_dhcpprofile pdh
			    ON (pdh.idgrp = $idgrp
				AND pdh.iddhcpprof = d.iddhcpprof)
			INNER JOIN dns.p_ip pip
			    ON (pip.idgrp = $idgrp
			    -- select IP permissions overlapping this range
			    AND NOT (host (broadcast (pip.addr))::inet < d.min
				    OR host (network (pip.addr))::inet > d.max)
			    )
		    WHERE d.iddhcprange = $iddhcprange
			AND n.dhcp != 0
			AND pn.dhcp != 0
		    GROUP BY d.iddhcprange, d.min, d.max, d.iddom, dom.name,
			d.default_lease_time, d.max_lease_time,
			d.iddhcpprof, dh.name
		) AS t
		"
    set found 0
    ::dbdns exec $sql tab {
	set j $tab(j)
	set found 1
    }
    if {! $found} then {
	::scgi::serror 404 [mc "DHCP range not found or unauthorized"]
    }
    return $j
}

##############################################################################

proc dhcp-new {iddhcprange idgrp _parm} {
    # get body just to check it's a JSON body
    ::scgi::get-body-json $_parm

    set dbody [dict get $_parm "_bodydict"]

    set spec {object {
			{min			{type inet4 req} req}
			{max			{type inet4 req} req}
			{iddom			{type int opt -1} req}
			{default_lease_time	{type int opt 0} req}
			{max_lease_time		{type int opt 0} req}
			{iddhcpprof		{type int opt -1} req}
		    } req
		}
    set body [::scgi::check-json-value $dbody $spec]
    ::scgi::import-json-object $body

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
		FROM dns.host
		    NATURAL INNER JOIN dns.addr
		WHERE mac IS NOT NULL
		    AND addr >= $qmin
		    AND addr <= $qmax
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

    return $iddhcprange
}
