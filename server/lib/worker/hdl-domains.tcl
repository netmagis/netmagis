##############################################################################

api-handler get {/domains} yes {
	mailrole 0
    } {
    set idgrp [::u idgrp]
    set w [domains-test-mailrole $mailrole]
    if {$w ne ""} then {
	set w "AND $w"
    }

    set sql "SELECT json_agg (t.*) AS j FROM (
		SELECT d.*, p.mailrole
		    FROM dns.domain d
			INNER JOIN dns.p_dom p USING (iddom)
		    WHERE p.idgrp = $idgrp
			$w
		    ORDER BY p.sort ASC
		) AS t
		"
    ::dbdns exec $sql tab {
	set j $tab(j)
    }
    if {$j eq ""} then {
	set j {[]}
    }

    ::scgi::set-header Content-Type application/json
    ::scgi::set-body $j
}

##############################################################################

api-handler get {/domains/([0-9]+:iddom)} yes {
	mailrole 0
    } {
    set idgrp [::u idgrp]
    set w [domains-test-mailrole $mailrole]
    if {$w ne ""} then {
	set w "AND $w"
    }
    set sql "SELECT row_to_json (t.*) AS j FROM (
		SELECT d.*, p.mailrole
		    FROM dns.domain d
			INNER JOIN dns.p_dom p USING (iddom)
		    WHERE p.idgrp = $idgrp
			AND d.iddom = $iddom
			$w
		) AS t
		"
    set found 0
    ::dbdns exec $sql tab {
	set found 1
	set j $tab(j)
    }

    if {! $found} then {
	::scgi::serror 404 [mc "Domain %s not found" $iddom]
    }

    ::scgi::set-header Content-Type application/json
    ::scgi::set-body $j
}

##############################################################################
# Utility function
##############################################################################

proc domains-test-mailrole {mailrole} {
    switch -exact -- $mailrole {
	{} { set w "" }
	0  { set w "mailrole = 0" }
	1  { set w "mailrole != 0" }
	default {
	    ::scgi::serror 412 [mc "Invalid mailrole value '%s' $mailrole]
	}
    }
}
