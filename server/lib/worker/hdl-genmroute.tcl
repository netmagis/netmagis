api-handler get {/gen/mroute} genz {
    } {

    #
    # Extract views which have at least one mailaddr
    #

    set sql "SELECT COALESCE (json_agg (t), '\[\]') AS j FROM (
			SELECT DISTINCT v.name
			    FROM dns.mailrole m
				INNER JOIN dns.name n USING (idname)
				INNER JOIN dns.view v USING (idview)
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
api-handler get {/gen/mroute/([^/]+:name)} genz {
    } {

    set idview [::n viewid $name]
    if {$idview == -1} then {
	::scgi::serror 404 [mc "View '%s' not found" $name]
    }

    #
    # Get mail routes
    #

    set sql "SELECT COALESCE (json_agg (t), '\[\]') AS j FROM (
		    SELECT na.name || '.' || da.name AS mailaddr,
			    nh.name || '.' || dh.name AS mailhost
			FROM dns.name na
			    INNER JOIN dns.domain da USING (iddom)
			    INNER JOIN dns.mailrole mr USING (idname)
			    INNER JOIN dns.host h USING (idhost)
			    INNER JOIN dns.name nh ON (h.idname = nh.idname)
			    INNER JOIN dns.domain dh ON (nh.iddom = dh.iddom)
			WHERE na.idview = $idview
			ORDER BY dh.name ASC, nh.name ASC,
			    da.name ASC, na.name ASC
		    ) t
		"
    ::dbdns exec $sql tab {
	set j $tab(j)
    }

    ::scgi::set-header Content-Type application/json
    ::scgi::set-body $j
}
