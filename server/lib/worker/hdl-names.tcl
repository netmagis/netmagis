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
	if {[check-authorized-host ::dbdns [::u idcor] $p::name $p::domain $idview trr $p::context]} then {
	    puts BINGO!
	} else {
	    scgiapp::scgi-error 403 Forbidden
	}
    }
    puts "/names => view=$p::view"
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
