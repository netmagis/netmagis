api-handler get {/gen/dhcp} genz {
	view		0
	gen		0
    } {
    #
    # Integrate query parameters as a WHERE clause
    #

    set where {}
    if {$view ne ""} then {
	set qview [pg_quote $view]
	lappend where "v.name = $qview"
    }
    if {$gen ne ""} then {
	if {! [regexp {^[01]$} $gen]} then {
	    ::scgi::serror 400 [mc "Invalid 'gen' value"]
	}
	lappend where "gendhcp = $gen"
    }

    if {[llength $where] > 0} then {
	set where [join $where " AND "]
	set where "WHERE $where"
    }

    #
    # Extract zones (we do not distinguish forward/reverse zones here)
    #

    set sql "SELECT COALESCE (json_agg (t), '\[\]') AS j FROM (
			SELECT v.name, v.gendhcp AS gen, v.counter
			    FROM dns.view v
			    $where
			    ORDER BY v.name
		    ) t
		"
    ::dbdns exec $sql tab {
	set j $tab(j)
    }
    ::scgi::set-header Content-Type application/json
    ::scgi::set-body $j
}

api-handler post {/gen/dhcp} genz {
    } {
    # get body just to check it's a JSON body
    ::scgi::get-body-json $_parm

    set dbody [dict get $_parm "_bodydict"]

    set spec {array {object {
				{name	{type string req} req}
				{counter {type int req} req}
			}
			req
		    }
		    req
		}
    set body [::scgi::check-json-value $dbody $spec]

    #
    # Special case for empty list
    #

    if {[llength $body] > 0} then {

	#
	# Lock database for an atomic operation
	#

	::dbdns lock {dns.view} {
	    #
	    # Get view counters supplied by client
	    #

	    set lv {}
	    foreach jv $body {
		::scgi::import-json-object $jv
		lappend lv [pg_quote $name]
	    }

	    set lv [join $lv ","]
	    set sql "SELECT name, counter FROM dns.view WHERE name IN ($lv)"
	    ::dbdns exec $sql tab {
		set cnt($tab(name)) $tab(counter)
	    }

	    #
	    # Build and execute the SQL commands to update view generation flag
	    #

	    set lvgen {}
	    set update {}
	    foreach jv $body {
		::scgi::import-json-object $jv
		set qname [pg_quote $name]
		if {$cnt($name) eq $counter} then {
		    lappend lvgen $qname
		}
	    }

	    if {[llength $lvgen] > 0} then {
		set lvgen [join $lvgen ","]
		set sql "UPDATE dns.view SET gendhcp = 0 WHERE name IN ($lvgen)"
		::dbdns exec $sql
	    }
	}
    }

    ::scgi::set-header Content-Type application/json
    ::scgi::set-body "null"

    return
}

proc tojson {k v injson} {
    if {! $injson} then {
	set v "\"$v\""
    }
    return "\"$k\": $v"
}

# name: view name
api-handler get {/gen/dhcp/([^/]+:name)} genz {
    } {

    set idview [::n viewid $name]
    if {$idview == -1} then {
	::scgi::serror 404 [mc "View '%s' not found" $name]
    }

    #
    # Get global configuration parameters for DHCP
    #

    set json {}
    ::dbdns lock {global.config
                    dns.view
                    dns.network
                    dns.dhcprange
                    dns.dhcpprofile
                    dns.name
                    dns.domain
                    dns.host
                    dns.addr} {
	#
	# Get global values
	#

	set sql "SELECT to_json (counter) AS value
		    FROM dns.view
		    WHERE idview = $idview
		    "
	::dbdns exec $sql tab {
	    lappend json [tojson "counter" $tab(value) true]
	}

	set lv {}
	foreach k {default_lease_time
			max_lease_time
			dhcpdefdomain
			dhcpdefdnslist} {
	    set tabk($k) 0
	    lappend lv [pg_quote $k]
	}
	set lv [join $lv ","]
	set sql "SELECT key, to_json (value) AS value
		    FROM global.config
		    WHERE key IN ($lv)
		    "
	::dbdns exec $sql tab {
	    lappend json [tojson $tab(key) $tab(value) true]
	    incr tabk($tab(key))
	}
	foreach k [array names tabk] {
	    if {$tabk($k) == 0} then {
		lappend json [tojson $k "" false]
	    }
	}

	#
	# Get profiles
	#

	set sql "SELECT COALESCE (json_agg (t), '\[\]') AS j FROM (
			SELECT name, text
			    FROM dns.dhcpprofile
			    ORDER BY name
			) t
		    "
	::dbdns exec $sql tab {
	    set j $tab(j)
	}
	lappend json [tojson "profiles" $j true]

	#
	# Get subnets
	#

	set sql "SELECT COALESCE (json_agg (t), '\[\]') AS j FROM (
			SELECT addr4 AS network,
			    HOST (addr4) AS addr,
			    NETMASK (addr4) AS netmask,
			    gw4 AS gw,
			    comment AS comment
			FROM dns.network
			WHERE dhcp > 0 AND gw4 IS NOT NULL
			ORDER BY addr4
			) t
		    "
	::dbdns exec $sql tab {
	    set j $tab(j)
	}
	lappend json [tojson "subnets" $j true]

	#
	# Get ranges
	#

	set sql "SELECT COALESCE (json_agg (t), '\[\]') AS j FROM (
			SELECT
			    nw.addr4 AS network,
			    d.name AS domain,
			    r.min,
			    r.max,
			    r.default_lease_time,
			    r.max_lease_time,
			    p.name AS profile
			FROM dns.network nw, dns.dhcprange r
			    NATURAL INNER JOIN dns.domain d
			    LEFT OUTER JOIN dns.dhcpprofile p USING (iddhcpprof)
			WHERE nw.dhcp > 0 AND nw.gw4 IS NOT NULL
			    AND r.min <<= nw.addr4
			    AND r.max <<= nw.addr4
			) t
		    "
	::dbdns exec $sql tab {
	    set j $tab(j)
	}
	lappend json [tojson "ranges" $j true]

	#
	# Get hosts
	#

	set sql "SELECT COALESCE (json_agg (t), '\[\]') AS j FROM (
		    SELECT nw.addr4 AS network,
			    n.name || '.' || d.name AS name,
			    h.mac,
			    a.addr,
			    p.name AS profile
			FROM dns.name n
			    INNER JOIN dns.domain d USING (iddom)
			    INNER JOIN dns.host h USING (idname)
			    INNER JOIN dns.addr a USING (idhost)
			    LEFT OUTER JOIN dns.dhcpprofile p USING (iddhcpprof)
			    , dns.network nw
			WHERE n.idview = $idview
			    AND nw.dhcp > 0 AND nw.gw4 IS NOT NULL
			    AND a.addr <<= nw.addr4
			    AND h.mac IS NOT NULL
			) t
		    "
	::dbdns exec $sql tab {
	    set j $tab(j)
	}
	lappend json [tojson "hosts" $j true]
    }

    set json [join $json ","]
    set j "\{$json\}"

    ::scgi::set-header Content-Type application/json
    ::scgi::set-body $j
}
