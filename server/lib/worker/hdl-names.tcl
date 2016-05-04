api-handler get {/names} yes {
	view	0
	name	0
	domain	0
	context	0
	cidr	0
    } {
    if {$::parm::context ne ""} then {
	if {$::parm::view eq "" || $::parm::name eq "" || $::parm::domain eq ""} then {
	    sgciapp::scgi-error 400 "'context' parameter can be used only if view/name/domain are provided"
	}

	if {[check-authorized-host
    }
    puts "/names => view=$::parm::view"
}

api-handler get {/names/([0-9]+:idrr)} yes {
	fields	0
    } {

    puts stderr "BINGO !"
    puts "idrr=$::parm::idrr"
    puts "fields=$::parm::fields"

    if {! [read-rr-by-id $dbfd(dns) $::parm::idrr trr]} then {
	puts "NOT FOUND"
    } else {
	puts [array get trr]
    }
}
