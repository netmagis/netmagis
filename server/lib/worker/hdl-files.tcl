array set fileext {
    html text/html
    json application/json
    js   application/javascript
    pdf  application/pdf
    css  text/css
    png  image/png
}

set conf(defaultfile)	netmagis.html

#
# Notice: conf(files) is a sorted list of directories where to
# search for files
#


#
# This is the fallback handler for GET method
# (since the selection regexp is empty)
#
# We use the _prefix variable preset by the worker handle-request
# procedure, which has been sanitized (no ".." nor "/" repetition)
# by the HTTP server (tested with Apache and Nginx)
#

api-handler get {} any {
    } {
    global fileext
    global conf

    #
    # Use the current locale to add items to the search path
    #

    set lang [mclocale]

    #
    # Get all components (except the first: /) from the prefix
    #

    set lcomp [lreplace [file split $_prefix] 0 0]

    #
    # Check the final component to see if it looks like a file
    # name (with an extension in fileext).
    # If not, add the defaultfile.
    #

    lassign [file-mimetype [lindex $lcomp end]] mimetype base ext
    if {$mimetype eq ""} then {
	lappend lcomp $conf(defaultfile)
	lassign [file-mimetype [lindex $lcomp end]] mimetype base ext
    }

    #
    # Get a list of all suitable paths from the shortest to the
    # longest.
    # E.g: if _prefix=/a/b/c/x/y.html (lcomp={a b c x y.html}),
    # build the list:
    #	{y.html x/y.html c/x/y.html b/c/x/y.html a/b/c/x/y.html}
    # and add the current locale <LC> in this search list:
    #	{y.html.<LC> y.html x/y.html.<LC> x/y.html ...}
    #

    set lpath {}
    set start [expr [llength $lcomp]-1]
    for {set i $start} {$i >= 0} {incr i -1} {
	#
	# Add the more precise first: with current locale
	#
	set l [lrange $lcomp $i end-1]
	lappend l "$base.$lang.$ext"
	lappend lpath [join $l "/"]

	#
	# Add the generic (unlocalized) next:
	#
	lappend lpath [join [lrange $lcomp $i end] "/"]
    }

    #
    # Search for the file with the multiple combinations
    #

    set path ""
    foreach f $lpath {
	foreach d $conf(files) {
	    set p $d/$f
	    if {[file exists $p]} then {
		set path $p
		break
	    }
	}
    }

    if {$path eq ""} then {
	::scgi::serror 404 [mc "URI %s not found" $_prefix]
    }

    try {
	set fd [open $path "rb"]
	set r [read $fd]
	close $fd
    } on error msg {
	::scgi::serror 404 [mc "Error reading file '%s'" $_prefix]
    }

    # Replace templates variables by their values
    if {$ext eq "html"} then {
	regsub -all {%LANG%} $r $lang r
    }

    ::scgi::set-header Content-Type $mimetype
    ::scgi::set-body $r true
}

#
# Detects the mimetype from the file extension.
# Returns a list {mimetype base ext} or {}
#

proc file-mimetype {name} {
    global fileext

    set r {}
    if {[regexp {^(.*)\.([^.]+)$} $name foo base ext]} then {
	if {[info exist fileext($ext)]} then {
	    set r [list $fileext($ext) $base $ext]
	} else {
	    ::scgi::serror 404 [mc "Invalid extension '%s'" $ext]
	}
    }
    return $r
}
