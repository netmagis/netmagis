##############################################################################

api-handler get {/search} logged {
	q 1
    } {
    set idgrp [::n idgrp]

    set ipversion [::ip::version $q]

    if {$q eq "_"} then {
    } elseif {$ipversion > 0} then {
	set cidr [expr {[::ip::mask $q] ne ""}]
    } else {
	set qq1 [pg_quote "$q%"]
	set qq2 [pg_quote "%$q%"]
	set sql "SELECT COALESCE (json_agg (t), '\[\]') AS j FROM (
		    SELECT 'alias' AS type,
			    n.name || '.' || d.name AS result,
			    v.name AS view,
			    'aliases/' || idname AS link
			FROM dns.name n
			    INNER JOIN dns.view v USING (idview)
			    INNER JOIN dns.domain d USING (iddom)
			    INNER JOIN dns.alias USING (idname)
			WHERE n.name ILIKE $qq2
		    UNION
		    SELECT 'host' AS type,
			    n.name || '.' || d.name AS result,
			    v.name AS view,
			    'hosts/' || idname AS link
			FROM dns.name n
			    INNER JOIN dns.view v USING (idview)
			    INNER JOIN dns.domain d USING (iddom)
			    INNER JOIN dns.host USING (idname)
			WHERE n.name ILIKE $qq2
		    UNION
		    SELECT 'network' AS type,
			    w.name AS result,
			    NULL as view,
			    'networks/' || idnet AS link
			FROM dns.network w
			    INNER JOIN dns.p_network p USING (idnet)
			WHERE p.idgrp = $idgrp
			    AND (w.name ILIKE $qq2
				    OR w.location LIKE $qq2
				    OR w.comment LIKE $qq2
				    )
		    UNION
		    SELECT 'domain' AS type,
			    d.name AS result,
			    NULL as view,
			    'domains/' || d.iddom AS link
			FROM dns.domain d
			    INNER JOIN dns.p_dom p USING (iddom)
			WHERE p.idgrp = $idgrp
			    AND d.name ILIKE $qq2
		    UNION
		    SELECT 'dhcpprofile' AS type,
		    	    d.name AS result,
			    NULL as view,
			    'dhcpprofiles/' || d.iddhcpprof AS link
			FROM dns.dhcpprofile d
			    INNER JOIN dns.p_dhcpprofile p USING (iddhcpprof)
			WHERE p.idgrp = $idgrp
			    AND (d.name LIKE $qq2
				    OR d.text LIKE $qq2
				    )
		    ) AS t
		    "
    }

    ::dbdns exec $sql tab {
	set j $tab(j)
    }

    ::scgi::set-header Content-Type application/json
    ::scgi::set-body $j
}
