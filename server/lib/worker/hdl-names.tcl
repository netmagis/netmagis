api-handler get {/names} yes {
	view	0
	name	0
	domain	0
	context	0
	cidr	0
    } {
    if {$::p::context ne ""} then {
	if {$p::view eq "" || $p::name eq "" || $p::domain eq ""} then {
	    scgiapp::scgi-error 400 "'context' parameter can be used only if view/name/domain are provided"
	}
	set idview [::u viewid $p::view]
	if {$idview eq ""} then {
	    scgiapp::scgi-error 404 "View not found"
	}
	set msg [check-authorized-host ::dbdns [::u idcor] $p::name $p::domain $idview trr $p::context]
	if {$msg eq ""} then {
	    set idrr $trr(idrr)
	    if {$idrr eq ""} then {
		scgiapp::scgi-error 404 "Not found"
	    } else {
		set sql "SELECT row_to_json (r)
				FROM dns.full_rr r
				WHERE idrr = $idrr"
		set j ""
		::dbdns exec $sql tab {
		    set j $tab(row_to_json)
		}
		scgiapp::set-body $j
		scgiapp::set-header Content-type application/json
	    }
	} else {
	    scgiapp::scgi-error 403 "Forbidden ($msg)"
	}
    }
}

api-handler get {/names/([0-9]+:idrr)} yes {
	fields	0
    } {

    puts stderr "BINGO !"
    puts "idrr=$p::idrr"
    puts "fields=$p::fields"

    if {! [read-rr-by-id $dbfd(dns) $p::idrr trr]} then {
	puts "NOT FOUND"
    } else {
	puts [array get trr]
    }
}
