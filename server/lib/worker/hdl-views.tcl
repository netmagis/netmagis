api-handler get {/views} logged {
    } {
    set idgrp [::n idgrp]
    set sql "SELECT COALESCE (json_agg (t), '\[\]') AS j FROM (
			SELECT v.idview, v.name, p.selected
			    FROM dns.view v
				INNER JOIN dns.p_view p USING (idview)
			    WHERE p.idgrp = $idgrp
			    ORDER BY p.sort ASC, v.name ASC
		    ) t
		"
    ::dbdns exec $sql tab {
	set j $tab(j)
    }
    ::scgi::set-header Content-Type application/json
    ::scgi::set-body $j
}

api-handler get {/views/([0-9]+:idview)} logged {
    } {
    set idgrp [::n idgrp]
    set sql "SELECT row_to_json (t) AS j
		    FROM (
			SELECT v.idview, v.name, p.selected
			    FROM dns.view v
				INNER JOIN dns.p_view p USING (idview)
			    WHERE p.idgrp = $idgrp
				AND v.idview = $idview
		    ) t
		"
    set j ""
    ::dbdns exec $sql tab {
	set j $tab(j)
    }
    if {$j eq ""} then {
	::scgi::serror 404 [mc "View '%s' not found" $idview]
    }
    ::scgi::set-header Content-Type application/json
    ::scgi::set-body $j
}
