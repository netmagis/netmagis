##############################################################################

api-handler get {/relaydoms} admin {
	view	0
	domain	0
	idhost	0
	minrelay 0
    } {
    #
    # Prepare filter clauses
    #

    set filter {}

    if {$view ne ""} then {
	set qview [pg_quote $view]
	lappend filter "x.vname = $qview"
    }

    if {$domain ne ""} then {
	set qdomain [pg_quote $domain]
	lappend filter "x.dname = $qdomain"
    }

    if {$idhost ne ""} then {
	if {! [regexp {^[0-9]+$} $idhost]} then {
	    ::scgi::serror 400 [mc "Invalid idhost '%s'" $idhost]
	}
	check-idhost ::dbdns $idhost
	lappend filter "rd.idhost = $idhost"
    }

    if {$minrelay ne ""} then {
	if {! [regexp {^[0-9]+$} $minrelay]} then {
	    ::scgi::serror 400 [mc "Invalid minrelay '%s'" $minrelay]
	}
    } else {
	set minrelay 0
    }

    #
    # Create SQL request
    #

    set where ""
    if {[llength $filter] > 0} then {
	append where "WHERE "
	append where [join $filter " AND "]
    }

    set sql "
	WITH dv AS (SELECT x.iddom, x.dname, x.idview, x.vname
				FROM (
					SELECT d.iddom, d.name AS dname,
					       v.idview, v.name AS vname
					    FROM dns.domain d, dns.view v
				    ) AS x
				    NATURAL LEFT JOIN dns.relaydom rd
				$where
				GROUP BY x.iddom, x.idview, x.dname, x.vname
				HAVING COUNT (rd.idhost) >= $minrelay
		    )
	    SELECT COALESCE (json_agg (t), '\[\]') AS j FROM (
		    SELECT dv.iddom, dv.idview,
			    -- FUTURE USE dv.dname, dv.vname,
			    sreq_mxhosts.relays
			FROM dv
			     , LATERAL (
				SELECT array_agg (json_build_object (
						'idhost', r.idhost,
						'prio', r.prio,
						'ttl', r.ttl
						)
					    ORDER BY r.prio ASC
					    ) AS relays
				    FROM dns.relaydom r
				    WHERE r.iddom = dv.iddom
					AND r.idview = dv.idview
				) AS sreq_mxhosts
		    ORDER BY dv.dname ASC
		) AS t
		"

    ::dbdns exec $sql tab {
	set j $tab(j)
    }
    ::scgi::set-header Content-Type application/json
    ::scgi::set-body $j
}

##############################################################################

api-handler get {/relaydoms/([0-9]+:idview)/([0-9]+:iddom)} admin {
    } {
    if {[::n viewname $idview] eq "" || [::n domainname $iddom] eq ""} then {
	::scgi::serror 404 [mc "Relaydom not found"]
    }

    set j [relaydom-get-json $idview $iddom]
    ::scgi::set-header Content-Type application/json
    ::scgi::set-body $j
}

##############################################################################

api-handler put {/relaydoms/([0-9]+:idview)/([0-9]+:iddom)} admin {
    } {
    set view [::n viewname $idview]
    set domain [::n domainname $iddom]
    if {$view eq "" || $domain eq ""} then {
	::scgi::serror 404 [mc "Relaydom not found"]
    }

    #
    # Check input parameters
    #

    # get body just to check it's a JSON body
    ::scgi::get-body-json $_parm

    set dbody [dict get $_parm "_bodydict"]

    set spec {array {object {
			    {prio	{type int req} req}
			    {ttl	{type int opt {}} req}
			    {idhost	{type int req} req}
			} req
		    }
		    opt {}
		}
    set mxhosts [::scgi::check-json-value $dbody $spec]

    #
    # Get the old relaydoms under a format suitable to check-mx-list
    #

    set sql "SELECT prio, idhost, ttl
		    FROM dns.relaydom
		    WHERE idview = $idview AND iddom = $iddom"
    set omx {}
    ::dbdns exec $sql tab {
	lappend omx [list $tab(prio) $tab(idhost) $tab(ttl)]
    }

    #
    # Check the diffs between old and new values
    #

    set mxlist [check-mx-list $idview $mxhosts $omx]

    #
    # Store the modifications detected in mxlist
    # 

    ::dbdns lock {dns.relaydom} {
	set log {}
	lassign $mxlist ldel lmod lnew

	set lsql {}
	foreach mx $lmod {
	    lassign $mx prio ttl idhost rr
	    lappend lsql "UPDATE dns.relaydom
				SET prio = $prio, ttl = $ttl
				WHERE iddom = $iddom AND idhost = $idhost"
	    lappend log "![::rr::get-fqdn $rr](pri=$prio,ttl=$ttl)"
	}

	foreach mx $lnew {
	    lassign $mx prio ttl idhost rr
	    lappend lsql "INSERT INTO dns.relaydom
					(iddom, idview, idhost, prio, ttl)
				VALUES ($iddom, $idview, $idhost, $prio, $ttl)"
	    lappend log "+[::rr::get-fqdn $rr](pri=$prio,ttl=$ttl)"
	}

	foreach mx $ldel {
	    lassign $mx prio ttl idhost rr
	    lappend lsql "DELETE FROM dns.relaydom
				WHERE iddom = $iddom
				    AND idview = $idview
				    AND idhost = $idhost"
	    lappend log "-[::rr::get-fqdn $rr](pri=$prio,ttl=$ttl)"
	}

	set sql [join $lsql ";"]
	::dbdns exec $sql

	set logevent "modrelaydom"
	set log [join $log ", "]
	set logmsg "mod relaydom $domain/$view $log"
	set jbefore [json-mxlist $idview $iddom $omx]
	set jafter [relaydom-get-json $idview $iddom]
	::n writelog $logevent $logmsg $jbefore $jafter
    }

    ::scgi::set-header Content-Type application/json
    ::scgi::set-body $jafter
}


##############################################################################
# Utility functions
##############################################################################

proc json-mxlist {idview iddom lmx} {
    set jmx {}
    foreach m $lmx {
	lassign $m prio idhost ttl
	lappend jmx [::json::write object \
					prio $prio \
					ttl $ttl \
					idhost $idhost \
				    ]
    }
    set jmx [join $jmx ","]
    set jmx "\[$jmx\]"
    set j [::json::write object iddom $iddom idview $idview relays $jmx]
    return $j
}

proc relaydom-get-json {idview iddom} {
    set sql "SELECT row_to_json (t.*) AS j FROM (
		SELECT d.iddom, v.idview,
			sreq_mxhosts.relays
		    FROM dns.domain d, dns.view v
			 , LATERAL (
			    SELECT array_agg (json_build_object (
					    'idhost', r.idhost,
					    'prio', r.prio,
					    'ttl', r.ttl
					    )
					ORDER BY r.prio ASC
					) AS relays
				FROM dns.relaydom r
				WHERE r.iddom = d.iddom AND r.idview = v.idview
			    ) AS sreq_mxhosts
		    WHERE d.iddom = $iddom AND v.idview = $idview
		) AS t
		"

    # if the test on domainname/viewname was successful, we cannot return null
    set j "null"
    ::dbdns exec $sql tab {
	set j $tab(j)
    }
    return $j
}
