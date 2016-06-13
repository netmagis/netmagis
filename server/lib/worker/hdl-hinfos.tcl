##############################################################################

api-handler get {/hinfos} yes {
    } {
    set sql "SELECT json_agg (t.*) AS j FROM (
		SELECT idhinfo, name
		    FROM dns.hinfo
		    WHERE present != 0
		    ORDER BY sort ASC
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

api-handler get {/hinfos/([0-9]+:idhinfo)} yes {
    } {
    set idgrp [::u idgrp]
    set sql "SELECT json_agg (t.*) AS j FROM (
		SELECT idhinfo
		    FROM dns.hinfo
		    WHERE present != 0
			AND idhinfo = $idhinfo
		) AS t
		"
    set found 0
    ::dbdns exec $sql tab {
	set found 1
	set j $tab(j)
    }

    if {! $found} then {
	::scgi::serror 404 [mc "Hinfo %s not found"]
    }

    ::scgi::set-header Content-Type application/json
    ::scgi::set-body $j
}
