##############################################################################

api-handler get {/dhcpranges} yes {
	cidr 1
    } {

    set qcidr [pg_quote $cidr]
    set idgrp [::u idgrp]

    set sql "SELECT COALESCE (json_agg (t), '\[\]') AS j FROM (
		SELECT d.*
		    FROM dns.dhcprange d
			INNER JOIN dns.p_dom p USING (iddom)
		    WHERE min <<= $qcidr
			AND max <<= $qcidr
			AND p.idgrp = $idgrp
			AND dns.check_dhcprange_grp ($idgrp, min, max)
		    ORDER BY min
		) AS t
		"
    ::dbdns exec $sql tab {
	set j $tab(j)
    }
    ::scgi::set-header Content-Type application/json
    ::scgi::set-body $j
}

##############################################################################

api-handler post {/dhcpranges} yes {
    } {
    set idgrp [::u idgrp]
    set iddhcprange [dhcp-new -1 $idgrp $_parm]
    set j [dhcp-get $iddhcprange $idgrp]
    ::scgi::set-header Content-Type application/json
    ::scgi::set-body $j
}

##############################################################################

api-handler get {/dhcpranges/([0-9]+:iddhcprange)} yes {
    } {
    set j [dhcp-get $iddhcprange [::u idgrp]]
    ::scgi::set-header Content-Type application/json
    ::scgi::set-body $j
}

##############################################################################

api-handler put {/dhcpranges/([0-9]+:iddhcprange)} yes {
    } {
    set idgrp [::u idgrp]
    set j [dhcp-new $iddhcprange $idgrp $_parm]
    set j [dhcp-get $iddhcprange [::u idgrp]]
    ::scgi::set-header Content-Type application/json
    ::scgi::set-body $j
}

##############################################################################

api-handler delete {/dhcpranges/([0-9]+:iddhcprange)} yes {
    } {
    set idgrp [::u idgrp]

    set sql "SELECT iddhcprange
		    FROM dns.dhcprange
			INNER JOIN dns.p_dom p USING (iddom)
		    WHERE iddhcprange = $iddhcprange
			AND p.idgrp = $idgrp
			AND dns.check_dhcprange_grp ($idgrp, min, max)
		"
    set found 0
    ::dbdns exec $sql tab {
	set found 1
    }
    if {! $found} then {
	::scgi::serror 404 [mc "DHCP range not found"]
    }

    set sql "DELETE FROM dns.dhcprange WHERE iddhcprange = $iddhcprange"
    ::dbdns exec $sql

    ::scgi::set-header Content-Type text/plain
    ::scgi::set-body "OK"
}

##############################################################################
# Utility functions
##############################################################################

proc dhcp-get {iddhcprange idgrp} {
    set sql "SELECT row_to_json (t.*) AS j FROM (
		SELECT *
		    FROM dns.dhcprange
		    WHERE iddhcprange = $iddhcprange
			AND dns.check_dhcprange_grp ($idgrp, min, max)
		) AS t
		"
    set found 0
    ::dbdns exec $sql tab {
	set j $tab(j)
	set found 1
    }
    if {! $found} then {
	::scgi::serror 404 [mc "DHCP range not found"]
    }
    return $j
}

##############################################################################

proc dhcp-new {iddhcprange idgrp _parm} {
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

    if {! [::u isalloweddom $iddom]} then {
	::scgi::serror 412 [mc "Invalid domain '%s'" $iddom]
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
    # Check dhcpprofile
    #

    if {$iddhcpprof == -1} then {
	# for SQL insert/update below
	set iddhcpprof "NULL"
    } else {
	set sql "SELECT iddhcpprof
		    FROM dns.dhcpprofile
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
    # Check address ownership
    #

    set sql "SELECT count(*) AS c
		FROM dns.network n
		    INNER JOIN dns.p_network p USING (idnet)
		WHERE p.idgrp = $idgrp
		    AND n.addr4 >>= (inet $qmin)
		    AND n.addr4 >>= (inet $qmax)
	    "
    ::dbdns exec $sql tab {
	set c $tab(c)
    }
    if {$c == 0} then {
	::scgi::serror 412 [mc {Range (%1$s,%2$s) is not in an allowed network} $min $max]
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
	::scgi::serror 412 [mc {Range (%1$s,%2$s) overlaps another range} $min $max]
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
	:scgi::serror 412 [mc {Conflict between dynamic range (%1$s) and %2$s IP address(es) declared with a MAC address} "$min...$max" $c]
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
