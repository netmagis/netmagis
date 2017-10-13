# allowed tables:
# each table has the following attributes:
#	- id used for /admin/table/id key
#	- list of ids which can be used as a filter
#

set admin_tables {
    dns.network		{ref {idnet int idorg int idcomm int}}
    dns.community	{ref {idcomm int}}
    dns.organization	{ref {idorg int}}
    dns.zone_forward	{ref {idzone int idview int name str}}
    dns.zone_reverse4	{ref {idzone int idview int name str}}
    dns.zone_reverse6	{ref {idzone int idview int name str}}
    dns.hinfo		{ref {idhinfo int name str sort int}}
    dns.domain		{ref {iddom int}}
    dns.dhcpprofile	{ref {iddhcpprof int}}
    dns.view		{ref {idview int}}
    global.config	{ref {key str}}
    global.nmuser	{ref {idcor int idgrp int}}
    global.nmgroup	{ref {idgrp int}}

    dns.p_ip		{gperm {idgrp int}}
    dns.p_network	{gperm {idgrp int idnet int}}
    dns.p_view		{gperm {idgrp int idview int}}
    dns.p_dchpprofile	{gperm {idgrp int iddhcpprof int}}
    dns.p_dom		{gperm {idgrp int iddom int}}
}

################################################################################

api-handler get {/admin/([a-z0-9._]+:table)} admin {
	order 0
    } {
    global admin_tables

    if {! [dict exists $admin_tables $table]} then {
	::scgi::serror 404 [mc "Table %s not found" $table]
    }
    lassign [dict get $admin_tables $table] type lid

    #
    # Check order list (comma separated list, reverse order indicated by -)
    # Example: order=name,-idview
    #

    set lorder {}
    foreach o [split $order ","] {
	set dir ASC
	if {[regsub {^-} $o {} o]} then {
	    set dir DESC
	}
	set found 0
	foreach {id tp} $lid {
	    if {$o eq $id} then {
		lappend lorder "$o $dir"
		set found 1
		break
	    }
	}
	if {! $found} then {
	    ::scgi::serror 404 [mc "invalid order field '%s'" $o]
	}
    }
    set orderby ""
    if {[llength $lorder] > 0} then {
	set lorder [join $lorder ","]
	set orderby "ORDER BY $lorder"
    }

    #
    # Check filter given by query parameters
    # (but don't try to filter on the key)
    #

    set lwhere {}
    foreach {id tp} [lreplace $lid 0 1] {
	if {[dict exists $_parm $id]} then {
	    set val [lindex [dict get $_parm $id] 0]
	    switch $tp {
		int {
		    if {! [regexp {^[0-9]+} $val]} then {
			::scgi::serror 404 [mc "invalid parameter '%s'" $id]
		    }
		}
		str {
		    set val [pg_quote $val]
		}
	    }
	    lappend lwhere "$id = $val"
	}
    }

    set where ""
    if {$type eq "ref"} then {
	if {[llength $lwhere] > 0} then {
	    set where [format "WHERE %s" [join $lwhere " AND "]]
	}
	set idname [lindex $lid 0]
	set sql "SELECT COALESCE (json_agg (r), '\[\]') AS j FROM (
			SELECT * FROM $table $where $orderby
		    ) AS r
		"
    } else {
	# idname is idgrp
	if {[llength $lwhere] > 0} then {
	    set where [format "AND %s" [join $lwhere " AND "]]
	}
	set sql "SELECT COALESCE (json_agg (r), '\[\]') AS j FROM (
			SELECT g.idgrp, gp.perm
			    FROM global.nmgroup g
				, LATERAL (
					SELECT array_agg (row_to_json (p.*))
						AS perm
					    FROM $table p
					    WHERE p.idgrp = g.idgrp
						$where
				    ) AS gp
		    ) AS r
		"
    }

    ::dbdns exec $sql tab {
	set j $tab(j)
    }

    ::scgi::set-header Content-Type application/json
    ::scgi::set-body $j
}

################################################################################

api-handler get {/admin/([a-z0-9._]+:table)/([^/]+:id)} admin {
    } {
    global admin_tables

    if {! [dict exists $admin_tables $table]} then {
	::scgi::serror 404 [mc "Table %s not found" $table]
    }
    lassign [dict get $admin_tables $table] type lid

    if {$type eq "ref"} then {
	set idname [lindex $lid 0]
	set idtp [lindex $lid 1]
	if {$idtp eq "str"} then {
	    set id [pg_quote $id]
	}
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

################################################################################

api-handler delete {/admin/([a-z0-9._]+:table)/([^/]+:id)} admin {
    } {
    global admin_tables

    if {! [dict exists $admin_tables $table]} then {
	::scgi::serror 404 [mc "Table %s not found" $table]
    }
    lassign [dict get $admin_tables $table] type lid


    if {$type ne "ref" || $type eq "global.config"} then {
	::scgi::serror 403 [mc "Table %s not allowed" $table]
    }

    set idname [lindex $lid 0]
    set idtp [lindex $lid 1]
    if {$idtp eq "str"} then {
	set id [pg_quote $id]
    }

    set sql "DELETE FROM $table t WHERE $idname = $id"

    ::dbdns exec $sql
    ::scgi::set-header Content-Type text/plain
    ::scgi::set-body "OK"
}

################################################################################

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

api-handler post {/admin/([a-z._]+:table)} admin {
    } {
    global admin_tables

    if {! [dict exists $admin_tables $table]} then {
	::scgi::serror 404 [mc "Table %s not found" $table]
    }
    lassign [dict get $admin_tables $table] type lid

    if {$type ne "ref" || $type eq "global.config"} then {
	::scgi::serror 403 [mc "Table %s not allowed" $table]
    }
    set idname [lindex $lid 0]
    set qbody [pg_quote [get-body-json $_parm]]

    #
    # Get the sequence associated to the table
    #

    if {$table in {dns.zone_forward dns.zone_reverse4 dns.zone_reverse6}} then {
	set seq "dns.seq_zone"
    } else {
	regsub {^([^\.]+)\.([^\.]+)$} $table {\1.seq_\2} seq
    }
    set qseq [pg_quote $seq]

    #
    # Insert the new item in collection
    #

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

################################################################################

#
# Expecting:
#	[ { attr1:val11, attr2:val12....}, {attr1:val21, attr2:val22...}... ]
#	
# Example: for /admin/dns.p_view
#	[ {"idview":1, "selected":1, "sort":100}, {"idview":2, ...} ]
#
# No check on individual attribute names, except usual identifier syntax
#	

api-handler put {/admin/([a-z0-9._]+:table)/([^/]+:id)} admin {
    } {
    global admin_tables

    if {! [dict exists $admin_tables $table]} then {
	::scgi::serror 404 [mc "Table %s not found" $table]
    }
    lassign [dict get $admin_tables $table] type lid
    set body [get-body-json $_parm]
    set qbody [pg_quote $body]
    set temp "temp[::thread::id]"

    if {$type eq "ref"} then {
	set idname [lindex $lid 0]
	set idtp [lindex $lid 1]
	if {$idtp eq "str"} then {
	    set id [pg_quote $id]
	}

	#
	# Update referential table element
	# For this request (sql1 below), due to the rigidity of
	# UPDATE SQL statement, we have to get all column names.
	# We extract them from PostgreSQL information_schema.
	# (JSON dict order cannot be trusted)
	#

	if {! [regexp {^([^.]+)\.([^.]+)$} $table foo schema rel]} then {
	    ::scgi::serror 500 [mc {Internal error: cannot split '%1$s'} $table]
	}
	set qschema [pg_quote $schema]
	set qrel [pg_quote $rel]
	set sql "SELECT column_name
		    FROM information_schema.columns
		    WHERE table_schema = $qschema and table_name = $qrel
		    "
	set lcol {}
	::dbdns exec $sql tab {
	    lappend lcol $tab(column_name)
	}
	set cols [join $lcol ","]

	set sql1 "CREATE TEMPORARY TABLE $temp ON COMMIT DROP AS
		    SELECT *
			FROM json_populate_record (null::$table, $qbody) ;
		UPDATE $temp SET $idname = $id ;
		UPDATE $table
			SET ($cols) = (SELECT * FROM $temp)
			WHERE $idname = $id
		"

	set sql2 "SELECT row_to_json (t.*) AS j
			FROM $table t
			WHERE $idname = $id
		    "
    } else {
	#
	# Insert new permissions for this group
	#

	set sql1 "CREATE TEMPORARY TABLE $temp ON COMMIT DROP AS
		    SELECT *
			FROM json_populate_recordset (null::$table, $qbody) ;
		UPDATE $temp SET idgrp = $id ;
		DELETE FROM $table WHERE idgrp = $id ;
		INSERT INTO $table SELECT * FROM $temp
		"

	set sql2 "SELECT row_to_json (r.*) AS j
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

    ::dbdns lock [list $table] {
	::dbdns exec $sql1
    }


    ::dbdns exec $sql2 tab {
	set j $tab(j)
    }

    ::scgi::set-header Content-Type application/json
    ::scgi::set-body $j
}
