api-handler get {/names} yes {
	view	0
	name	0
	domain	0
	test	0
	cidr	0
    } {
    if {$test ne ""} then {
	if {$view eq "" || $name eq "" || $domain eq ""} then {
	    scgiapp::scgi-error 400 [mc "'test' needs view/name/domain parameters"]
	}
	set idview [::u viewid $view]
	if {$idview eq ""} then {
	    scgiapp::scgi-error 404 [mc "View '%s' not found" $view]
	}
	set msg [check-authorized-host ::dbdns [::u idcor] \
				    $name $domain $idview trr $test]
	if {$msg eq ""} then {
	    set j {[]}
	    set idrr $trr(idrr)
	    if {$idrr ne ""} then {
		set sql "SELECT json_build_array (row_to_json (r)) AS j
				FROM dns.full_rr r
				WHERE idrr = $idrr"
		::dbdns exec $sql tab {
		    set j $tab(j)
		}
	    }
	    scgiapp::set-body $j
	    scgiapp::set-header Content-Type application/json
	} else {
	    scgiapp::scgi-error 403 [mc "Forbidden (%s)" $msg]
	}
    } else {
	scgiapp::set-body [sub-names $view $name $domain $cidr]
	scgiapp::set-header Content-Type application/json
    }
}

api-handler get {/names/([0-9]+:idrr)} yes {
	fields	0
    } {

    puts stderr "BINGO !"
    puts "idrr=$idrr"
    puts "fields=$fields"

    if {! [read-rr-by-id $dbfd(dns) $idrr trr]} then {
	puts "NOT FOUND"
    } else {
	puts [array get trr]
    }
}


proc sub-names {view name domain cidr} {
    set idgrp [::u idgrp]
    
    set lwhere {}

    #
    # Filter on name
    #

    if {$name ne ""} then {
	set qname [pg_quote $name]
	lappend lwhere "upper (rr.name) = upper ($qname)"
    }

    #
    # Filter on view
    #

    if {$view ne ""} then {
	set qview [pg_quote $view]
	lappend lwhere "rr.idview IN (
				SELECT idview FROM dns.p_view
					    NATURAL INNER JOIN dns.view
				    WHERE idgrp = $idgrp
					AND name = $qview
				    )"
    } else {
	lappend lwhere "rr.idview IN (
				SELECT idview FROM dns.p_view
				    WHERE idgrp = $idgrp
				    )"
    }

    #
    # Filter on domain
    #

    if {$domain ne ""} then {
	set qdomain [pg_quote $domain]
	lappend lwhere "rr.iddom IN (
				SELECT iddom FROM dns.p_dom
					    NATURAL INNER JOIN dns.domain
				    WHERE idgrp = $idgrp
					AND upper (name) = upper ($qdomain)
				    )"
    } else {
	lappend lwhere "rr.iddom IN (
				SELECT iddom FROM dns.p_dom
				    WHERE idgrp = $idgrp
				    )"
    }

    #
    # Filter on CIDR
    #

    if {$cidr ne ""} then {
	set qcidr [pg_quote $cidr]
	lappend lwhere "rr_ip.addr <<= $qcidr"
	lappend lwhere "rr_ip.addr <<= ANY (
				SELECT addr FROM dns.p_ip
				    WHERE idgrp = $idgrp AND allow_deny = 1
					AND (addr <<= $qcidr OR addr >>= $qcidr)
				    )"
	lappend lwhere "NOT rr_ip.addr <<= ANY (
				SELECT addr FROM dns.p_ip
				    WHERE idgrp = $idgrp AND allow_deny = 0
					AND (addr <<= $qcidr OR addr >>= $qcidr)
				    )"
    } else {
	lappend lwhere "rr_ip.addr <<= ANY (
				SELECT addr FROM dns.p_ip
				    WHERE idgrp = $idgrp AND allow_deny = 1
				    )"
	lappend lwhere "NOT rr_ip.addr <<= ANY (
				SELECT addr FROM dns.p_ip
				    WHERE idgrp = $idgrp AND allow_deny = 0
				    )"
    }

    set where [join $lwhere " AND "]

    set sql "SELECT json_agg (r.*) AS j
		    FROM dns.full_rr r
		    WHERE idrr IN (
			SELECT DISTINCT idrr
			    FROM dns.rr
				INNER JOIN dns.rr_ip USING (idrr)
				WHERE $where
		    )
		    "
    ### puts "sql=$sql"
    set j ""
    ::dbdns exec $sql tab {
	set j $tab(j)
    }

    return $j
}
