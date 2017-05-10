#
# This file provides two packages to build a SCGI-based application
#
# It is in fact divided into 2 different packages:
# - for the server: this package contains only one function to
#	start the multi-threaded SCGI server
# - for the app: this package is implicitely loaded into each thread
#	started by the server (see thrscript)
#

package require Tcl 8.6
package require Thread 2.7

package provide scgi 0.1

namespace eval ::scgi:: {
    namespace export start test-mode

    ###########################################################################
    # Server connection and thread pool management
    ###########################################################################

    # thread pool id
    variable tpid

    # server configuration
    variable serconf
    array set serconf {
	-minworkers 2
	-maxworkers 4
	-idletime 30
	-myaddr 0.0.0.0
	-myport 8080
	-debug 1
    }


    #
    # Start a multi-threaded server to handle SCGI requests from the
    # HTTP proxy
    #
    # Usage:
    #	::scgi::start [options] init-script handle-function
    #	with standard options:
    #		-minworkers: minimum number of threads in thread pool
    #		-maxworkers: maximum number of threads in thread pool
    #		-idletime: idle-time for worker threads
    #		-myaddr: address to listen to connections
    #		-myport: port number to listen to connections
    #		-debug: get verbose error message
    #
    #	and arguments:
    #	- init-script: script to call in each worker thread. This script
    #		is called after creating the client scgi package. Since
    #		each thread is created with a default Tcl interpreter
    #		(thus containing only the initial set of Tcl commands),
    #		the init-script should source a file containing the
    #		SCGI application itself.
    #	- handle-function: this is the name of a function inside the
    #		the SCGI application (thus in a worker thread) to
    #		handle a SCGI request from the HTTP proxy. This function
    #		is called with the following arguments:
    #
    #		XXXXXXXXXXXXXXXXX
    #

    proc start args {
	variable tpid
	variable serconf

	#
	# Get default parameters
	#

	array set p [array get serconf]

	#
	# Argument analysis
	#

	while {[llength $args] > 0} {
	    set a [lindex $args 0]
	    switch -glob -- $a {
		-- {
		    set args [lreplace $args 0 0]
		    break
		}
		-* {
		    if {[info exists p($a)]} then {
			set p($a) [lindex $args 1]
			set args [lreplace $args 0 1]
		    } else {
			error "invalid option '$a'. Should be 'server [array get serconf]'"
		    }
		}
		* {
		    break
		}
	    }
	}

	if {[llength $args] != 2} then {
	    error "invalid args: should be init-script handle-request"
	}

	lassign $args initscript handlereq

	variable thrscript

	set tpid [tpool::create \
			-minworkers $p(-minworkers) \
			-maxworkers $p(-maxworkers) \
			-idletime $p(-idletime) \
			-initcmd "$thrscript ;
				set ::scgi::handlefn $handlereq ;
				set ::scgi::debug $p(-debug) ;
				$initscript" \
		    ]

	socket \
	    -server [namespace code server-connect-hack] \
	    -myaddr $p(-myaddr) \
	    $p(-myport)

	vwait forever
    }

    #
    # Activates the scgi test-mode.
    # This procedure loads the subpart scgi module (containing the accept
    # procedure) and the test subpart which overloads the accept proc
    # in order to be called directly from a test environment
    #

    proc test-mode {dbg initscript hdlfn} {
	variable thrscript
	variable tstscript

	uplevel \#0 $thrscript
	uplevel \#0 $tstscript
	set ::scgi::handlefn $hdlfn
	set ::scgi::debug $dbg
	uplevel \#0 $initscript
    }

    proc server-connect-hack {sock host port} {
	after 0 [namespace code [list server-connect $sock $host $port]]
    }

    proc server-connect {sock host port} {
	variable tpid

	::thread::detach $sock
	set jid [tpool::post $tpid "::scgi::accept $sock $host $port"]
    }

    ###########################################################################
    # Connection handling
    #
    # Sub-package used for connections handled by each individual thread
    ###########################################################################

    variable thrscript {
	package require Thread 2.7
	package require ncgi 1.4
	package require ip 1.3
	package require json 1.1
	package require json::write 1.0

	namespace eval ::scgi:: {
	    namespace export accept \
			    get-header get-body-json \
			    set-header set-body set-json \
			    get-cookie \
			    set-cookie del-cookie \
			    check-json-value import-json-object \
			    serror \
			    output

	    #
	    # Name of the function (called in accept) to handle requests
	    # This variable is used in the ::scgi::start function.
	    #

	    variable handlefn

	    #
	    # Generate a Tcl stack trace in the message sent back
	    #

	    variable debug

	    #
	    # Global state associated with the current request
	    # - sock: socket to the client
	    # - reqhdrs: request headers
	    # - errcode: html error code, in case of error
	    # - rephdrs: reply headers
	    # - repbody: reply body
	    # - repbin: true if body is a binary format
	    # - reqcook: dict of received cookies
	    # - repcook: dict of cookies to be sent
	    # - done: boolean if output already done
	    #

	    variable state
	    array set state {
		sock {}
		reqhdrs {}
		errcode {}
		rephdrs {}
		repbody {}
		repbin {}
		reqcook {}
		repcook {}
		done {}
	    }

	    #
	    # This function is called from the server thread
	    # by the ::scgi::server-connect function,
	    # indirectly by the tpool::post command.
	    # 

	    proc accept {sock host port} {
		variable handlefn
		variable debug
		variable state

		#
		# Get input socket
		#

		thread::attach $sock

		#
		# Reset global state
		#

		foreach k [array names state] {
		    set state($k) ""
		}
		set state(sock) $sock
		set state(done) false
		set state(errcode) 500
		set state(repbin) false

		try {
		    lassign [scgi-read $sock] state(reqhdrs) body

		    # Uncomment this line to display request headers
		    # array set x $state(reqhdrs) ; parray x ; puts stdout ""

		    set parm [parse-param $state(reqhdrs) $body]
		    parse-cookies
		    set uri [get-header SCRIPT_NAME "/"]
		    # normalize URI (apache does not dot it)
		    regsub -all {/+} $uri {/} uri
		    set meth [string tolower [get-header REQUEST_METHOD "get"]]

		    $handlefn $uri $meth $parm

		} on error msg {

		    if {$state(errcode) == 500} then {
			set-header Status "500 Internal server error" true
			#### XXX : KEEP A LOG of $msg BEFORE MODIFICATION
			set msg "Internal server error"
		    } else {
			set-header Status "$state(errcode) $msg" true
		    }

		    if {$debug} then {
			global errorInfo
			set-body "<html>\n"
			set-body "<h1>$state(errcode) $msg</h1>\n"
			set-body "<pre>$errorInfo</pre>\n"
			set-body "</html>\n"
		    } else {
			set-body "<pre>$state(errcode) $msg</pre>"
		    }
		}

		try {
		    output
		    close $sock
		}
	    }

	    #
	    # Decode input according to the SCGI protocol
	    # Returns a 2-element list: {<hdrs> <body>}
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

	    proc scgi-read {sock} {
		fconfigure $sock -translation {binary crlf}

		set len ""
		# Decode the length of the netstring: "70:..."
		while {1} {
		    set c [read $sock 1]
		    if {$c eq ""} then {
			error "Invalid netstring length in SCGI protocol"
		    }
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
		    error "Invalid final comma in SCGI protocol"
		}

		# Netstring contains headers. Decode them (without final \0)
		set hdrs [lrange [split $data \0] 0 end-1]

		# Get content_length header
		set clen [dget $hdrs CONTENT_LENGTH 0]

		set body [read $sock $clen]

		return [list $hdrs $body]
	    }

	    proc serror {code reason} {
		variable state

		set state(errcode) $code
		error $reason
	    }

	    proc get-header {key {defval {}}} {
		variable state
		return [dget $state(reqhdrs) $key $defval]
	    }

	    proc get-body-json {parm} {
		set btype [dict get $parm "_bodytype"]
		if {$btype ne "json"} then {
		    serror 404 "Invalid type (JSON expected)"
		}
		return [dict get $parm "_body"]
	    }

	    #
	    # Check json value (already processed by json::json2dict)
	    # against a specification
	    # Raise an error if value does not conform to the specification.
	    #
	    # Specification grammar (start symbol = <type>):
	    #   <type> ::= { type <simple> <optreq> }
	    #   	 | { array <type> <optreq> }
	    #   	 | { object { <member>+ } <optreq> }
	    #   <simple> ::= int | float | inet | inet4 | inet6
	    #              | string | bool
	    #   <member> ::= { <name> <type> <optreq> }
	    #   <optreq> ::= req | opt <tclvalue>
	    #   <tclvalue> ::= <any Tcl value which can result from json2dict>
	    #   <name> ::= <any string suitable for a Tcl variable name>
	    #   
	    # Exemple 1:
	    #   { type int req }
	    #   => 5		ok
	    #	=> null		not ok
	    # Example 2:
	    #	{ type bool opt false}
	    #	=> true		ok
	    #	=> null		ok (default: false)
	    #	=> 5		not ok
	    # Example 3:
	    #	{ array {type int req} req}
	    #	=> [1, 2, 3]	ok
	    #	=> []		ok
	    #	=> [1, null, 3]	not ok (int cannot be null)
	    #	=> null		not ok
	    #	=> 1		not ok
	    # Example 4:
	    #	{ object { {x {type int req} req}
	    #		   {y {type bool req} opt false}
	    #		 } req
	    #	   }
	    # => {"x": 1, "y": false}	ok
	    # => {"x": 1}		ok (default: "y": false)
	    # => {"x": 1, "y": null}	not ok (y value is required)
	    # Example 5:
	    #   { object { {a {type string req} req}
	    #		   {b {type int opt -1} opt -1}
	    #		 } req
	    #	      }
	    #	=> {"a": "foo", "b": 1}		ok
	    #	=> {"a": "foo", "b": null}	ok (default: "b": -1)
	    #	=> {"a": "foo"}			ok (default: "b": -1)
	    # Example 6:
	    #	{ object {
	    #	    {a {type int req} req}
	    #	    {b {type bool req} opt 0}
	    #	    {c {type string req} req}
	    #	    {d {object {
	    #		         {x {type int req} req}
	    #		         {y {type int req} opt 6}
	    #		       } opt {x -1 y 6}
	    #		   }
	    #		}
	    #	    {e {array {type int req} opt {1 2 3}}}
	    #	    {f {array {object {
	    #			    	{g {type int} req}
	    #			    	{h {type int} req}
	    #			     } opt {g 1 h 1}
	    #			}
	    #		    } opt {{g 1 h 1} {g 2 h 2}}
	    #		}
	    #	    } req }
	    #	=> {... "d": null ...}			ok
	    #	=> {... "d": {"x": 1} ...}		ok
	    #	=> {... "d": {"x": 1, "y": null} ...}	not ok
	    #	=> {... "e": null ...}			ok (default: {1 2 3})
	    #	=> {... "e": [] ...}			ok (value: {})
	    #	=> {... "e": [1, 2, null, ...] ...}	not ok (int != null)
	    #
	    # Limitations compared to JSON specifications:
	    # - elements must have same type in an array
	    # - JSON 'null' values cannot be detected in string types
	    #

	    proc check-json-value {val spec} {
		try {
		    set v [check-json-internal $val $spec ""]
		} on error {msg} {
		    # unhandled error
		    serror 404 $msg
		} on 10 {msg} {
		    # invalid spec (from application)
		    serror 500 $msg
		} on 11 {msg} {
		    # invalid JSON value from user
		    serror 404 $msg
		}
		return $v
	    }

	    proc error-spec {msg ctxt} {
		if {$ctxt eq ""} then {
		    set ctxt "at top-level"
		} else {
		    set ctxt "in $ctxt"
		}
		return -code 10 "Internal error: invalid JSON spec ($msg) $ctxt"
	    }

	    proc error-val {val msg ctxt} {
		if {[string length $val] > 8} then {
		    set val [string range $val 0 7]
		    append val "..."
		}
		if {$ctxt eq ""} then {
		    set ctxt "at top-level"
		} else {
		    set ctxt "in $ctxt"
		}
		return -code 11 "Invalid JSON value '$val' ($msg) $ctxt"
	    }

	    proc check-json-internal {val spec ctxt} {
		lassign $spec type attr optreq defval

		switch -- $optreq {
		    opt { set opt 1 }
		    req { set opt 0 }
		    default {
			error-spec "optreq '$optreq' should be opt|req" $ctxt
		    }
		}

		switch -- $type {
		    type {
			set v [check-json-simple $val $attr $opt $defval $ctxt]
		    }
		    array {
			set v [check-json-array $val $attr $opt $defval "$ctxt/array"]
		    }
		    object {
			set v [check-json-object $val $attr $opt $defval "$ctxt/object"]
		    }
		    default {
			error-spec "type '$type' should be type|array|object" $ctxt
		    }
		}

		return $v
	    }

	    #
	    # Internal procedure: check value against a single type spec
	    # and return new value (changed if default value is used)
	    #
	    # val: JSON value
	    # type: int|float|inet|...
	    # opt: 1 if optional values are authorized
	    # defval: default value if opt==1
	    # ctxt: context for error messages
	    #

	    proc check-json-simple {val type opt defval ctxt} {
		if {$val eq "null" && $type ne "string"} then {
		    if {$opt} then {
			return $defval
		    } else {
			error-val $val "cannot be null" $ctxt
		    }
		}

		switch -- $type {
		    int {
			if {! [regexp {^-?[0-9]+$} $val]} then {
			    error-val $val "not an integer" $ctxt
			}
		    }
		    float {
			if {[catch {expr 0+$val}]} then {
			    error-val $val "not a number" $ctxt
			}
		    }
		    inet4 {
			if {[::ip::version $val] != 4} then {
			    error-val $val "not an IPv4 address" $ctxt
			}
		    }
		    inet6 {
			if {[::ip::version $val] != 6} then {
			    error-val $val "not an IPv6 address" $ctxt
			}
		    }
		    inet {
			if {! ([::ip::version $val] in {4 6})} then {
			    error-val $val "not an IP address" $ctxt
			}
		    }
		    string {
			# nothing
		    }
		    bool {
			if {$val ne "true" && $val ne "false"} then {
			    append ctxt "$val"
			    error-val $val "not a boolean" $ctxt
			}
		    }
		    default {
			error-spec "type '$type' should be int|float|..." $ctxt
		    }
		}

		return $val
	    }

	    proc check-json-array {val type opt defval ctxt} {
		if {$val eq "null"} then {
		    if {$opt} then {
			set v $defval
		    } else {
			error-val $val "array required" $ctxt
		    }
		} else {
		    set v {}
		    foreach e $val {
			lappend v [check-json-internal $e $type $ctxt]
		    }
		}
		return $v
	    }

	    proc check-json-object {val members opt defval ctxt} {
		if {$val eq "null"} then {
		    if {$opt} then {
			set v $defval
		    } else {
			error-val $val "object required" $ctxt
		    }
		} else {
		    # keep a copy of old dict for error messages
		    set oldval $val
		    # create a new directory to return the value
		    set v [dict create]
		    # traverse the list of members
		    foreach m $members {
			lassign $m key type optreq defval
			if {[dict exists $val $key]} then {
			    set nv [dict get $val $key]
			    set nv [check-json-internal $nv $type "$ctxt/$key"]
			    dict set v $key $nv
			    dict unset val $key
			} else {
			    if {$optreq eq "opt"} then {
				dict set v $key $defval
			    } else {
				error-val $oldval "key '$key' required" $ctxt
			    }
			}
		    }
		    # check if unknown members are still in the old dict
		    set dk [dict keys $val]
		    if {[llength $dk] > 0} then {
			set dk [join $dk "', '"]
			set dk "'$dk'"
			error-val $oldval "unknown key(s) $dk" $ctxt
		    }
		}
		return $v
	    }

	    #
	    # Import a json object (in fact, a Tcl dict) into Tcl variables
	    # To be safe, check-json-value should be called before to
	    # assert that all keys are legal.
	    #

	    proc import-json-object {jdict} {
		dict for {k v} $jdict {
		    uplevel [list set $k $v]
		}
	    }

	    #
	    # Set header for future return
	    # key: header name
	    # val: header value
	    # replace: true (default) if header should replace existing
	    #	header with the same name or false if header should be
	    #	added to other headers with the same name.
	    #

	    proc set-header {key val {replace {true}}} {
		variable state

		set key [string totitle $key]
		set val [string trim $val]

		if {$replace || ![dict exists $state(rephdrs) $key]} then {
		    dict set state(rephdrs) $key $val
		}
	    }

	    # Warning: get-cookie gets a cookie value as sent by the
	    # client, do not confuse with {set,del}-cookie which set
	    # the cookie to be *returned* to the the client

	    proc get-cookie {name} {
		variable state

		return [dget $state(reqcook) $name]
	    }

	    # Set-cookie on reply
	    # Input:
	    #   - name: cookie name (printable ascii chars, excluding [,; =])
	    #   - val: cookie value (printable ascii chars, excluding [,; ])
	    #   - expire: unix timestamp, or 0 if no expiration date
	    #   - path:
	    #   - domain:
	    #   - secure:
	    #   - httponly:
	    # Output: none
	    #
	    # History:
	    #   2014/03/28 : pda/jean : design

	    proc set-cookie {name val expire path domain secure httponly} {
		variable state

		set l {}

		lappend l "$name=$val"
		if {$expire > 0} then {
		    # Wdy, DD Mon YYYY HH:MM:SS GMT
		    set max [clock format $expire -gmt yes -format "%a, %d %b %Y %T GMT"]
		    lappend "Expires=$max"
		}
		if {$path ne ""} then {
		    lappend "Path=$path"
		}
		if {$domain ne ""} then {
		    lappend "Domain=$domain"
		}
		if {$secure} then {
		    lappend "Secure"
		}
		if {$httponly} then {
		    lappend "HttpOnly"
		}

		dict set state(repcook) $name [join $l "; "]
	    }

	    proc del-cookie {name} {
		set-cookie $name "" 1 "" "" 0 0
	    }

	    proc set-body {data {binary false}} {
		variable state

		set state(repbin) $binary
		append state(repbody) $data
	    }

	    proc set-json {dict} {
		set-header Content-Type application/json
		set-body [tcl2json $dict]
	    }

	    #
	    # See http://rosettacode.org/wiki/JSON#Tcl
	    #

	    proc tcl2json {value} {
		# Guess the type of the value; deep *UNSUPPORTED* magic!
		regexp {^value is a (.*?) with a refcount} \
		    [::tcl::unsupported::representation $value] -> type
	     
		switch $type {
		    string {
			return [json::write string $value]
		    }
		    dict {
			return [json::write object {*}[
			    dict map {k v} $value {tcl2json $v}]]
		    }
		    list {
			return [json::write array {*}[lmap v $value {tcl2json $v}]]
		    }
		    int - double {
			return [expr {$value}]
		    }
		    booleanString {
			return [expr {$value ? "true" : "false"}]
		    }
		    default {
			# Some other type; do some guessing...
			if {$value eq "null"} {
			    # Tcl has *no* null value at all; empty strings are semantically
			    # different and absent variables aren't values. So cheat!
			    return $value
			} elseif {[string is integer -strict $value]} {
			    return [expr {$value}]
			} elseif {[string is double -strict $value]} {
			    return [expr {$value}]
			} elseif {[string is boolean -strict $value]} {
			    return [expr {$value ? "true" : "false"}]
			}
			return [json::write string $value]
		    }
		}
	    }

	    proc output {} {
		variable state

		if {$state(done)} then {
		    return
		}

		fconfigure $state(sock) -encoding utf-8 -translation crlf

		if {$state(repbin)} then {
		    set clen [string length $state(repbody)]
		} else {
		    set u [encoding convertto utf-8 $state(repbody)]
		    set clen [string length $u]
		}

		set-header Status "200" false
		set-header Content-Type "text/html; charset=utf-8" false
		set-header Content-Length $clen

		# output registered cookies
		dict for {name val} $state(repcook) {
		    set-header Set-Cookie $val false
		}

		foreach {k v} $state(rephdrs) {
		    puts $state(sock) "$k: $v"
		}
		puts $state(sock) ""
		flush $state(sock)

		if {$state(repbin)} then {
		    fconfigure $state(sock) -translation binary
		} else {
		    fconfigure $state(sock) -encoding utf-8 -translation lf
		}
		puts -nonewline $state(sock) $state(repbody)

		catch {close $state(sock)}

		set state(done) true
	    }

	    #
	    # Extract parameters
	    # - hdrs: the request headers
	    # - body: the request body, as a byte string
	    #
	    # Returns dictionary
	    #

	    proc parse-param {hdrs body} {
		variable state

		set parm [dict create]

		set query [dget $hdrs QUERY_STRING]
		set parm [keyval $parm [split $query "&"]]

		if {$body eq ""} then {
		    dict set parm _bodytype ""
		} else {
		    lassign [content-type $hdrs] ctype charset
		    switch -- $ctype {
			{application/x-www-form-urlencoded} {
			    dict set parm _bodytype ""
			    set parm [keyval $parm [split $body "&"]]
			}
			{application/json} {
			    dict set parm _bodytype "json"
			    dict set parm _body $body
			    dict set parm _bodydict [::json::json2dict $body]
			}
			default {
			    dict set parm _bodytype $ctype
			    dict set parm _body $body
			}
		    }
		}

		return $parm
	    }

	    #
	    # Import parameters from a dictionary into a specific namespace
	    # Use a fully qualified namespace (e.g.: ::foo for example)
	    # or variables in the uplevel scope.
	    #

	    proc import-param {dict {ns {}}} {
		if {$ns ne ""} then {
		    if {[namespace exists $ns]} then {
			namespace delete $ns
		    }
		    dict for {var val} $dict {
			namespace eval $ns [list variable $var $val]
		    }
		} else {
		    dict for {var val} $dict {
			uplevel [list set $var $val]
		    }
		}
	    }

	    #
	    # Extract individual parameters
	    # - parm: dictionary containing
	    #

	    proc keyval {parm lkv} {
		foreach kv $lkv {
		    if {[regexp {^([^=]+)=(.*)$} $kv foo key val]} then {
			set key [::ncgi::decode $key]
			set val [::ncgi::decode $val]
			dict lappend parm $key $val
		    }
		}
		return $parm
	    }

	    #
	    # Extract content-type from headers and returns
	    # a 2-element list: {<content-type> <charset>}
	    # Example : {application/x-www-form-urlencoded utf-8}
	    #

	    proc content-type {hdrs} {
		set h [dget $hdrs CONTENT_TYPE]
		set charset "utf-8"
		switch -regexp -matchvar m -- $h {
		    {^([^;]+)$} {
			set ctype [lindex $m 1]
		    }
		    {^([^;\s]+)\s*;\s*(.*)$} {
			set ctype [lindex $m 1]
			set parm [lindex $m 2]
			foreach p [split $parm ";"] {
			    lassign [split $p "="] k v
			    if {$k eq "charset"} then {
				set charset $v
			    }
			}
		    }
		    default {
			set ctype $h
		    }
		}
		return [list $ctype $charset]
	    }

	    #
	    # Parse cookies
	    # Returns a dictionary
	    #

	    proc parse-cookies {} {
		variable state

		set cookie [dict create]
		set ck [get-header HTTP_COOKIE]
		foreach kv [split $ck ";"] {
		    if {[regexp {^\s*([^=]+)=(.*)} $kv foo k v]} then {
			dict set cookie $k $v
		    }
		}
		set state(reqcook) $cookie
	    }

	    #
	    # Parse accept-language header and choose the
	    # appropriate language among those listed in the
	    # "avail" list
	    # accept-language is provided by the
	    # HTTP_ACCEPT_LANGUAGE SCGI header, whose value
	    # is a string under the RFC 2616 format
	    #	lang [;q=\d+], ...
	    #

	    proc get-locale {avail} {
		set accepted [string tolower [get-header HTTP_ACCEPT_LANGUAGE]]
		if {$accepted ne ""} then {
		    #
		    # Parse accept-language string and build two arrays:
		    # tabl($quality) {list of accepted languages}
		    # tabq($lang) $quality
		    #
		    foreach a [split $accepted ","] {
			regsub -all {\s+} $a {} a
			set s [split $a ";"]
			set lang [lindex $s 0]
			set q 1
			foreach param [lreplace $s 0 0] {
			    regexp {^q=([.0-9]+)$} $param foo q
			}
			lappend tabl($q) $lang
			set tabq($lang) $q
		    }
		    #
		    # If there is a sub-language-tag, add the
		    # language-tag if it does not exist.
		    # There may be any number of sub-tags (e.g
		    # en-us-nyc-manhattan)
		    #
		    foreach l [array names tabq] {
			set q $tabq($l)
			set ll [split $l "-"]
			while {[llength $ll] > 1} {
			    set ll [lreplace $ll end end]
			    set llp [join $ll "-"]
			    if {! [info exists tabq($llp)]} then {
				lappend tabl($q) $llp
				set tabq($llp) $q
			    }
			}
		    }

		    #
		    # Filter accepted languages by available languages
		    # using quality factor.
		    #
		    set avail [string tolower $avail]
		    set locale "C"
		    foreach q [lsort -real -decreasing [array names tabl]] {
			foreach l $tabl($q) {
			    if {[lsearch -exact $avail $l] != -1} then {
				set locale $l
				break
			    }
			}
			if {$locale ne "C"} then {
			    break
			}
		    }
		} else {
		    set locale "en"
		}
		return $locale
	    }

	    #
	    # Get a value from a dictionary, using a default value
	    # if key is not found.
	    #

	    proc dget {dict key {defval {}}} {
		if {[dict exists $dict $key]} then {
		    set v [dict get $dict $key]
		} else {
		    set v $defval
		}
		return $v
	    }
	}
    }

    ###########################################################################
    # Test sub-part
    #
    # Sub-package which overloads some functions of the connection sub-package
    ###########################################################################

    variable tstscript {
	namespace eval ::scgi:: {
	    namespace export simulcall output

	    #
	    # This function is called directly from the test program.
	    # It initializes a pseudo-environment compatible with the
	    # true scgi.tcl (see variable state) in order to re-use
	    # original scgi.tcl functions, and it calls the specified
	    # worker function.
	    # 

	    proc simulcall {meth uri headers cookies body} {
		variable handlefn
		variable debug
		variable state

		#
		# Reset global state
		#

		foreach k [array names state] {
		    set state($k) ""
		}
		set state(done) false
		set state(errcode) 500
		set state(repbin) false

		try {
		    set state(reqhdrs) $headers
		    set parm [parse-param $state(reqhdrs) $body]
		    set state(reqcook) $cookies

		    # normalize URI (apache does not dot it)
		    regsub -all {/+} $uri {/} uri

		    $handlefn $uri $meth $parm

		} on error msg {

		    if {$state(errcode) == 500} then {
			set-header Status "500 Internal server error" true
			#### XXX : KEEP A LOG of $msg BEFORE MODIFICATION
			set msg "Internal server error"
		    } else {
			set-header Status "$state(errcode) $msg" true
		    }

		    if {$debug} then {
			global errorInfo
			set-body "<html>\n"
			set-body "<h1>$state(errcode) $msg</h1>\n"
			set-body "<pre>$errorInfo</pre>\n"
			set-body "</html>\n"
		    } else {
			set-body "<pre>$state(errcode) $msg</pre>"
		    }
		}

		try {
		    output
		}

		#
		# Adapt result to test needs
		#

		set stcode 500
		set stmsg ""
		set ct ""
		foreach {k v} $state(rephdrs) {
		    switch [string tolower $k] {
			status {
			    regexp {^(\d+)\s*(.*)} $v foo stcode stmsg
			}
			content-type { set ct $v }
		    }
		}

		return [list $stcode $stmsg $ct $state(repbody)]
	    }

	    proc output {} {
		variable state

		if {$state(done)} then {
		    return
		}

		set-header Status "200" false
		set-header Content-Type "text/html; charset=utf-8" false

		# output registered cookies
		dict for {name val} $state(repcook) {
		    set-header Set-Cookie $val false
		}

		set state(done) true
	    }
	}
    }
}
