##############################################################################

api-handler get {/search} yes {
	q 1
    } {
    set idgrp [::u idgrp]

    set ipversion [::ip::version $q]

    if {$q eq "_"} then {
    } elseif {$ipversion > 0} then {
	set cidr [expr {[::ip::mask $q] ne ""}]
    } else {
	set qq1 [pg_quote "$q%"]
	set qq2 [pg_quote "%$q%"]
	set sql "SELECT COALESCE (json_agg (t), '\[\]') AS j FROM (
		    SELECT r.name AS result,
			    'rr' AS type,
			    global.mklink ('/names/', r.idrr) AS link
			FROM dns.rr r
			WHERE r.name LIKE $qq1
		    UNION 
		    SELECT r.name AS result,
			    'network' AS type,
			    global.mklink ('/networks/', r.idnet) AS link
			FROM dns.network r
			    INNER JOIN dns.p_network p USING (idnet)
			WHERE p.idgrp = $idgrp
			    AND (r.name LIKE $qq2
				    OR r.location LIKE $qq2
				    OR r.comment LIKE $qq2
				    )
		    UNION
		    SELECT r.name AS result,
			    'domain' AS type,
			    global.mklink ('/domains/', r.iddom) AS link
			FROM dns.domain r
			    INNER JOIN dns.p_domain p USING (iddom)
			WHERE p.idgrp = $idgrp
			    AND r.name LIKE $qq2
		    UNION
		    SELECT r.name AS result,
			    'dhcpprofile' AS type,
			    global.mklink ('/dhcpprofiles/', r.iddhcpprof)
				    AS link
			FROM dns.dhcpprofile r
			    INNER JOIN dns.p_dhcpprofile p USING (iddhcpprof)
			WHERE p.idgrp = $idgrp
			    AND (r.name LIKE $qq2
				    OR r.text LIKE $qq2
				    )
			ORDER BY p.sort ASC
		    ) AS t
		    "
    }

    ::dbdns exec $sql tab {
	set j $tab(j)
    }

    ::scgi::set-header Content-Type application/json
    ::scgi::set-body $j
}
