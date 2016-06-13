##############################################################################

api-handler get {/domains} yes {
    } {
    set idgrp [::u idgrp]
    set sql "SELECT json_agg (t.*) AS j FROM (
		SELECT d.*
		    FROM dns.domain d
			INNER JOIN dns.p_dom p USING (iddom)
		    WHERE p.idgrp = $idgrp
		    ORDER BY p.sort ASC
		) AS t
		"
    set j {[]}
    ::dbdns exec $sql tab {
	set j $tab(j)
    }
    ::scgi::set-header Content-Type application/json
    ::scgi::set-body $j
}

##############################################################################

api-handler get {/domains/([0-9]+:iddom)} yes {
    } {
    set idgrp [::u idgrp]
    set sql "SELECT json_agg (t.*) AS j FROM (
		SELECT d.*
		    FROM dns.domain d
			INNER JOIN dns.p_dom p USING (iddom)
		    WHERE p.idgrp = $idgrp
			AND d.iddom = $iddom
		) AS t
		"
    set found 0
    ::dbdns exec $sql tab {
	set found 1
	set j $tab(j)
    }

    if {! $found} then {
	::scgi::serror 404 [mc "Domain %s not found"]
    }

    ::scgi::set-header Content-Type application/json
    ::scgi::set-body $j
}
