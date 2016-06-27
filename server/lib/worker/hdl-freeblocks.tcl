api-handler get {/freeblocks} yes {
	cidr	1
	size	1
	sort	0
    } {

    if {! [regexp {^[0-9]+$} $size] || $size < 1} then {
	::scgi::serror 412 [mc {Invalid query parameter (%1$s=%2$s)} size $size]
    }
    if {! [::ip::is "ipv4" $cidr]} then {
	::scgi::serror 412 [mc {Invalid query parameter (%1$s=%2$s)} cidr $cidr]
    }

    set idgrp [::u idgrp]
    set qcidr [pg_quote $cidr]

    switch -- $sort {
	size    { set order "ORDER BY n ASC, a ASC" }
	addr    -
	default { set order "ORDER BY a ASC, n ASC" }
    }

    # ok for /16, but not /15
    set max 65537

    # XXX check property of addresses
    set sql "SELECT COALESCE (json_agg (t), '\[\]') AS j FROM (
		SELECT
			a AS addr,
			n AS size
		    FROM dns.ipranges ($qcidr, $max, $idgrp)
		    WHERE n > $size
		    $order
		) AS t"
    ::dbdns exec $sql tab {
	set j $tab(j)
    }
    ::scgi::set-header Content-Type application/json
    ::scgi::set-body $j
}
