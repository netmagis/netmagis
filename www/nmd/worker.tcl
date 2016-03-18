
source %LIBNETMAGIS%

source /local/netmagis/www/netmagis/lib.tcl

set debug 1

set conf(static-dir)	/tmp
set conf(api-dir)	/local/netmagis/www/netmagis/api

package require html
package require Pgtcl

array set route {
    get {}
    post {}
    put {}
    delete {}
}

proc scgi-accept {sock ip port} {
    set code [catch {scgi-accept-2 $sock $ip $port} result err] 
    if {$code == 1} then {
	puts stderr "Erreur attrapée par scgi-accept:"
	puts stderr [dict get $err -errorinfo]
    }
}

proc scgi-accept-2 {sock ip port} {
    thread::attach $sock
    fconfigure $sock -translation {binary crlf}

    #
    # Exemple from: https://python.ca/scgi/protocol.txt
    #	"70:"
    #   	"CONTENT_LENGTH" <00> "27" <00>
    #		"SCGI" <00> "1" <00>
    #		"REQUEST_METHOD" <00> "POST" <00>
    #		"REQUEST_URI" <00> "/deepthought" <00>
    #	","
    #	"What is the answer to life?"
    #

    set len ""
    # Decode the length of the netstring: "70:..."
    while {1} {
	set c [read $sock 1]
	if {$c eq ":"} then {
	    break
	}
	append len $c
    }
    # Read the value (all headers) of the netstring
    set data [read $sock $len]

    # Read the final comma (which is not part of netstring len)
    set comma [read $sock 1]
    if {$comma ne ","} then {
	puts $sock "500 Internal server error"
	close $sock
	return
    }

    # Netstring contains headers. Decode them (without final \0)
    set headers [lrange [split $data \0] 0 end-1]

    # Get content_length header
    set cl 0
    catch {set cl [dict get $headers CONTENT_LENGTH]}

    set body [read $sock $cl]

    handle-request $sock $headers $body

    close $sock
}

##############################################################################
# PostgreSQL interface
##############################################################################

#
# Input:
#   - db: "dns" or "mac"
#   - sql: sql command to send to the database
#   - tabname: name of an array used in the tcl script
#   - script: tcl script to execute for each row
# Output:
#   - return value: empty string (no error) or sql error message
#   - script error: a Tcl error is throwed
#

proc nm_pg_select {db sql tabname script} {
    global dbfd
    global debug

    set r ""
    try {
	uplevel 1 [list pg_execute -array $tabname $dbfd($db) $sql $script]
    } trap {NONE} {msg err} {
	# Pgtcl 1.9 returns errorcode == NONE
	set errinfo [dict get $err -errorinfo]
	if {[regexp "^PGRES_FATAL_ERROR" $errinfo]} then {
	    # reset db handle
	    set info [pg_dbinfo status $dbfd($db)]
	    if {$info ne "connection_ok"} then {
		database-disconnect $db
	    }

	    # return a one-line message, or throw an error with the full stack?
	    if {$debug} then {
		error $msg $errinfo NONE
	    } else {
		set first [lindex [split $errinfo "\n"] 0]
		regsub {.*ERROR:\s+} $first {} r
	    }
	} else {
	    # it is not a Pgtcl error
	    error $msg $errinfo NONE
	}
    }
    return $r
}

##############################################################################
# Request handling
##############################################################################

#
# Input:
#   - sock: socket
#   - headers: Tcl dictionnary containing http server informations
#   - body: request body, including form parameters
# Output:
#   - stdout: <code> <text>

proc handle-request {sock headers body} {
    if {[catch {set uri [dict get $headers DOCUMENT_URI]}]} then {
	api-error $sock 400 "Cannot read DOCUMENT_URI"
	return
    }

    puts "HANDLE-REQUEST $uri"
				array set h $headers
				parray h

    switch -regexp -matchvar last $uri {
	{^/static/([[:alnum:]][-.[:alnum:]]*)$} {
	    handle-static $sock [lindex $last 1]
	}
	default {
	    #
	    # Try API
	    #

#	    regsub -all {/+} $uri {_} route
	    if {[catch {set method [dict get $headers REQUEST_METHOD]}]} then {
		api-error $sock 400 "Cannot read REQUEST_METHOD"
		return
	    }
	    set method [string tolower $method]

	    global route
	    global dbfd


	    set found 0
	    foreach r $route($method) {
		lassign $r re vars paramspec script

		set l [regexp -inline $re $uri]
		if {[llength $l] > 0} then {
		    set i 0
		    foreach val [lreplace $l 0 0] {
			set var [lindex $vars $i]
			# XXXXXXXXXXXXXXXXX
			#uplevel \#0 {set $var $val}
			set $var $val
			incr i
		    }
		    #uplevel \#0 eval $script

		    set codetext [database-reconnect dns]
		    if {$codetext ne ""} then {
			lassign $codetext code msg
			api-error $sock $code $msg
			return
		    }

		    set codetext [database-reconnect mac]
		    if {$codetext ne ""} then {
			lassign $codetext code msg
			api-error $sock $code $msg
			return
		    }

		    if {[catch $script msg]} then {
			puts stderr "ERREUR pour '$uri': $msg"
		    }
		    set found 1
		    break
		}
	    }

	    if {! $found} then {
		api-error $sock 404 "'$uri' not found"
	    }
	    return
	}
    }
}

array set http_codes {
    400 {Bad Request}
    401 {Unauthorized}
    402 {Payment Required}
    403 {Forbidden}
    404 {Not Found}
    405 {Method Not Allowed}
    406 {Not Acceptable}
    407 {Proxy Authentication Required}
    408 {Request Timeout}
    409 {Conflict}
    410 {Gone}
    411 {Length Required}
    412 {Precondition Failed}
    413 {Request Entity Too Large}
    414 {Request-URI Too Long}
    415 {Unsupported Media Type}
    416 {Requested Range Not Satisfiable}
    417 {Expectation Failed}
    418 {I'm a teapot (RFC 2324)}
    420 {Enhance Your Calm (Twitter)}
    422 {Unprocessable Entity (WebDAV)}
    423 {Locked (WebDAV)}
    424 {Failed Dependency (WebDAV)}
    425 {Reserved for WebDAV}
    426 {Upgrade Required}
    428 {Precondition Required}
    429 {Too Many Requests}
    431 {Request Header Fields Too Large}
    444 {No Response (Nginx)}
    449 {Retry With (Microsoft)}
    450 {Blocked by Windows Parental Controls (Microsoft)}
    499 {Client Closed Request (Nginx)}
}

proc api-error {sock code msg} {
    global http_codes

    if {! [info exists http_codes($code)]} then {
	set msg "Code $code substituted by 400. Original message: $msg"
	set code 400
    }
    puts $sock "$code $http_codes($code)"
    puts $sock "Content-Type: text/plain"
    puts $sock ""
    puts $sock $msg
}

proc handle-static {sock page} {
    global conf

    set path $conf(static-dir)/$page

    if {[file exists $path]} then {
	# Determine Content-Type, based on file extension
	switch -glob [string tolower $page] {
	    *.png	{ set ct "image/png" ; set bin 1 }
	    *.gif	{ set ct "image/gif" ; set bin 1 }
	    *.jpg	{ set ct "image/jpeg" ; set bin 1 }
	    *.jpeg	{ set ct "image/jpeg" ; set bin 1 }
	    *.html	{ set ct "text/html" ; set bin 0 }
	    default	{ set ct "text/plain" ; set bin 0 }
	}

	if {[catch {set fd [open $path "r"]} msg]} then {
	    api-error $sock 404 "Cannot open '$page' ($msg)"
	    return
	}
	if {$bin} then {
	    fconfigure $fd -translation binary
	}
	set content [read $fd]
	close $fd

	puts $sock "Status: 200 OK"
	puts $sock "Content-Type: $ct"
	puts $sock ""
	if {$bin} then {
	    fconfigure $sock -translation binary
	}
	puts $sock $content
    } else {
	api-error $sock 404 "'$page' not found"
    }
}

proc handle-api-v1 {sock action headers body} {

    set codetext [database-reconnect dns]
    if {$codetext ne ""} then {
	lassign $codetext code msg
	api-error $sock $code $msg
	return
    }

    set codetext [database-reconnect mac]
    if {$codetext ne ""} then {
	lassign $codetext code msg
	api-error $sock $code $msg
	return
    }

#				array set h $headers
#				parray h

    #
    # Look for form value for "name"
    #
    set name ""
    if {$body ne ""} then {
	############## XXXXXXX : improve decoding, make it robust
	foreach pair [split $body &] {
	    lassign [split $pair =] key val
	    if {$key == "name"} then {
		set name $val
		break
	    }
	}
    }

    # exec sleep 10

    if {$name eq ""} then {
	puts $sock "Status: 200 OK"
	puts $sock "Content-Type: text/html"
	puts $sock ""
	puts $sock "<HTML>"
	puts $sock "<BODY>"
	puts $sock {<FORM METHOD="POST" ACTION="/sdshdsqghd">}
	puts $sock {Name&nbsp;:}
	puts $sock {<INPUT TYPE="TEXT" NAME="name">}
	puts $sock {<INPUT TYPE="SUBMIT" VALUE ="Consult">}
	puts $sock {</FORM>}
	puts $sock {</BODY>}
	puts $sock {</HTML>}
    } else {
	puts $sock "Status: 200 OK"
	puts $sock "Content-Type: text/html"
	puts $sock ""
	puts $sock "<HTML>"
	puts $sock "<BODY>"
	puts $sock {<TABLE>}
	set sql "SELECT r.name || '.' || d.name AS name,
				i.addr,
				v.name AS view
			    FROM dns.rr_ip i,
				dns.rr r,
				dns.domain d,
				dns.view v
			    WHERE r.name = '$name'
				AND r.iddom = d.iddom
				AND r.idrr = i.idrr
				AND r.idview = v.idview
			    "
	puts stdout "AVANT PGEXEC"
	set msg [nm_pg_select dns $sql t {
	    puts $sock {<TR>}
	    puts $sock "<TD>$t(name)</TD>"
	    puts $sock "<TD>$t(addr)</TD>"
	    puts $sock "<TD>$t(view)</TD>"
	    puts $sock {</TR>}
	} ]
	puts stdout "APRES PGEXEC : msg=$msg"
	puts $sock {</TABLE>}
	puts $sock {</BODY>}
	puts $sock {</HTML>}
    }
}

##############################################################################
# Thread initialisation
##############################################################################

proc thread-init {} {
    global dbfd
    global conf

    #
    # Prepare for DB connection
    #

    set dbfd(dns) "not connected"
    set dbfd(mac) "not connected"

    #
    # Create a global object for configuration parameters
    #

    config ::dnsconfig

    puts "READY [info procs route-*]"
}

proc database-disconnect {db} {
    global dbfd

    catch {pg_disconnect $dbfd($db)}
    set dbfd($db) "not connected"
}

proc api-handler {method pathspec paramspec script} {
    global route

    set method [string tolower $method]

    if {! [info exists route($method)]} then {
	puts stderr "invalid method for route $pathspec"
	exit 1
    }

    #
    # Check the path specification
    #

    set n1 [regexp -all {[(]} $pathspec]
    set n2 [regexp -all {[)]} $pathspec]
    set n3 [regexp -all {[:]} $pathspec]
    set n4 [regsub -all {\(([^:]+):[^)]+\)} $pathspec {} dummy]
    puts "pathspec=$pathspec, n1=$n1, n2=$n2, n3=$n3, n4=$n4"
    if {$n1 != $n2 || $n2 != $n3 || $n3 != $n4} then {
	puts stderr "invalid path specification '$pathspec'"
	exit 1
    }

    #
    # Extract variable names from path specification
    #

    set vars {}
    foreach {all var} [regexp -all -inline {:([^)]+)\)} $pathspec] {
	lappend vars $var
    }

    #
    # Build regexp for URI matching
    #

    regsub -all {\(([^:]+):[^)]+\)} $pathspec {(\1)} re
    set re "^$re$"

    lappend route($method) [list $re $vars $paramspec $script]
}

api-handler get {/views} {
	crit	0 1
    } {
}

api-handler get {/views/([0-9]+:idview)} {
	crit	0 1
    } {
}

api-handler get {/names} {
	view	1 1
    } {
}

api-handler get {/names/([0-9]+:idrr)} {
	fields	0 1
    } {

    puts stderr "BINGO !"
    puts "idrr=$idrr"

    if {! [read-rr-by-id $dbfd(dns) $idrr trr]} then {
	puts "NOT FOUND"
    } else {
	puts [array get trr]
    }
}

#
# Input:
#   - db: "dns" or "mac"
#

proc database-reconnect {db} {
    global dbfd
    global libconf

    if {$dbfd($db) ne "not connected"} then {
	return {}
    }
    puts stderr "RECONNECT $db"

    switch $db {
	dns {
	    #
	    # Access to Netmagis database
	    #

	    set conninfo [get-conninfo "dnsdb"]
	    if {[catch {set dbfd($db) [pg_connect -conninfo $conninfo]} msg]} then {
		return "503 Database unavailable"
	    }

	    #
	    # Access to configuration parameters (stored in the database)
	    #

	    dnsconfig setdb $dbfd($db)

	    #
	    # Check compatibility with database schema version
	    # - empty string : pre-2.2 schema
	    # - non empty string : integer containing schema version
	    # Netmagis version (x.y.... => xy) must match schema version.
	    #

	    # get code version (from top-level Makefile)
	    if {! [regsub {^(\d+)\.(\d+).*} $libconf(version) {\1\2} nver]} then {
		return [format "500 Internal Server Error (Netmagis version number '%s' unrecognized)" $libconf(version)]
	    }

	    # get schema version (from database)
	    if {[catch {dnsconfig get "schemaversion"} sver]} then {
		set sver ""
	    }

	    if {$sver eq ""} then {
		return [format "500 Internal Server Error (Database schema is too old. See http://netmagis.org/upgrade.html)" $version]
	    } elseif {$sver < $nver} then {
		return [format "500 Internal Server Error (Database schema is too old. See http://netmagis.org/upgrade.html)" $version]
	    } elseif {$sver > $nver} then {
		return [format "500 Internal Server Error (Database schema '%1$s' is not yet recognized by Netmagis %2$s)" $sver $version]
	    }

	    #
	    # Log initialization
	    #

	    set log [::webapp::log create %AUTO% \
					-subsys netmagis \
					-method opened-postgresql \
					-medium [list "db" $dbfd($db) table global.log] \
			    ]
	}
	mac {
	    #
	    # Access to MAC database
	    #

	    set conninfo [get-conninfo "macdb"]
	    if {[catch {set dbfd($db) [pg_connect -conninfo $conninfo]} msg]} then {
		return "503 Database unavailable"
	    }

	}
    }

    return ""
}

thread-init
