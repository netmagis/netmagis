set conf(defaultfile)	netmagis.html

api-handler get {} any {
    } {
    global conf

    set name $conf(defaultfile)

    set path ""
    foreach d $conf(files) {
	set p $d/$name
	if {[file exists $p]} then {
	    set path $p
	    break
	}
    }

    if {$path eq ""} then {
	::scgi::serror 404 [mc "File '%s' not found" $name]
    }

    try {
	set fd [open $path "rb"]
	set r [read $fd]
	close $fd
    } on error msg {
	::scgi::serror 404 [mc "Error reading file '%s'" $path]
    }

    ::scgi::set-header Content-Type "text/html"
    ::scgi::set-body $r true
}
