set conf(static-dir)	/tmp

package require snit
package require Pgtcl

array set route {
    get {}
    post {}
    put {}
    delete {}
}

##############################################################################
# Thread initialisation
##############################################################################

proc thread-init {conffile} {
    global dbfd

    ::local-config create ::lc
    ::lc read $conffile

    ::db create ::dbdns
    ::dbdns init "dns" ::lc 3.0.foobar 		;# "%NMVERSION%"

    ::db create ::dbmac
    ::dbmac init "mac" ::lc ""

		#
		# Access to configuration parameters (stored in the database)
		#

#		dnsconfig setdb $dbfd($db)


    #
    # Prepare for DB connection
    #

    set dbfd(dns) "not connected"
    set dbfd(mac) "not connected"

    #
    # Create a global object for configuration parameters
    #

    # config ::dnsconfig
    # puts "READY [info procs route-*]"
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

		    try {
			::dbdns reconnect
			::dbmac reconnect
		    } on error msg {
			::scgiapp::scgi-error 503 $msg
		    }

		    ::scgiapp::set-body "YOU KNOW WHAT? I AM HAPPY..."

		    ::dbdns select "SELECT value FROM global.config WHERE
					    key = 'schemaversion'" tab {
			::scgiapp::set-body " WITH schemaversion = $tab(value)"
		    }

		    return

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
# Configuration interface
##############################################################################

snit::type ::local-config {
    variable conf

    method read {file} {
	if {[catch {set fd [open "$file" "r"]} msg]} then {
	    error "Cannot open configuration file '$file'"
	}
	set lineno 1
	set errors ""
	set conf [dict create]
	while {[gets $fd line] >= 0} {
	    regsub {#.*} $line {} line
	    regsub {\s*$} $line {} line
	    if {$line ne ""} then {
		if {[regexp {(\S+)\s+"(.*)"} $line m key val]} then {
		    dict set conf $key  $val
		} elseif {[regexp {(\S+)\s+(.*)} $line m key val]} then {
		    dict set conf $key $val
		} else {
		    append errors "$file($lineno): unrecognized line $line\n"
		}
	    }
	    incr lineno
	}
	close $fd
	if {$errors ne ""} then {
	    error $errors
	}
	dict set conf _conffile $file
	dict set conf _version "%NMVERSION%"
    }

    method get {key} {
	if {[dict exists $conf $key]} then {
	    set v [dict get $conf $key]
	} else {
	    set v ""
	}
	return $v
    }
}

##############################################################################
# Configuration parameters from database
##############################################################################

#
# Configuration parameters class
#
# This class is a simple way to access to configuration parameters
# of the Netmagis application.
#
# Methods:
# - setdb dbfd
#	set the database handle used to access parameters
# - class
#	returns all known classes
# - desc class-or-key
#	returns the description associated with class or key
# - keys [ class ]
#	returns all keys associed with the class, or all known keys
# - keytype key
#	returns type of a given key, under the format {string|bool|text|menu x}
#	X is present only for the "menu" type.
# - keyhelp key
#	returns the help message associated with a key
# - get key
#	returns the value associated with a key
# - set key val
#	set the value associated with a key and returns an empty string or
#	an error message.
#

snit::type ::config {
    # database object
    variable dbo ""

    # configuration parameter specification
    # {{class class-spec} {class class-spec} ...}
    # class = class name
    # class-spec = {{key ro/rw type} {key ro/rw type} ...}
    variable configspec {
	{general
	    {datefmt rw {string}}
	    {dayfmt rw {string}}
	    {authmethod rw {menu {{pgsql Internal} {ldap {LDAP}} {casldap CAS}}}}
	    {authexpire rw {string}}
	    {authtoklen rw {string}}
	    {wtmpexpire rw {string}}
	    {failloginthreshold1 rw {string}}
	    {faillogindelay1 rw {string}}
	    {failloginthreshold2 rw {string}}
	    {faillogindelay2 rw {string}}
	    {failipthreshold1 rw {string}}
	    {failipdelay1 rw {string}}
	    {failipthreshold2 rw {string}}
	    {failipdelay2 rw {string}}
	    {pageformat rw {menu {{a4 A4} {letter Letter}}} }
	    {schemaversion ro {string}}
	}
	{dns
	    {defuser rw {string}}
	}
	{dhcp
	    {dhcpdefdomain rw {string}}
	    {dhcpdefdnslist rw {string}}
	    {default_lease_time rw {string}}
	    {max_lease_time rw {string}}
	    {min_lease_time rw {string}}
	}
	{topo
	    {topoactive rw {bool}}
	    {defdomain rw {string}}
	    {topofrom rw {string}}
	    {topoto rw {string}}
	    {topographddelay rw {string}}
	    {toposendddelay rw {string}}
	    {topomaxstatus rw {string}}
	    {sensorexpire rw {string}}
	    {modeqexpire rw {string}}
	    {ifchangeexpire rw {string}}
	    {fullrancidmin rw {string}}
	    {fullrancidmax rw {string}}
	}
	{mac
	    {macactive rw {bool}}
	}
	{authcas
	    {casurl rw {string}}
	}
	{authldap
	    {ldapurl rw {string}}
	    {ldapbinddn rw {string}}
	    {ldapbindpw rw {string}}
	    {ldapbasedn rw {string}}
	    {ldapsearchlogin rw {string}}
	    {ldapattrlogin rw {string}}
	    {ldapattrname rw {string}}
	    {ldapattrgivenname rw {string}}
	    {ldapattrmail rw {string}}
	    {ldapattrphone rw {string}}
	    {ldapattrmobile rw {string}}
	    {ldapattrfax rw {string}}
	    {ldapattraddr rw {string}}
	}
	{authpgsql
	    {authpgminpwlen rw {string}}
	    {authpgmaxpwlen rw {string}}
	    {authpgmailfrom rw {string}}
	    {authpgmailreplyto rw {string}}
	    {authpgmailcc rw {string}}
	    {authpgmailbcc rw {string}}
	    {authpgmailsubject rw {string}}
	    {authpgmailbody rw {text}}
	    {authpggroupes rw {string}}
	}
    }

    #
    # Internal representation of parameter specification
    #
    # (class)			{<cl1> ... <cln>}
    # (class:<cl1>)		{<k1> ... <kn>}
    # (key:<k1>:type)		{string|bool|text|menu ...}
    # (key:<k1>:rw)		ro|rw
    #

    variable internal -array {}

    constructor {} {
	set internal(class) {}
	foreach class $configspec {

	    set classname [lindex $class 0]
	    lappend internal(class) $classname
	    set internal(class:$classname) {}

	    foreach key [lreplace $class 0 0] {
		lassign $key keyname keyrw keytype

		lappend internal(class:$classname) $keyname
		set internal(key:$keyname:type) $keytype
		set internal(key:$keyname:rw) $keyrw
	    }
	}
    }

    method setdb {dbo} {
	set dbo $dbo
    }

    # returns all classes
    method class {} {
	return $internal(class)
    }

    # returns textual description of the given class or key
    method desc {cork} {
	set r $cork
	if {[info exists internal(class:$cork)]} then {
	    set r [mc "cfg:$cork"]
	} elseif {[info exists internal(key:$cork:type)]} {
	    set r [mc "cfg:$cork:desc"]
	}
	return $r
    }

    # returns all keys associated with a class (default  : all classes)
    method keys {{class {}}} {
	if {[llength $class] == 0} then {
	    set class $internal(class)
	}
	set lk {}
	foreach c $class {
	    set lk [concat $lk $internal(class:$c)]
	}
	return $lk
    }

    # returns key rw/ro
    method keyrw {key} {
	set r ""
	if {[info exists internal(key:$key:rw)]} then {
	    set r $internal(key:$key:rw)
	}
	return $r
    }

    # returns key type
    method keytype {key} {
	set r ""
	if {[info exists internal(key:$key:type)]} then {
	    set r $internal(key:$key:type)
	}
	return $r
    }

    # returns key help
    method keyhelp {key} {
	set r $key
	if {[info exists internal(key:$key:type)]} then {
	    set r [mc "cfg:$key:help"]
	}
	return $r
    }

    # returns key value
    method get {key} {
	if {[info exists internal(key:$key:type)]} then {
	    set found 0
	    $dbo select "SELECT * FROM global.config WHERE key = '$key'" tab {
		set val $tab(value)
		set found 1
	    }
	    if {! $found} then {
		switch $internal(key:$key:type) {
		    string	{ set val "" }
		    bool	{ set val 0 }
		    set text	{ set val "" }
		    set menu	{ set val "" }
		    default	{ set val "type unknown" }
		}
	    }
	} else {
	    error [mc "Unknown configuration key '%s'" $key]
	}
	return $val
    }

    # set key value
    # returns empty string if ok, or an error message
    method set {key val} {
	if {[info exists internal(key:$key:rw)]} then {
	    if {$internal(key:$key:rw) eq "rw"} then {
		set r ""
		set k [pg_quote $key]
		set sql "DELETE FROM global.config WHERE key = $k"
		if {[$dbo exec $sql msg]} then {
		    set v [pg_quote $val]
		    set sql "INSERT INTO global.config (key, value)
		    				VALUES ($k, $v)"
		    if {! [::pgsql::execsql $db $sql msg]} then {
			set r [mc {Cannot set key '%1$s' to '%2$s': %3$s} $key $val $msg]
		    }
		} else {
		    set r [mc {Cannot fetch key '%1$s': %2$s} $key $msg]
		}
	    } else {
		set r [mc {Cannot modify read-only key '%s'} $key]
	    }
	} else {
	    error [mc "Unknown configuration key '%s'" $key]
	}

	return $r
    }
}


##############################################################################
# PostgreSQL interface
##############################################################################

snit::type ::db {
    # Database prefix in configuration file
    variable dbprefix

    # Access to local configuration file
    variable lc

    # Database handler (result of pg_connect)
    variable dbfd "not connected"

    # Database handler (result of pg_connect)
    variable dbversion

    # prefix: "dns" or "mac" (according to local configuration file)
    # confobj: access to the local configuration file
    # versioncheck: version number (such as 3.0.5beta1) or ""

    method init {prefix confobj versioncheck} {
	set dbprefix $prefix
	set lc $confobj
	set dbversion $versioncheck
    }

    method disconnect {} {
	catch {pg_disconnect $dbfd}
	set dbfd "not connected"
    }

    method reconnect {} {
	if {$dbfd ne "not connected"} then {
	    return {}
	}

	#
	# Get conninfo string
	#
	set conninfo {}
	foreach f {{host host} {port port} {dbname name}
			    {user user} {password password}} {
	    lassign $f connkey suffix
	    set v [$lc get "${dbprefix}db${suffix}"]
	    regsub {['\\]} $v {\\&} v
	    lappend conninfo "$connkey='$v'"
	}
	set conninfo [join $conninfo " "]

	puts "conninfo=$conninfo"

	try {
	    set dbfd [pg_connect -conninfo $conninfo]
	} on error msg {
	    error "Database $dbprefix unavailable"
	}

#		#
#		# Log initialization
#		#
#
#		set log [::webapp::log create %AUTO% \
#					    -subsys netmagis \
#					    -method opened-postgresql \
#					    -medium [list "db" $dbfd($db) table global.log] \
#				]

    }

    method select {sql tabname script} {
	try {
	    uplevel 1 [list pg_execute -array $tabname $dbfd $sql $script]
	} trap {NONE} {msg err} {
	    # Pgtcl 1.9 returns errorcode == NONE
	    set errinfo [dict get $err -errorinfo]
	    if {[regexp "^PGRES_FATAL_ERROR" $errinfo]} then {
		# reset db handle
		set info [pg_dbinfo status $dbfd]
		if {$info ne "connection_ok"} then {
		    $self disconnect
		}
		error $msg
	    } else {
		# it is not a Pgtcl error
		error $msg $errinfo NONE
	    }
	}
    }
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

try {
    thread-init $conffile
} on error msg {
    puts stderr $msg
    exit 1
}
