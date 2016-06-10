# allowed tables:
# each table has the following attributes:
#	- id used for /admin/table/id key
#	- list of ids which can be used as a filter
#

set admin_tables {
    dns.network		{ref {idnet idorg idcomm}}
    dns.community	{ref {idcomm}}
    dns.organization	{ref {idorg}}
    dns.zone_forward	{ref {idview}}
    dns.zone_reverse4	{ref {idview}}
    dns.zone_reverse6	{ref {idview}}
    dns.hinfo		{ref {idhinfo}}
    dns.domain		{ref {iddom}}
    dns.dhcpprofile	{ref {iddhcpprof}}
    dns.view		{ref {idview}}
    global.config	{ref {key}}
    global.nmuser	{ref {idcor idgrp}}
    global.nmgroup	{ref {idgrp}}

    dns.p_ip		{gperm {idgrp}}
    dns.p_network	{gperm {idgrp idnet}}
    dns.p_view		{gperm {idgrp idview}}
    dns.p_dchpprofile	{gperm {idgrp iddhcpprof}}
    dns.p_dom		{gperm {idgrp iddom}}
}

api-handler get {/admin/([a-z._]+:table)} yes {
    } {
    if {! [::u cap "p_admin"]} then {
	::scgi::serror 403 [mc "Forbidden"]
    }

    global admin_tables

    if {! [dict exists $admin_tables $table]} then {
	::scgi::serror 404 [mc "Table %s not found" $table]
    }
    lassign [dict get $admin_tables $table] type lid

    #
    # Check filter given by query parameters
    # (but don't try to filter on the key)
    #

    set lwhere {}
    foreach id [lreplace $lid 0 0] {
	if {[dict exists $_parm $id]} then {
	    set val [lindex [dict get $_parm $id] 0]
	    if {! [regexp {^[0-9]+$} $val]} then {
		::scgi::serror 404 [mc "%s parameter is not numeric" $id]
	    }
	    lappend lwhere "$id = $val"
	}
    }
    set where ""
    if {[llength $lwhere] > 0} then {
	set where [format "WHERE %s" [join $lwhere " AND "]]
    }

    if {$type eq "ref"} then {
	set idname [lindex $lid 0]
	set sql "SELECT json_agg (r.*) AS j
			FROM (SELECT * FROM $table $where) AS r
		"
    } else {
	# idname is idgrp
	set sql "SELECT json_agg (r.*) AS j
		    FROM (
			SELECT g.idgrp, gp.perm
			    FROM global.nmgroup g
				, LATERAL (
					SELECT array_agg (row_to_json (p.*))
						AS perm
					    FROM $table p
					    WHERE p.idgrp = g.idgrp
				    ) AS gp
		    ) AS r
		"
    }

    set j {[]}		;# never used: json_agg always returns exactly 1 row
    ::dbdns exec $sql tab {
	set j $tab(j)
    }

    ::scgi::set-header Content-Type application/json
    ::scgi::set-body $j
}

api-handler get {/admin/([a-z._]+:table)/([0-9]+:id)} yes {
    } {
    if {! [::u cap "p_admin"]} then {
	::scgi::serror 403 [mc "Forbidden"]
    }

    global admin_tables

    if {! [dict exists $admin_tables $table]} then {
	::scgi::serror 404 [mc "Table %s not found" $table]
    }
    lassign [dict get $admin_tables $table] type lid

    if {$type eq "ref"} then {
	set idname [lindex $lid 0]
	set sql "SELECT row_to_json (t.*) AS j
			FROM $table t
			WHERE $idname = $id
		    "
    } else {
	# idname is idgrp
	set sql "SELECT row_to_json (r.*) AS j
		    FROM (
			SELECT $id AS idgrp, gp.perm
			    FROM (
				SELECT array_agg (row_to_json (p.*))
					AS perm
				    FROM $table p
				    WHERE p.idgrp = $id
			    ) AS gp
		    ) AS r
		"
    }

    set found 0
    ::dbdns exec $sql tab {
	set j $tab(j)
	set found 1
    }

    if {! $found} then {
	::scgi::serror 404 [mc {Resource %1$d of table %2$s not found} $id $table]
    }

    ::scgi::set-header Content-Type application/json
    ::scgi::set-body $j
}

#
# POST to enter a new item is for referential tables only (i.e. not for
# permissions)
#
# Expecting:
#	[ { attr1:val11, attr2:val12....}, {attr1:val21, attr2:val22...}... ]
# (without index)
#
# Example: for /admin/dns.organization
#	{"name":"Big Corp. Inc"}
#

api-handler post {/admin/([a-z._]+:table)} yes {
    } {
    if {! [::u cap "p_admin"]} then {
	::scgi::serror 403 [mc "Forbidden"]
    }

    global admin_tables

    if {! [dict exists $admin_tables $table]} then {
	::scgi::serror 404 [mc "Table %s not found" $table]
    }
    lassign [dict get $admin_tables $table] type lid

    if {$type ne "ref"} then {
	::scgi::serror 403 [mc "Table %s not allowed" $table]
    }
    set idname [lindex $lid 0]
    set qbody [pg_quote [::scgi::get-body-json $_parm]]

    #
    # Insert the new item in collection
    #

    regsub {^([^\.]+)\.([^\.]+)$} $table {\1.seq_\2} seq
    set qseq [pg_quote $seq]

    set temp "temp[::thread::id]"
    set sql "CREATE TEMPORARY TABLE $temp ON COMMIT DROP AS
		    SELECT * FROM json_populate_record (null::$table, $qbody) ;
		UPDATE $temp SET $idname = nextval ($qseq) ;
		WITH newrow AS (
		    INSERT INTO $table SELECT * FROM $temp RETURNING *
		) SELECT row_to_json (t.*) AS j
			FROM (SELECT * FROM newrow) AS t
	    "

    set j ""
    ::dbdns lock [list $table] {
	::dbdns exec $sql tab {
	    set j $tab(j)
	}
    }

    ::scgi::set-header Content-Type application/json
    ::scgi::set-body $j
}

#
# Expecting:
#	[ { attr1:val11, attr2:val12....}, {attr1:val21, attr2:val22...}... ]
#	
# Example: for /admin/dns.p_view
#	[ {"idview":1, "selected":1, "sort":100}, {"idview":2, ...} ]
#
# No check on individual attribute names, except usual identifier syntax
#	

api-handler put {/admin/([a-z._]+:table)/([0-9]+:id)} yes {
    } {
    if {! [::u cap "p_admin"]} then {
	::scgi::serror 403 [mc "Forbidden"]
    }

    global admin_tables

    if {! [dict exists $admin_tables $table]} then {
	::scgi::serror 404 [mc "Table %s not found" $table]
    }
    lassign [dict get $admin_tables $table] type lid
    set body [::scgi::get-body-json $_parm]
    set qbody [pg_quote $body]
    set temp "temp[::thread::id]"

    if {$type eq "ref"} then {
	set idname [lindex $lid 0]

	#
	# Update referential table
	# For this request, due to the rigidity of UPDATE SQL statement,
	# we have to get all column names. We extrat them from JSON
	# input.
	#

	set lcol [list $idname]
	dict for {name val} [dict get $_parm "_bodydict"] {
	    if {! [regexp {^[a-z][_a-z]*$} $name]} then {
		::scgi::serror 404 [mc "Invalid JSON field '%s'" $name]
	    }
	    lappend lcol $name
	}
	set cols [join $lcol ","]

	set sql "CREATE TEMPORARY TABLE $temp ON COMMIT DROP AS
		    SELECT *
			FROM json_populate_record (null::$table, $qbody) ;
		UPDATE $temp SET $idname = $id ;
		UPDATE $table
			SET ($cols) = (SELECT * FROM $temp)
			WHERE $idname = $id
		"
    } else {
	#
	# Insert new permissions for this group
	#

	set sql "CREATE TEMPORARY TABLE $temp ON COMMIT DROP AS
		    SELECT *
			FROM json_populate_recordset (null::$table, $qbody) ;
		UPDATE $temp SET idgrp = $id ;
		DELETE FROM $table WHERE idgrp = $id ;
		INSERT INTO $table SELECT * FROM $temp
		"
    }

    ::dbdns lock [list $table] {
	::dbdns exec $sql
    }

    ::scgi::set-header Content-Type application/json
    ::scgi::set-body ""
}
