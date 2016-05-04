api-handler get {/names} yes {
	view	0
	cidr	0
	domain	0
    } {
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
