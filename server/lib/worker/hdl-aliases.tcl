##############################################################################

api-handler get {/aliases} logged {
	view	0
	name	0
	domain	0
	idhost	0
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
	lappend filter "n.name = $qname"
    }

    if {$domain ne ""} then {
	set qdomain [pg_quote $domain]
	lappend filter "domain.name = $qdomain"
    }

    if {$idhost ne ""} then {
	if {! [regexp {^[0-9]+$} $idhost]} then {
	    ::scgi::serror 400 [mc "Invalid idhost '%s'" $idhost]
	}
	check-idhost ::dbdns $idhost
	lappend filter "a.idhost = $idhost"
    }

    #
    # Append group permissions
    #

    set idgrp [::n idgrp]

    lappend filter "n.idview IN (SELECT idview
				    FROM dns.p_view WHERE idgrp = $idgrp)"
    lappend filter "n.iddom IN (SELECT iddom
				    FROM dns.p_dom WHERE idgrp = $idgrp)"
    lappend filter "addr.addr <<= ANY (
			    SELECT addr FROM dns.p_ip
				WHERE idgrp = $idgrp AND allow_deny = 1 $wip)"
    lappend filter "NOT addr.addr <<= ANY (
			    SELECT addr FROM dns.p_ip
				WHERE idgrp = $idgrp AND allow_deny = 0 $wip)"

    #
    # Create SQL request
    #

    set filter [join $filter " AND "]

    set sql "SELECT COALESCE (json_agg (t), '\[\]') AS j FROM (
		SELECT
			DISTINCT ON (a.idname)
			a.idname AS idalias,
			n.name,
			n.iddom,
			n.idview,
			a.idhost,
			a.ttl
		    FROM dns.alias a
			INNER JOIN dns.name n USING (idname)
			INNER JOIN dns.host h USING (idhost)
			INNER JOIN dns.domain USING (iddom)
			INNER JOIN dns.view USING (idview)
			INNER JOIN dns.addr USING (idhost)
		    WHERE $filter
		) AS t"

    ::dbdns exec $sql tab {
	set j $tab(j)
    }
    ::scgi::set-header Content-Type application/json
    ::scgi::set-body $j
}

##############################################################################

api-handler post {/aliases} logged {
    } {
    lassign [aliases-new-and-mod $_parm [::rr::not-a-rr]] id j
    ::scgi::set-header Content-Type application/json
    ::scgi::set-body $id
}

##############################################################################

api-handler get {/aliases/([0-9]+:idalias)} logged {
    } {
    set rr [check-idalias $idalias]
    set j [alias-get-json $idalias]
    ::scgi::set-header Content-Type application/json
    ::scgi::set-body $j
}

##############################################################################

api-handler put {/aliases/([0-9]+:idalias)} logged {
    } {
    set orr [check-idalias $idalias]
    lassign [aliases-new-and-mod $_parm $orr] id j
    ::scgi::set-header Content-Type application/json
    ::scgi::set-body $j
}

##############################################################################

api-handler delete {/aliases/([0-9]+:idalias)} logged {
    } {
    set rr [check-idalias $idalias]

    #
    # Delete the alias
    #

    set sql "DELETE FROM dns.alias WHERE idname = $idalias"
    ::dbdns exec $sql

    #
    # Add a log
    #

    set fqdn [::rr::get-fqdn $rr]
    set view [::n viewname [::rr::get-idview $rr]]
    set jbefore [::rr::json-alias $rr]
    ::n writelog "delalias" "del alias $fqdn/$view" $jbefore "null"

    ::scgi::set-header Content-Type text/plain
    ::scgi::set-body "OK"
}

##############################################################################
# Utility functions
##############################################################################

proc check-idalias {idalias} {
    set rr [::rr::read-by-idname ::dbdns $idalias]
    if {! [::rr::found $rr] || [::rr::get-cname $rr] == -1} then {
	::scgi::serror 404 [mc "Alias not found"]
    }

    set msg [check-authorized-rr ::dbdns [::n idcor] $rr "del-name"]
    if {$msg ne ""} then {
	::scgi::serror 400 $msg
    }

    return $rr
}

proc alias-get-json {idname} {
    set sql "SELECT row_to_json (t.*) AS j FROM (
		SELECT
		    n.name,
		    n.iddom,
		    n.idview,
		    a.idhost,
		    a.ttl
		FROM dns.alias a
		    NATURAL INNER JOIN dns.name n
		WHERE a.idname = $idname
	    ) AS t
		"
    set found 0
    ::dbdns exec $sql tab {
	set j $tab(j)
	set found 1
    }
    if {! $found} then {
	::scgi::serror 404 [mc "Alias not found"]
    }
    return $j
}

##############################################################################
# Huge function to create or update a specific alias
##############################################################################

#
# Create a new alias, or modify an existing alias
#
# Input:
#   - _parm: JSON for new values
#   - for a new alias: orr is empty
#   - to modify an existing alias: orr contains the existing rr
# Output:
#   - list {new-idalias json-of-new-alias}
#

proc aliases-new-and-mod {_parm orr} {
    set idgrp [::n idgrp]

    #
    # Check input parameters
    #

    if {[::rr::found $orr]} then {
	# update
	set oidname [::rr::get-idname $orr]
	set spec {object {
			    {idhost	{type int req} req}
			    {ttl	{type int opt {null}} req}
			} req
		    }
    } else {
	# creation
	set oidname -1
	set spec {object {
			    {name	{type string req} req}
			    {iddom	{type int opt {number -1}} req}
			    {idview	{type int opt {number -1}} req}
			    {idhost	{type int req} req}
			    {ttl	{type int opt {null}} req}
			} req
		    }
    }

    # get body and check against spec
    set nmj [check-body-json $_parm $spec]

    ::nmjson::import-object $nmj 1

    if {$oidname == -1} then {
	#
	# Check various ids
	#

	if {! [::n isalloweddom $iddom]} then {
	    ::scgi::serror 400 [mc "Invalid domain id '%s'" $iddom]
	}

	if {! [::n isallowedview $idview]} then {
	    ::scgi::serror 400 [mc "Invalid view id '%s'" $idview]
	}

	#
	# Check syntax of new host name
	#

	set msg [check-name-syntax $name]
	if {$msg ne ""} then {
	    ::scgi::serror 400 $msg
	}
	set name [string tolower $name]
    }

    #
    # Check new TTL
    #

    set ottl -1
    if {$oidname != -1} then {
	set ottl [::rr::get-ttlcname $orr]
    }
    set ttl [check-ttl $ttl $ottl]

    #
    # Check if we are authorized to add the new alias
    #

    if {$oidname == -1} then {
	# Check alias name
	set idcor [::n idcor]
	set domain [::n domainname $iddom]
	set msg [check-authorized-host ::dbdns $idcor $name $domain $idview nrr "alias"]
	if {$msg ne ""} then {
	    ::scgi::serror 400 $msg
	}
	set nidname -1
	if {[::rr::found $nrr]} then {
	    set nidname [::rr::get-idname $nrr]
	}
    } else {
	set nidname $oidname
    }

    # Check target host
    set rrh [check-idhost ::dbdns $idhost]
    set nfqdnh [::rr::get-fqdn $rrh]

    if {$oidname == -1} then {
	# check view of host (if alias creation)
	set idviewh [::rr::get-idview $rrh]
	if {$idviewh != $idview} then {
	    set n [::n viewname $idviewh]
	    set h [::rr::get-fqdn $rrh]
	    ::scgi::serror 400 [mc {Inconsistent view '%1$s' for host '%2$s'} $n $h]
	}
    }

    ::dbdns lock {dns.name dns.alias} {
	#
	# Add new name for the alias since it did not pre-exist
	#
	if {$nidname == -1} then {
	    set nidname [::rr::add-name ::dbdns $name $iddom $idview]
	}

	#
	# Create or update alias
	#
	if {$oidname == -1} then {
	    # creation
	    set sql "INSERT INTO dns.alias (idname, idhost, ttl)
			    VALUES ($nidname, $idhost, $ttl)"

	    # Prepare log
	    set dom [::n domainname $iddom]
	    set fqdn "$name.$dom"
	    set view [::n viewname $idview]
	    set jbefore null

	    set logevent "addalias"
	    set logmsg "add alias $fqdn/$view->$nfqdnh"
	} else {
	    # update
	    set sql "UPDATE dns.alias SET
					idhost = $idhost,
					ttl = $ttl
				    WHERE idname = $nidname"

	    # Prepare log
	    set fqdn [::rr::get-fqdn $orr]
	    set view [::n viewname [::rr::get-idview $orr]]
	    set orrh [::rr::read-by-idhost ::dbdns [::rr::get-cname $orr]]
	    set ofqdnh [::rr::get-fqdn $orrh]
	    set jbefore [::rr::json-alias $orr]

	    set logevent "modalias"
	    set logmsg "mod alias $fqdn/$view->$ofqdnh -> $nfqdnh"
	}
	::dbdns exec $sql
    }
    set jafter [alias-get-json $nidname]
    ::n writelog $logevent $logmsg $jbefore $jafter

    #
    # Return both new id (for POST requests) and actual resource (for
    # PUT requests)
    #

    return [list $nidname $jafter]
}

