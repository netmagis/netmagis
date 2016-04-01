# source %LIBNETMAGIS%

# source /local/netmagis/lib/libnetmagis.tcl

source ./lib.tcl

set debug 1

set conf(static-dir)	/tmp
set conf(api-dir)	/local/netmagis/www/netmagis/api
set libconf(version)	3.0.alphabidulemachin

package require html
package require Pgtcl

array set route {
    get {}
    post {}
    put {}
    delete {}
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

proc handle-request {uri meth parm cookie} {

    switch -regexp -matchvar last $uri {
	{^/static/([[:alnum:]][-.[:alnum:]]*)$} {
	    if {$meth eq "get"} then {
		handle-static [lindex $last 1]
	    } else {
		::scgiapp::scgi-error 405 {Method not allowed}
	    }
	}
	default {
	    #
	    # Try API
	    #

	    global route
	    global dbfd

	    set found 0
	    foreach r $route($meth) {
		lassign $r re vars paramspec authneeded script

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
			::scgiapp::scgi-error $code $msg
		    }

		    set codetext [database-reconnect mac]
		    if {$codetext ne ""} then {
			lassign $codetext code msg
			::scgiapp::scgi-error $code $msg
		    }

		    d setdb $dbfd(dns)

		    set authtoken "TOKENTEST"
		    set authenticated [check-authtoken $dbfd(dns) $authtoken login]
		    if {$authneeded} then {
			if {! $authenticated} then {
			    ::scgiapp::scgi-error 403 "Not authenticated"
			}
		    }

		    if {$authenticated} then {
			catch {u destroy}
			::nmuser create ::u
			u setdb $dbfd(dns)
			u setlogin $login
		    }

		    if {[catch $script msg]} then {
			puts stderr "ERREUR pour '$uri': $msg"
		    }
		    set found 1
		    break
		}
	    }

	    if {! $found} then {
		error "'$uri' not found"
	    }
	    return
	}
    }
}

proc handle-static {page} {
    global conf

    set path $conf(static-dir)/$page

    if {[file exists $path]} then {
	# Determine Content-Type, based on file extension
	switch -glob [string tolower $page] {
	    *.png	{ set ct "image/png" ; set bin 1 }
	    *.gif	{ set ct "image/gif" ; set bin 1 }
	    *.jpg	{ set ct "image/jpeg" ; set bin 1 }
	    *.jpeg	{ set ct "image/jpeg" ; set bin 1 }
	    *.pdf	{ set ct "application/pdf" ; set bin 1 }
	    *.html	{ set ct "text/html" ; set bin 0 }
	    default	{ set ct "text/plain" ; set bin 0 }
	}

	if {[catch {set fd [open $path "r"]} msg]} then {
	    ::scgiapp::scgi-error 404 "Cannot open '$page' ($msg)"
	}
	if {$bin} then {
	    fconfigure $fd -translation binary
	}
	set content [read $fd]
	close $fd

	::scgiapp::set-header Content-type $ct
	::scgiapp::set-body $content $bin
    } else {
	::scgiapp::scgi-error 404 "'$page' not found"
    }
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

proc handle-api-v1 {sock action headers body} {

    set codetext [database-reconnect dns]
    if {$codetext ne ""} then {
	lassign $codetext code msg
	::scgiapp::scgi-error $code $msg
    }

    set codetext [database-reconnect mac]
    if {$codetext ne ""} then {
	lassign $codetext code msg
	::scgiapp::scgi-error $code $msg
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

proc api-handler {method pathspec authneeded paramspec script} {
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

    lappend route($method) [list $re $vars $paramspec $authneeded $script]
}

api-handler get {/login} no {
	user	1 1
	passwd	1 1
    } {

    ::scgiapp::set-json {{a 1 b 2 c {areuh tagada bouzouh}}}

}

api-handler get {/views} yes {
	crit	0 1
    } {
}

api-handler get {/views/([0-9]+:idview)} yes {
	crit	0 1
    } {
}

api-handler get {/names} yes {
	view	1 1
    } {
}

api-handler get {/names/([0-9]+:idrr)} yes {
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
		return {503 {Database unavailable}}
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
		set msg [format "Internal Server Error (Netmagis version number '%s' unrecognized)" $libconf(version)]
		return [list 500 $msg]
	    }

	    # get schema version (from database)
	    if {[catch {dnsconfig get "schemaversion"} sver]} then {
		set sver ""
	    }

	    set msg ""
	    if {$sver eq ""} then {
		set msg [format "Internal Server Error (Database schema is too old. See http://netmagis.org/upgrade.html)" $version]
	    } elseif {$sver < $nver} then {
		set msg [format "Internal Server Error (Database schema is too old. See http://netmagis.org/upgrade.html)" $version]
	    } elseif {$sver > $nver} then {
		set msg [format {Internal Server Error (Database schema '%1$s' is not yet recognized by Netmagis %2$s)} $sver $version]
	    }

	    if {$msg ne ""} then {
		return [list 500 $msg]
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
		return {503 {Database unavailable}}
	    }

	}
    }

    return ""
}

thread-init
