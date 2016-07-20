##############################################################################

api-handler get {/dhcpprofiles} logged {
    } {
    set idgrp [::n idgrp]
    set sql "SELECT COALESCE (json_agg (t), '\[\]') AS j FROM (
		SELECT d.iddhcpprof, d.name
		    FROM dns.dhcpprofile d
			INNER JOIN dns.p_dhcpprofile p USING (iddhcpprof)
		    WHERE p.idgrp = $idgrp
		    ORDER BY p.sort ASC
		) AS t
		"
    ::dbdns exec $sql tab {
	set j $tab(j)
    }
    ::scgi::set-header Content-Type application/json
    ::scgi::set-body $j
}

##############################################################################

api-handler get {/dhcpprofiles/([0-9]+:iddhcpprof)} logged {
    } {
    set idgrp [::n idgrp]
    set sql "SELECT row_to_json (t.*) AS j FROM (
		SELECT d.iddhcpprof, d.name
		    FROM dns.dhcpprofile d
			INNER JOIN dns.p_dhcpprofile p USING (iddhcpprof)
		    WHERE p.idgrp = $idgrp
			AND d.iddhcpprof = $iddhcpprof
		) AS t
		"
    set found 0
    ::dbdns exec $sql tab {
	set found 1
	set j $tab(j)
    }

    if {! $found} then {
	::scgi::serror 404 [mc "DHCP profile %s not found" $iddhcpprof]
    }

    ::scgi::set-header Content-Type application/json
    ::scgi::set-body $j
}
