# allowed tables:
# each table has the following attributes:
#	- id used for /admin/table/id key
#	- list of ids which can be used as a filter
#

set allowed_tables {
    dns.network {idnet idorg idcomm}
    dns.community {idcomm}
    dns.organization {idorg}
    dns.zone_forward {idview}
    dns.zone_reverse4 {idview}
    dns.zone_reverse6 {idview}
    dns.hinfo {idhinfo}
    dns.domain {iddom}
    dns.dhcpprofile {iddhcpprof}
    dns.view {idview}
    global.config {key}
    global.nmuser {idcor idgrp}
    global.nmgroup {idgrp}
}

set allowed_groups {
    dns.p_ip {idgrp}
    dns.p_network {idgrp idnet}
    dns.p_view {idgrp idnet}
}

api-handler get {/admin/([a-z._]+:table)} yes {
    } {
    if {! [::u cap "p_admin"]} then {
	::scgiapp::scgi-error 403 [mc "Forbidden"]
    }

    global allowed_tables
    global allowed_groups

    if {[dict exists $allowed_tables $table]} then {
	set sql "SELECT array_to_json (array_agg (row_to_json (t.*))) AS j
			FROM $table t
		"
    } elseif {[dict exists $allowed_groups $table]} then {
	set sql "SELECT json_agg (t.*) AS j
			FROM $table t
		"
    } else {
	::scgiapp::scgi-error 404 [mc "Table %d not found" $table]
    }

    set j ""
    ::dbdns exec $sql tab {
	set j $tab(j)
    }
    ::scgiapp::set-header Content-Type application/json
    ::scgiapp::set-body $j
}

api-handler get {/admin/([a-z._]+:table)/([0-9]+:id)} yes {
    } {
    ::scgiapp::set-header Content-Type application/json
    ::scgiapp::set-body $j
}
