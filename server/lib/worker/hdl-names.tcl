#array set names_sortcrit {
#    name	name
#    domain	domain
#    addr	rr_ip.addr
#    view	view
#}

api-handler get {/names} yes {
	view	0
	name	0
	domain	0
	addr	0
    } {
    #
    # Prepare filter clauses
    #

    set filter {}
    set wip ""

    if {$view ne ""} then {
	set qview [pg_quote $view]
	lappend filter "view.name = $qview"
    }

    if {$name ne ""} then {
	set qname [pg_quote $name]
	lappend filter "r.name = $qname"
    }

    if {$domain ne ""} then {
	set qdomain [pg_quote $domain]
	lappend filter "domain.name = $qdomain"
    }

    if {$addr ne ""} then {
	set qaddr [pg_quote $addr]
	lappend filter "rr_ip.addr <<= $qaddr"
	set wip "AND (addr <<= $qaddr OR addr >>= $qaddr)"
    }

    #
    # Append group permissions
    #

    set idgrp [::u idgrp]

    lappend filter "r.idview IN (SELECT idview
				    FROM dns.p_view WHERE idgrp = $idgrp)"
    lappend filter "r.iddom IN (SELECT iddom
				    FROM dns.p_dom WHERE idgrp = $idgrp)"
    lappend filter "rr_ip.addr <<= ANY (
			    SELECT addr FROM dns.p_ip
				WHERE idgrp = $idgrp AND allow_deny = 1 $wip)"
    lappend filter "NOT rr_ip.addr <<= ANY (
			    SELECT addr FROM dns.p_ip
				WHERE idgrp = $idgrp AND allow_deny = 0 $wip)"

    #
    # Order clause
    #

#    global names_sortcrit
#
#    set order {}
#    foreach c [split $sort ","] {
#	if {! [info exists names_sortcrit($c)]} then {
#	    ::scgi::serror 412 [mc "Invalid sort criterion '%s'" $c]
#	}
#	lappend order $names_sortcrit($c)
#    }
#    if {[llength $order] == 0} then {
#	set order ""
#    } else {
#	set order [join $order ", "]
#	set order "ORDER BY $order"
#    }

    #
    # Create SQL request
    #

    set filter [join $filter " AND "]

    set sql "SELECT COALESCE (json_agg (t), '\[\]') AS j FROM (
		SELECT
			DISTINCT ON (r.idrr)
			r.idrr,
			r.name,
			r.iddom,
			domain.name AS domain,
			r.idview,
			view.name AS view
		    FROM dns.rr r
			INNER JOIN dns.rr_ip USING (idrr)
			INNER JOIN dns.domain USING (iddom)
			INNER JOIN dns.view USING (idview)
		    WHERE $filter
		) AS t"

    ::dbdns exec $sql tab {
	set j $tab(j)
    }
    ::scgi::set-header Content-Type application/json
    ::scgi::set-body $j
}

api-handler get {/names/([0-9]+:idrr)} yes {
	fields	0
    } {

    if {! [read-rr-by-id $dbfd(dns) $idrr trr]} then {
	puts "NOT FOUND"
    } else {
	puts [array get trr]
    }
}
