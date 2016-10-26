array set fileext {
    html text/html
    json application/json
    js   application/javascript
    pdf  application/pdf
    css  text/css
    png  image/png
}

set conf(defaultfile)	netmagis.html

api-handler get {/} any {
    } {
    global conf

    file-get $conf(defaultfile)
}

api-handler get {/files/([-a-zA-Z0-9][-a-zA-Z0-9.]*:name)} any {
    } {
    file-get $name
}

proc file-get {name} {
    global fileext
    global conf

    if {! [regexp {^(.*)\.([^.]+)$} $name foo base ext]} then {
	::scgi::serror 404 [mc "Invalid file name '%s'" $name]
    }

    if {! [info exist fileext($ext)]} then {
	::scgi::serror 404 [mc "Invalid extension '%s'" $ext]
    }
    lassign $fileext($ext) mimetype

    set lang [mclocale]

    set path ""
    foreach f [list $base.$lang.$ext $base.$ext] {
	foreach d $conf(files) {
	    set p $d/$f
	    if {[file exists $p]} then {
		set path $p
		break
	    }
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
	::scgi::serror 404 [mc "Error reading file '%s'" $name]
    }

    # Replace templates variables by their values
    if {$ext eq "html"} then {
	regsub -all {%LANG%} $r $lang r
    }

    ::scgi::set-header Content-Type $mimetype
    ::scgi::set-body $r true
}
