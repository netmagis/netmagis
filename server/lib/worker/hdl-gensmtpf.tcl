api-handler get {/gen/smtpf} genz {
    } {

    #
    # Extract views which have at least one smtp-enabled host
    #

    set sql "SELECT COALESCE (json_agg (t), '\[\]') AS j FROM (
			SELECT DISTINCT v.name
			    FROM dns.host h
				INNER JOIN dns.name n USING (idname)
				INNER JOIN dns.view v USING (idview)
			    WHERE h.sendsmtp > 0
			    ORDER BY v.name
		    ) t
		"
    ::dbdns exec $sql tab {
	set j $tab(j)
    }

    ::scgi::set-header Content-Type application/json
    ::scgi::set-body $j
}

# name: view name
api-handler get {/gen/smtpf/([^/]+:name)} genz {
    } {

    set idview [::n viewid $name]
    if {$idview == -1} then {
	::scgi::serror 404 [mc "View '%s' not found" $name]
    }

    #
    # Get smtp-enabled host addresses
    #

    set sql "SELECT COALESCE (json_agg (t), '\[\]') AS j FROM (
		    SELECT a.addr
			FROM dns.host h
			    INNER JOIN dns.name n USING (idname)
			    INNER JOIN dns.addr a USING (idhost)
			    INNER JOIN dns.view v USING (idview)
			WHERE n.idview = $idview
			    AND h.sendsmtp > 0
			ORDER BY a.addr ASC
		    ) t
		"
    ::dbdns exec $sql tab {
	set j $tab(j)
    }

    ::scgi::set-header Content-Type application/json
    ::scgi::set-body $j
}
