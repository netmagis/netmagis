api-handler get {/networks} yes {
    } {
    set idgrp [::u idgrp]
    set sql "SELECT array_to_json (array_agg (row_to_json (t))) AS res
		    FROM (
			SELECT n.name,
				global.mklink ('/networks/', n.idnet) AS link,
				n.location,
				COALESCE (CAST (n.addr4 AS text), '') AS addr4,
				COALESCE (CAST (n.addr6 AS text), '') AS addr6,
				o.name AS organization,
				c.name AS community,
				n.comment,
				n.dhcp,
				n.gw4,
				n.gw6
			    FROM dns.network n
				INNER JOIN dns.community c USING (idcomm)
				INNER JOIN dns.organization o USING (idorg)
				INNER JOIN dns.p_network p USING (idnet)
			    WHERE p.idgrp = $idgrp
			    ORDER BY p.sort ASC, n.name ASC
		    ) t
		"
    # puts "request=$sql"
    set r ""
    ::dbdns exec $sql tab {
	set r $tab(res)
	# puts "r=$r"
    }
    ::scgiapp::set-header Content-Type application/json
    ::scgiapp::set-body $r
}

api-handler get {/networks/([0-9]+:idnet)} yes {
    } {
    set idgrp [::u idgrp]
    set sql "SELECT row_to_json (t) AS res
		    FROM (
			SELECT n.name,
				n.location,
				COALESCE (CAST (n.addr4 AS text), '') AS addr4,
				COALESCE (CAST (n.addr6 AS text), '') AS addr6,
				o.name AS organization,
				c.name AS community,
				n.comment,
				n.dhcp,
				n.gw4,
				n.gw6
			    FROM dns.network n
				INNER JOIN dns.community c USING (idcomm)
				INNER JOIN dns.organization o USING (idorg)
				INNER JOIN dns.p_network p USING (idnet)
			    WHERE p.idgrp = $idgrp
				AND p.idnet = $p::idnet
		    ) t
		"
    set r ""
    ::dbdns exec $sql tab {
	set r $tab(res)
    }
    if {$r eq ""} then {
	::scgiapp::scgi-error 404 "Network '$p::idnet' not found"
    }
    ::scgiapp::set-header Content-Type application/json
    ::scgiapp::set-body $r
}
