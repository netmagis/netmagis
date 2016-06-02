array set fileext {
    html text/html
    json application/json
    pdf  application/pdf
}

api-handler get {/files/([-a-zA-Z0-9][-a-zA-Z0-9.]*:name)} yes {
    } {
    global fileext
    global conf

    if {! [regexp {^(.*)\.([^.]+)$} $name foo base ext]} then {
	::scgiapp::scgi-error 404 [mc "Invalid file name '%s'" $name]
    }

    if {! [info exist fileext($ext)]} then {
	::scgiapp::scgi-error 404 [mc "Invalid extension '%s'" $ext]
    }
    lassign $fileext($ext) mimetype

    set lang [mclocale]

    set path ""
    foreach f [list $base.$lang.$ext $base.$ext] {
	set p $conf(static-dir)/$f
	if {[file exists $p]} then {
	    set path $p
	    break
	}
    }

    if {$path eq ""} then {
	::scgiapp::scgi-error 404 [mc "File '%s' not found" $name]
    }

    try {
	set fd [open $path "r"]
	set r [read $fd]
	close $fd
    } on error msg {
	::scgiapp::scgi-error 404 [mc "Error reading file '%s'" $name]
    }

    ::scgiapp::set-header Content-Type $mimetype
    ::scgiapp::set-body $r
}
