api-handler get {/views} yes {
    } {
    set idgrp [::u idgrp]
    set sql "SELECT json_agg (t.*) AS j FROM (
			SELECT v.name,
				global.mklink ('/views/', v.idview) AS link,
				p.selected, p.sort
			    FROM dns.view v
			    INNER JOIN dns.p_view p
				ON v.idview = p.idview
			    WHERE p.idgrp = $idgrp
			    ORDER BY p.sort ASC, v.name ASC
		    ) t
		"
    ::dbdns exec $sql tab {
	set j $tab(j)
    }
    if {$j eq ""} then {
	set j {[]}
    }
    ::scgi::set-header Content-Type application/json
    ::scgi::set-body $j
}

api-handler get {/views/([0-9]+:idview)} yes {
    } {
    set idgrp [::u idgrp]
    set sql "SELECT row_to_json (t) AS j
		    FROM (
			SELECT v.name, p.selected, p.sort
			    FROM dns.view v
			    INNER JOIN dns.p_view p
				ON v.idview = p.idview
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
