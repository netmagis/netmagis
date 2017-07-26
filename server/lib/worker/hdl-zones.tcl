api-handler get {/zones} genz {
	name		0
	view		0
	gen		0
    } {
    #
    # Integrate query parameters as a WHERE clause
    #

    set where {}
    if {$name ne ""} then {
	set qname [pg_quote $name]
	lappend where "z.name = $qname"
    }
    if {$view ne ""} then {
	set qview [pg_quote $view]
	lappend where "v.name = $qview"
    }
    if {$gen ne ""} then {
	if {! [regexp {^[01]$} $gen]} then {
	    ::scgi::serror 400 [mc "Invalid 'gen' value"]
	}
	lappend where "gen = $gen"
    }

    if {[llength $where] > 0} then {
	set where [join $where " AND "]
	set where "WHERE $where"
    }

    #
    # Extract zones (we do not distinguish forward/reverse zones here)
    #

    set sql "SELECT COALESCE (json_agg (t), '\[\]') AS j FROM (
			SELECT z.name, z.idview, z.gen
			    FROM dns.zone z
				INNER JOIN dns.view v USING (idview)
			    $where
			    ORDER BY z.name
		    ) t
		"
    ::dbdns exec $sql tab {
	set j $tab(j)
    }
    ::scgi::set-header Content-Type application/json
    ::scgi::set-body $j
}

api-handler get {/zones/([^/]+:name)} logged {
    } {
    gen-zone $name nversion
}


api-handler post {/zones/([^/]+:name)} logged {
    } {
    ::dbdns lock {dns.zone_forward dns.zone_reverse4 dns.zone_reverse6} {
	gen-zone $name nversion

	set qname [pg_quote $name]
	set sql "UPDATE dns.zone
		    SET version=$nversion, gen=0
		    WHERE name = $qname"
	::dbdns exec $sql
    }
}

#
# Generate a JSON object for zone generation, without modifying 
# state (version, gen).
#

proc gen-zone {name _nversion} {
    upvar $_nversion nversion

    set qname [pg_quote $name]

    #
    # Get the zone child table name (zone_forward/zone_reverse[46])
    # and various zone parameters such as zone serial number
    #

    set sql "SELECT n.nspname || '.' || c.relname AS table,
			zone.version,
			to_json (zone.prologue) AS prologue,
			to_json (zone.rrsup) AS rrsup,
			zone.gen, zone.idview
		    FROM dns.zone, pg_class c, pg_namespace n
		    WHERE name = $qname
			AND c.oid = zone.tableoid
			AND c.relnamespace = n.oid
			"
    set found 0
    ::dbdns exec $sql tab {
	# table = dns.zone_forward, dns.zone_reverse[46]
	set table	$tab(table)
	set version	$tab(version)
	set prologue	$tab(prologue)
	set rrsup	$tab(rrsup)
	set gen		$tab(gen)
	set idview	$tab(idview)
	set found 1
    }

    #
    # Zone not found
    #

    if {! $found} then {
	::scgi::serror 404 [mc "Zone '%s' not found" $name]
    }

    #
    # Get selection criterion
    #

    set sql "SELECT selection FROM $table WHERE name = $qname" 
    ::dbdns exec $sql tab {
	set selection $tab(selection)
    }

    #
    # Compute the new version number for the zone
    #

    set nversion [new-serial $version]

    #
    # Generate prologue with version number
    #

    if {[regsub {%ZONEVERSION%} $prologue $nversion prologue] != 1} then {
	::scgi::serrot 400 [mc "zone '%s': %%ZONEVERSION%% not found in prologue" $name]
    }

    #
    # Distinguish generation format
    #

    switch -- $table {
	dns.zone_forward {
	    set records [gen-fwd $name $selection $idview]
	}
	dns.zone_reverse4 {
	    set records [gen-ipv4 $name $selection $idview]
	}
	dns.zone_reverse6 {
	    set records [gen-ipv6 $name $selection $idview]
	}
	default {
	    ::scgi::serror 500 [mc {Internal error: zone '%1$s': invalid table ('%2$s')} $name $table]
	}
    }


    #
    # Assemble the two JSON parts (prologue, record) into a single object
    #

    set j "\{\"prologue\":$prologue, \"rrsup\":$rrsup, \"records\":$records\}"

    ::scgi::set-header Content-Type application/json
    ::scgi::set-body $j
}


#
# Compute the new serial of a zone
#
# Input:
#   - serial: old serial number
# Output:
#   - return value: new serial number
#
# Algorithm (see issue #47):
#   if current serial is empty (new zone)
#	then new serial := ctoday concatenated with 00
#	else
#	     parse the current serial (from the zone_*.version column)
#	        to get yyyymmdd and nn
#            if yyyymmdd < today
#	 	 then new serial := ctoday concatenated with 00
#		 else new serial := serial + 1
#
#   Properties of this algorithm:
#	- the serial is strictly monotonic
#	- it follows the yyyymmddnn convention when possible
#		(for aestethic reasons)
#	- if there is one modification every minute, starting from
#		2012/09/20, this algorithm will overflow the 32-bit SOA
#		serial in 4343,37 years, so in year 6355.
#
# History:
#   2012/09/20 : pda/jean : design of the new auto-adaptative algorithm
#   2013/09/09 :     jean : fix initial value bug
#

proc new-serial {serial} {
    set today [clock format [clock seconds] -format "%Y%m%d"]
    if {$serial eq ""} then {
	set nserial "${today}00"
    } elseif {[regexp {^(\d{8})(\d{2})$} $serial dummy odate onn]} then {
	if {$odate < $today} then {
	    set nserial "${today}00"
	} else {
	    set nserial [expr $serial+1]
	}
    } else {
	set nserial [expr $serial+1]
    }

    return $nserial
}

#
# Return zone contents for a forward zone as a JSON array
#
# Input:
#   - zone: name of zone to generate
#   - selection: selection criterion (domain name)
#   - idview: view associated with this zone
# Output:
#   - return value: json records
#
# History:
#   2002/04/26 : pda/jean : design
#   2004/03/09 : pda/jean : add mail role generation
#   2012/10/24 : pda/jean : add views
#

proc gen-fwd {zone selection idview} {
    #
    # Get working domain id
    #
    set iddom [::n domainid $selection]
    if {$iddom == -1} then {
	::scgi::serror 400 [mc {Zone '%1$s': domain '%2$s' not found in database} $zone $selection]
    }

    #
    # Get all IP (v4 or v6) addresses
    #

    set sql "SELECT COALESCE (json_agg (t), '\[\]') AS j FROM (
		-- A or AAAA
		SELECT n.name,
			h.ttl,
			CASE WHEN family (a.addr) = 4 THEN 'A'
			    WHEN family (a.addr) = 6 THEN 'AAAA'
			    ELSE '?'
			END AS type,
			host (a.addr) AS rdata
		    FROM dns.name n
			NATURAL INNER JOIN dns.host h
			NATURAL INNER JOIN dns.addr a
		    WHERE n.iddom = $iddom
			AND n.idview = $idview
		UNION
		-- MX: a MX n b 
		SELECT n1.name,
			mx.ttl,
			'MX'::text AS type,
			mx.prio::text || ' '
			    || n2.name || '.' || d2.name || '.'
			    AS rdata
		    FROM dns.name n1
			INNER JOIN dns.mx ON (n1.idname = mx.idname)
			INNER JOIN dns.host h2 ON (mx.idhost = h2.idhost)
			INNER JOIN dns.name n2 ON (h2.idname = n2.idname)
			INNER JOIN dns.domain d2 ON (n2.iddom = d2.iddom)
		    WHERE n1.iddom = $iddom
			AND n1.idview = $idview
		UNION
		-- aliases: a CNAME b
		SELECT n1.name,
			a.ttl,
			'CNAME'::text AS type,
			n2.name || '.' || d2.name || '.' AS rdata
		    FROM dns.name n1
			INNER JOIN dns.alias a ON (n1.idname = a.idname)
			INNER JOIN dns.host h2 ON (a.idhost = h2.idhost)
			INNER JOIN dns.name n2 ON (h2.idname = n2.idname)
			INNER JOIN dns.domain d2 ON (n2.iddom = d2.iddom)
		    WHERE n1.iddom = $iddom
			AND n1.idview = $idview
		UNION
		-- mail addresses are referring the mail relays for this domain
		SELECT n.name,
			rd.ttl,
			'MX'::text AS type,
			rd.prio::text || ' '
			    || nr.name || '.' || dr.name || '.'
			    AS rdata
		    FROM dns.name n
			INNER JOIN dns.mailrole mr ON (n.idname = mr.idname)
			INNER JOIN dns.relaydom rd ON (rd.iddom = rd.iddom)
			INNER JOIN dns.host hr ON (rd.idhost = hr.idhost)
			INNER JOIN dns.name nr ON (hr.idname = nr.idname)
			INNER JOIN dns.domain dr ON (nr.iddom = dr.iddom)
		    WHERE n.iddom = $iddom
			AND n.idview = $idview
		ORDER BY name, type, rdata
		) t
	    "
    ::dbdns exec $sql tab {
	set j $tab(j)
    }

    #
    # Done!
    #

    return $j
}

#
# Return zone contents for a IPv4 reverse zone as JSON records
#
# Input:
#   - zone: name of zone to generate
#   - selection: selection criterion (CIDR)
#   - idview: view associated with this zone
# Output:
#   - return value: json records
#
# History:
#   2002/04/26 : pda/jean : design
#   2012/10/24 : pda/jean : add views
#

proc gen-ipv4 {zone selection idview} {
    #
    # Get CIDR prefix length to compute how many bytes we keep in RR name
    #

    if {! [regexp {.*/([0-9]*)} $selection foo prefixlen]} then {
	::scgi::serror 400 [mc {zone '%1$s': invalid selection criterion '%2$s'} $zone $selection]
    }
    
    if {$prefixlen >= 24} then {
	set first 3
    } elseif {$prefixlen >= 16} then {
	set first 2
    } elseif {$prefixlen >= 8} then {
	set first 1
    }

    set records {}
    set sql "SELECT a.addr, h.ttl,
		    to_json (n.name || '.' || d.name || '.') AS rdata
		FROM dns.addr a
		    INNER JOIN dns.host h USING (idhost)
		    INNER JOIN dns.name n USING (idname)
		    INNER JOIN dns.domain d USING (iddom)
		WHERE a.addr <<= '$selection'
		    AND n.idview = $idview
		ORDER BY a.addr
	    "
    ::dbdns exec $sql tab {
	set addr $tab(addr)
	set lname {}
	foreach byte [lrange [split $addr "."] $first 3] {
	    set lname [linsert $lname 0 $byte]
	}
	set name [join $lname "."]
	set ttl   $tab(ttl)
	set rdata $tab(rdata)
	set j "\"name\":\"$name\",\"type\":\"PTR\",\"ttl\":$ttl,\"rdata\":$rdata"
	lappend records "\{$j\}"
    }
    set records [join $records ",\n"]
    set records "\[$records\]"

    return $records
}

#
# Return zone contents for a IPv6 reverse zone as JSON records
#
# Input:
#   - zone: name of zone to generate
#   - selection: selection criterion
#   - idview: view associated with this zone
# Output:
#   - return value: json records
#
# History:
#   2002/04/26 : pda/jean : specification
#   2004/01/14 : pda/jean : design
#   2012/10/24 : pda/jean : add views
#

proc gen-ipv6 {zone selection idview} {
    #
    # Get prefix length to compute how many nibbles we keep in RR name
    #

    if {! [regexp {.*/([0-9]*)} $selection foo prefixlen]} then {
	::scgi::serror 400 [mc {zone '%1$s': invalid selection criterion '%2$s'} $zone $selection]
    }

    if {$prefixlen % 4 != 0} then {
	::scgi::serror 400 [mc {zone '1$s': prefix not multiple of 4 ('%2$s')} $zone $selection]
    }
    
    set nbq [expr 32 - ($prefixlen / 4)]

    set sql "SELECT a.addr, h.ttl,
		    to_json (n.name || '.' || d.name || '.') AS rdata
		FROM dns.addr a
		    INNER JOIN dns.host h USING (idhost)
		    INNER JOIN dns.name n USING (idname)
		    INNER JOIN dns.domain d USING (iddom)
		WHERE a.addr <<= '$selection'
		    AND n.idview = $idview
		ORDER BY a.addr
	    "
    ::dbdns exec $sql tab {
	#
	# Remove particular case where address contains "::" at the beginning
	# or at the end
	#

	regsub {^::} $tab(addr) {0::} addr
	regsub {::$} $addr {::0} addr

	#
	# IPv4 compatible IPv6 addresses (last part = a.b.c.d)
	#

	set l [split $addr ":"]

	set ip4 [split [lindex $l end] "."]
	if {[llength $ip4] == 4} then {
	    set l [lreplace $l end end]

	    set p1 [format "%x" [expr [lindex $ip4 0] * 256 + [lindex $ip4 1]]]
	    lappend l $p1

	    set p2 [format "%x" [expr [lindex $ip4 2] * 256 + [lindex $ip4 3]]]
	    lappend l $p2
	}

	#
	# If there is a "::" in address
	#

	set n [llength $l]
	set len0 [expr 8 - $n]
	set posempty [lsearch $l {}]
	if {$posempty >= 0} then {
	    set l [concat [lrange $l 0 [expr $posempty - 1]] \
			  [lrange {0 0 0 0 0 0 0 0} 0 $len0] \
			  [lrange $l [expr $posempty + 1] end] \
		      ]
	}

	#
	# Each list element should be a nibble. Reverse the list.
	#

	set nl {}
	foreach e $l {
	    foreach q [split [format "%04x" 0x$e] ""] {
		set nl [linsert $nl 0 $q]
	    }
	}

	#
	# Keep only first nbq nibbles
	#

	set name [join [lrange $nl 0 [expr $nbq - 1]] "."]

	#
	# Get out the PTR
	#

	set ttl   $tab(ttl)
	set rdata $tab(rdata)
	set j "\"name\":\"$name\",\"type\":\"PTR\",\"ttl\":$ttl,\"rdata\":$rdata"
	lappend records "\{$j\}"
    }
    set records [join $records ",\n"]
    set records "\[$records\]"

    return $records
}
