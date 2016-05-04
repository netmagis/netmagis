api-handler get {/views} yes {
    } {
    set idgrp [::u idgrp]
    set sql "SELECT array_to_json (array_agg (row_to_json (t))) AS res
		    FROM (
			SELECT v.name, '/views/' || v.idview AS link,
				    p.selected, p.sort
			    FROM dns.view v
			    INNER JOIN dns.p_view p
				ON v.idview = p.idview
			    WHERE p.idgrp = $idgrp
			    ORDER BY p.sort ASC, v.name ASC
		    ) t
		"
    set r ""
    ::dbdns exec $sql tab {
	set r $tab(res)
    }
    ::scgiapp::set-header Content-Type application/json
    ::scgiapp::set-body $r
}

api-handler get {/views/([0-9]+:idview)} yes {
    } {
    set idgrp [::u idgrp]
    set sql "SELECT row_to_json (t) AS res
		    FROM (
			SELECT v.name, p.selected, p.sort
			    FROM dns.view v
			    INNER JOIN dns.p_view p
				ON v.idview = p.idview
			    WHERE p.idgrp = $idgrp
				AND v.idview = $::parm::idview
		    ) t
		"
    set r ""
    ::dbdns exec $sql tab {
	set r $tab(res)
    }
    if {$r eq ""} then {
	::scgiapp::scgi-error 404 "View '$::parm::idview' not found"
    }
    ::scgiapp::set-header Content-Type application/json
    ::scgiapp::set-body $r
}
