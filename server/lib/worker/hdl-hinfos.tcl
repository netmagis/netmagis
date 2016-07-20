##############################################################################

api-handler get {/hinfos} logged {
	present 0
    } {

    set w [hinfo-test-present $present]
    if {$w ne ""} then {
	set w "WHERE $w"
    }

    set sql "SELECT COALESCE (json_agg (t), '\[\]') AS j FROM (
		SELECT idhinfo, name, present
		    FROM dns.hinfo
		    $w
		    ORDER BY sort ASC
		) AS t
		"
    ::dbdns exec $sql tab {
	set j $tab(j)
    }
    ::scgi::set-header Content-Type application/json
    ::scgi::set-body $j
}

##############################################################################

api-handler get {/hinfos/([0-9]+:idhinfo)} logged {
	present 0
    } {
    set w [hinfo-test-present $present]
    if {$w ne ""} then {
	set w "$w AND"
    }

    set sql "SELECT row_to_json (t.*) AS j FROM (
		SELECT idhinfo, name
		    FROM dns.hinfo
		    WHERE $w
			idhinfo = $idhinfo
		) AS t
		"
    set found 0
    ::dbdns exec $sql tab {
	set found 1
	set j $tab(j)
    }

    if {! $found} then {
	::scgi::serror 404 [mc "Hinfo %s not found"]
    }

    ::scgi::set-header Content-Type application/json
    ::scgi::set-body $j
}

##############################################################################
# Utility function
##############################################################################

proc hinfo-test-present {present} {
    switch -exact -- $present {
	{} { set w "" }
	0  { set w "present = 0" }
	1  { set w "present != 0" }
	default {
	    ::scgi::serror 412 [mc "Invalid present value '%s' $present]
	}
    }
}
