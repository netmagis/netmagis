#!%TCLSH%

set conf(baseurl)	/netmagis
set conf(meth)		{get post put delete}

set conf(version)	SET-BY-MAIN
set conf(conffile)	SET-BY-MAIN
set conf(libdir)	SET-BY-MAIN
set conf(files)		SET-BY-MAIN
set conf(tctfile)	SET-BY-MAIN

set conf(cookies)	[dict create]
set conf(lastcall) 	"(nothing)"
set conf(lastresult) 	"(nothing)"

set conf(allnums)	{}

set conf(usage) {usage: %s version conffile libdir files tctfile}

##############################################################################
# Procedures which may be called by .tct files
##############################################################################

proc test-reset-cookie {} {
    global conf

    set conf(cookies) [dict create]
}

proc test-set-cookie {name val} {
    global conf

    dict set conf(cookies) $name $val
}

# returns a list {status msg contenttype body}
proc test-call {meth uri jsonbody} {
    global conf

    set conf(lastcall) "$meth $uri"

    set hdrs [dict create]

    set meth [string tolower $meth]
    if {$meth ni $conf(meth)} then {
	puts stderr "Unknown method '$meth'"
	exit 1
    }

    #
    # Split uri into a real uri and a query string
    #

    if {[regexp {^([^?]+)\?(.*)} $uri foo uri qs]} then {
	dict set hdrs "QUERY_STRING" $qs
    }
    dict set hdrs "CONTENT_TYPE" "application/json"

    #
    # Process request
    #

    set cook $conf(cookies)
    set r [::scgi::simulcall $meth $uri $hdrs $cook $jsonbody]

    # leave a line in the log
    set conf(lastresult) $r

    return $r
}

# if expr is false, abort with a message including title
proc test-assert {num title expr} {
    global conf

    if {$num in $conf(allnums)} then {
	puts stderr "Test $num already provided"
	exit 1
    } else {
	lappend conf(allnums) $num
    }

    set r [uplevel "expr $expr"]
    if {$r} then {
	puts stderr "ok $num $title"
	puts stderr "\t$conf(lastcall)"
	puts stderr ""
    } else {
	lassign $conf(lastresult) stcode stmsg ct body
	puts stderr "not ok $num $title"
	puts stderr "\t$conf(lastcall)"
	puts stderr "\tstatus=$stcode $stmsg, cnotent-type=$ct"
	puts stderr "\tbody=$body"
	puts stderr "\tassert '$expr' false"
	exit 1
    }
}

# test json equality, returns true or false
proc test-json {ct jout jref} {
    if {$ct ne "application/json"} then {
	return 0
    }
    set nmjref [::nmjson::str2nmj $jref]
    set nmjout [::nmjson::str2nmj $jout]
    return [::nmjson::nmjeq $nmjref $nmjout]
}

##############################################################################
# Main procedure
##############################################################################

proc usage {argv0} {
    global conf

    puts stderr [format $conf(usage) $argv0]
    exit 1
}

proc main {argv0 argv} {
    global conf

    #
    # Initialize default values and parse arguments
    #

    set debug    true

    if {[llength $argv] != 5} then {
	usage $argv0
    }

    lassign $argv version conffile libdir files tctfile

    set conf(version)  $version
    set conf(conffile) $conffile
    set conf(libdir)   $libdir
    set conf(files)    $files
    set conf(tctfile)  $tctfile

    #
    # Load test package
    #

    global auto_path
    lappend auto_path $conf(libdir)/pkgtcl
    package require scgi
    package require nmjson

    #
    # Intialize a false worker thread context 
    #

    set initscript "source $conf(libdir)/worker/worker.tcl"
    set hdlfn "handle-request" 		;# handler function in worker.tcl

    ::scgi::test-mode $debug $initscript $hdlfn

    uplevel \#0 source $conf(tctfile)

    return 0
}

exit [main $argv0 $argv]
