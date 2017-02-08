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

    set otable1 "NATURAL LEFT JOIN dns.relaydom r"
    set otable2 "NATURAL LEFT JOIN dns.host h
		    LEFT JOIN dns.name n ON (n.idname = h.idname)
		    LEFT JOIN dns.view v ON (n.idview = v.idview)
		"
    set filter {}

    set needotable1 false
    set needotable2 false

    if {$view ne ""} then {
	set qview [pg_quote $view]
	set needotable1 true
	set needotable2 true
	lappend filter "v.name = $qview"
    }

    if {$domain ne ""} then {
	set qdomain [pg_quote $domain]
	lappend filter "d.name = $qdomain"
    }

    if {$idhost ne ""} then {
	if {! [regexp {^[0-9]+$} $idhost]} then {
	    ::scgi::serror 400 [mc "Invalid idhost '%s'" $idhost]
	}
	check-idhost ::dbdns $idhost
	set needotable1 true
	lappend filter "r.idhost = $idhost"
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

    set where1 ""
    if {[llength $filter] > 0} then {
	set where1 "WHERE "
	append where1 [join $filter " AND "]
    }

    set otable ""
    if {$needotable1} then {
	append otable $otable1
    }
    if {$needotable2} then {
	append otable " "
	append otable $otable2
    }

    set sql "
	WITH
	    r1 AS (SELECT DISTINCT d.iddom
				FROM dns.domain d
				    $otable
				$where1
		    )
	    ,
	    r2 AS (SELECT iddom
				FROM dns.domain d
				    NATURAL LEFT JOIN dns.relaydom r
				GROUP BY iddom
				HAVING COUNT (idhost) >= $minrelay
		    )
	    SELECT COALESCE (json_agg (t), '\[\]') AS j FROM (
		    SELECT r1.iddom,
			    sreq_mxhosts.relays
			FROM r1
			     NATURAL INNER JOIN r2
			     , LATERAL (
				SELECT array_agg (json_build_object (
					    'idhost', r.idhost,
					    'prio', r.prio,
					    'ttl', r.ttl
					    )
					) AS relays
				    FROM dns.relaydom r
				    WHERE r.iddom = r1.iddom
				) AS sreq_mxhosts
		    ORDER BY r1.iddom
		) AS t
		"

    ::dbdns exec $sql tab {
	set j $tab(j)
    }
    ::scgi::set-header Content-Type application/json
    ::scgi::set-body $j
}

##############################################################################

api-handler post {/mx} logged {
    } {
    lassign [mx-new-and-mod $_parm [::rr::not-a-rr]] id j
    ::scgi::set-header Content-Type text/plain
    ::scgi::set-body $id
}

##############################################################################

api-handler get {/mx/([0-9]+:idmx)} logged {
    } {
    set rr [check-idmx $idmx]
    set j [mx-get-json $idmx]
    ::scgi::set-header Content-Type application/json
    ::scgi::set-body $j
}

##############################################################################

api-handler put {/mx/([0-9]+:idmx)} logged {
    } {
    set orr [check-idmx $idmx]
    lassign [mx-new-and-mod $_parm $orr] id j
    ::scgi::set-header Content-Type application/json
    ::scgi::set-body $j
}

##############################################################################

api-handler delete {/mx/([0-9]+:idmx)} logged {
    } {
    set rr [check-idmx $idmx]

    #
    # Delete the mx
    #

    set sql "DELETE FROM dns.mx WHERE idname = $idmx"
    ::dbdns exec $sql

    #
    # Add a log
    #

    set fqdn [::rr::get-fqdn $rr]
    set view [::n viewname [::rr::get-idview $rr]]
    set lmx {}
    foreach h [::rr::get-mxhosts $rr] {
	lassign $h prio idhost ttl
	set hrr [::rr::read-by-idhost ::dbdns $idhost]
	lappend lmx [::rr::get-fqdn $hrr]
    }
    set lmx [join $lmx ", "]
    set jbefore [::rr::json-mx $rr]
    ::n writelog "delmx" "del mx $fqdn/$view ($lmx)" $jbefore "null"

    ::scgi::set-header Content-Type text/plain
    ::scgi::set-body "OK"
}

##############################################################################
# Utility functions
##############################################################################

proc check-idmx {idmx} {
    set rr [::rr::read-by-idname ::dbdns $idmx]
    if {! [::rr::found $rr] || [llength [::rr::get-mxhosts $rr]] == 0} then {
	::scgi::serror 404 [mc "MX not found"]
    }

    set msg [check-authorized-rr ::dbdns [::n idcor] $rr "del-mx"]
    if {$msg ne ""} then {
	::scgi::serror 400 $msg
    }

    return $rr
}

proc mx-get-json {idname} {
    set sql "SELECT row_to_json (t.*) AS j FROM (
		SELECT
		    n.name,
		    n.iddom,
		    n.idview,
		    array_agg (json_build_object (
					'idhost', m.idhost,
					'prio', m.prio,
					'ttl', m.ttl
					)
				) AS mxhosts
		FROM dns.mx m
		    NATURAL INNER JOIN dns.name n
		WHERE m.idname = $idname
		GROUP BY n.name, n.iddom, n.idview
	    ) AS t
		"
    set found 0
    ::dbdns exec $sql tab {
	set j $tab(j)
	set found 1
    }
    if {! $found} then {
	::scgi::serror 404 [mc "MX not found"]
    }
    return $j
}

##############################################################################
# Huge function to create or update a specific mx
##############################################################################

#
# Create a new mx, or modify an existing mx
#
# Input:
#   - _parm: JSON for new values
#   - for a new mx: orr is empty
#   - to modify an existing mx: orr contains the existing rr
# Output:
#   - list {new-idmx json-of-new-mx}
#

proc mx-new-and-mod {_parm orr} {
    set idgrp [::n idgrp]

    #
    # Check input parameters
    #

    # get body just to check it's a JSON body
    ::scgi::get-body-json $_parm

    set dbody [dict get $_parm "_bodydict"]

    if {[::rr::found $orr]} then {
	# update
	set oidname [::rr::get-idname $orr]
	set spec {array {object {
				{prio	{type int req} req}
				{ttl	{type int opt {}} req}
				{idhost	{type int req} req}
			    } req
			} req
		    }
	set body [::scgi::check-json-value $dbody $spec]
	set mxlist [check-mx-list $body [::rr::get-mxhosts $orr]]
	set nidname $oidname
    } else {
	# creation
	set oidname -1
	set spec {object {
			    {name	{type string req} req}
			    {iddom	{type int opt -1} req}
			    {idview	{type int opt -1} req}
			    {mxhosts	{array {object {
						{prio	{type int req} req}
						{ttl	{type int opt {}} req}
						{idhost	{type int req} req}
						} req
					    } req
					}
			    }
			} req
		    }
	set body [::scgi::check-json-value $dbody $spec]
	::scgi::import-json-object $body

	# Check various ids
	if {! [::n isalloweddom $iddom]} then {
	    ::scgi::serror 400 [mc "Invalid domain id '%s'" $iddom]
	}
	if {! [::n isallowedview $idview]} then {
	    ::scgi::serror 400 [mc "Invalid view id '%s'" $idview]
	}

	# Check syntax of new host name
	set msg [check-name-syntax $name]
	if {$msg ne ""} then {
	    ::scgi::serror 400 $msg
	}
	set name [string tolower $name]

	# Check MX host list
	set mxlist [check-mx-list $mxhosts {}]

	# Check new mx name
	set idcor [::n idcor]
	set domain [::n domainname $iddom]
	set msg [check-authorized-host ::dbdns $idcor $name $domain $idview nrr "add-mx"]
	if {$msg ne ""} then {
	    ::scgi::serror 400 $msg
	}
	set nidname -1
	if {[::rr::found $nrr]} then {
	    set nidname [::rr::get-idname $nrr]
	}

    }

    ::dbdns lock {dns.name dns.mx} {
	#
	# Add new name for the mx since it did not pre-exist
	# or delete old MX
	#
	set lsql {}
	if {$nidname == -1} then {
	    set nidname [::rr::add-name ::dbdns $name $iddom $idview]
	}

	set log {}
	lassign $mxlist ldel lmod lnew

	foreach mx $lmod {
	    lassign $mx prio ttl idhost rr
	    lappend lsql "UPDATE dns.mx
				SET prio = $prio, ttl = $ttl
				WHERE idname = $nidname AND idhost = $idhost"
	    lappend log "![::rr::get-fqdn $rr](pri=$prio,ttl=$ttl)"
	}

	foreach mx $lnew {
	    lassign $mx prio ttl idhost rr
	    lappend lsql "INSERT INTO dns.mx (idname, idhost, prio, ttl)
				    VALUES ($nidname, $idhost, $prio, $ttl)"
	    lappend log "+[::rr::get-fqdn $rr](pri=$prio,ttl=$ttl)"
	}

	foreach mx $ldel {
	    lassign $mx prio ttl idhost rr
	    lappend lsql "DELETE FROM dns.mx
				WHERE idname = $nidname AND idhost = $idhost"
	    lappend log "-[::rr::get-fqdn $rr](pri=$prio,ttl=$ttl)"
	}

	set log [join $log ", "]

	# distinguish log
	if {$oidname == -1} then {
	    set dom [::n domainname $iddom]
	    set fqdn "$name.$dom"
	    set view [::n viewname $idview]
	    set jbefore null

	    set logevent "addmx"
	    set logmsg "add mx $fqdn/$view $log"
	} else {
	    set fqdn [::rr::get-fqdn $orr]
	    set view [::n viewname [::rr::get-idview $orr]]
	    set jbefore [::rr::json-mx $orr]

	    set logevent "modmx"
	    set logmsg "mod mx $fqdn/$view $log"
	}

	set sql [join $lsql ";"]
	::dbdns exec $sql
    }
    set jafter [mx-get-json $nidname]
    ::n writelog $logevent $logmsg $jbefore $jafter

    #
    # Return both new id (for POST requests) and actual resource (for
    # PUT requests)
    #

    return [list $nidname $jafter]
}

#
# Check needed operations on the MX list
# jdict: new MX list, array of dict, returned by scgi::check-json-value
#				{prio	{type int req} req}
#				{ttl	{type int opt {}} req}
#				{idhost	{type int req} req}
# omx: old RR, including old MX list
# returns list {ldel lmod lnew}
#	where each ldel, lmod, lnew is a list:
#		{{prio ttl idhost rr} ...}

proc check-mx-list {jdict omx} {
    # process old MX list
    foreach m $omx {
	lassign $m oprio oidhost ottl
	set orr [check-idhost ::dbdns $oidhost]
	set old($oidhost) [list $oprio $ottl $orr]
    }

    set lmod {}
    set lnew {}

    # process new MX list
    foreach e $jdict {
	::scgi::import-json-object $e

	if {[info exists alreadyseen($idhost)]} then {
	    ::scgi::serror 400 [mc {Duplicate MX host %d} $idhost]
	}
	set alreadyseen($idhost) 1

	set msg [check-prio $prio]
	if {$msg ne ""} then {
	    ::scgi::serror 400 $msg
	}

	set ottl -1
	if {[info exists old($idhost)]} then {
	    set ottl [lindex $old($idhost) 1]
	}
	set ttl [check-ttl $ttl $ottl]

	if {[info exists old($idhost)]} then {
	    lassign $old($idhost) oprio ottl orr
	    if {$oprio != $prio || $ottl != $ttl} then {
		lappend lmod [list $prio $ttl $idhost $orr]
	    }
	    unset old($idhost)
	} else {
	    set rr [check-idhost ::dbdns $idhost]
	    lappend lnew [list $prio $ttl $idhost $rr]
	}
    }

    if {[llength [array names alreadyseen]] == 0} then {
	::scgi::serror 400 [mc {Empty MX host list}]
    }

    set ldel {}
    foreach oidhost [array names old] {
	lassign $old($oidhost) oprio ottl orr
	lappend ldel [list $oprio $ottl $oidhost $orr]
    }

    return [list $ldel $lmod $lnew]
}
