package require Tcl 8.6
package require ip

package provide nmjson 0.2

#
# This package provides an enhanced Tcl representation for JSON
# objects. A NMJson object is one of:
#
#	{ ... } -> {object <dict>}
#	[ ... ] -> {array <list>}
#	true    -> {bool <true-or-false>}
#	123	-> {number <val>}
#	"foo"   -> {string <str>}
#	null	-> {null}
#
# Some parts of this package are based upon the JSON tokenizer from the
# Jim Tcl HTTP server: https://github.com/dbohdan/jimhttp
#

namespace eval ::nmjson {
    namespace export str2nmj nmj2str nmjeq \
			nmjtype nmjval \
			check-spec import-object

    ###################################################
    # Get the string (regular JSON representation) from
    # a NMJson internal representation

    proc nmj2str {json} {
	lassign $json type val
	switch $type {
	    null {
		set s null
	    }
	    bool {
		set s false
		if {$val} then {
		    set s true
		}
	    }
	    number {
		set s $val
	    }
	    string {
		set s [string map {\\ \\\\ \" \\" / \\/ \n \\n \t \\t \b \\b \f \\f \r \\r} $val]
		set s "\"$s\""
	    }
	    object {
		set first 1
		set s "\{"
		dict for {k v} $val {
		    if {! $first} then {
			append s ", "
		    }
		    append s "\"$k\":"
		    append s [nmj2str $v]
		    set first 0
		}
		append s "\}"
	    }
	    array {
		set first 1
		set s "\["
		foreach v $val {
		    if {! $first} then {
			append s ", "
		    }
		    append s [nmj2str $v]
		    set first 0
		}
		append s "\]"
	    }
	    default {
		error "Invalid NMJSON type"
	    }
	}
	return $s
    }

    ###################################################
    # Get components of a NMJson object
    #
    # nmjtype:
    #	{ ... } -> object
    #	[ ... ] -> array
    #	true    -> bool
    #	123	-> number
    #	"foo"   -> string
    #	null	-> null
    #
    # nmjval:
    #	{ ... } -> <dict>
    #	[ ... ] -> <list>
    #	true    -> <true-or-false>
    #	123	-> <val>
    #	"foo"   -> <str>
    #	null	-> {}

    proc nmjtype {j} {
	return [lindex $j 0]
    }

    proc nmjval {j} {
	return [lindex $j 1]
    }

    ###################################################
    # Compare two NMJson objects

    proc nmjeq {j1 j2} {
	set r 0
	lassign $j1 type1 val1
	lassign $j2 type2 val2
	if {$type1 eq $type2} then {
	    switch $type1 {
		null {
		    set r 1
		}
		bool {
		    if {($val1 && $val2) || (! $val1 && ! $val2)} then {
			set r 1
		    }
		}
		number {
		    set r [expr {$val1 == $val2}]
		}
		string {
		    set r [expr {$val1 eq $val2}]
		}
		object {
		    if {[dict size $val1] == [dict size $val2]} then {
			set r 1
			dict for {k1 v1} $val1 {
			    if {[dict exists $val2 $k1]} then {
				set v2 [dict get $val2 $k1]
				set r [jsoneq $v1 $v2]
				if {! $r} then {
				    break
				}
			    } else {
				set r 0
				break
			    }
			}
		    }
		}
		array {
		    if {[llength $val1] == [llength $val2]} then {
			set r 1
			foreach v1 $val1 v2 $val2 {
			    set r [jsoneq $v1 $v2]
			    if {! $r} then {
				break
			    }
			}
		    }
		}
		default {
		    error "Invalid NMJSON type"
		}
	    }
	}
	return $r
    }

    ###################################################
    # Import a NMJson object into Tcl variables according to their
    # keys. With valonly parameter, only import values (and not
    # complete individual NMJson values)
    # 
    # To be safe, object keys should be checked before (see check-spec)
    #

    proc import-object {o valonly} {
	set jt [nmjtype $o]
	set jv [nmjval  $o]
	if {$jt ne "object"} then {
	    error "Invalid JSON object"
	}
	dict for {k v} $jv {
	    if {$valonly} then {
		set v [nmjval $v]
	    }
	    uplevel [list set $k $v]
	}
    }

    ###################################################
    # Check a NMJson value against a specification
    #
    # Returns a list:
    #	{true <new NMJson value>}
    #	{false <error message>}
    #
    # Specification grammar (start symbol = <type>):
    #   <type> ::= { type <simple> <optreq> }
    #   	 | { array <type> <optreq> }
    #   	 | { object { <member>+ } <optreq> }
    #   <simple> ::= int | float | inet | inet4 | inet6
    #              | string | bool
    #   <member> ::= { <name> <type> <optreq> }
    #   <optreq> ::= req | opt <nmjson-value>
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

    proc check-spec {j spec} {
	try {
	    set v [_check-spec-internal $j $spec ""]
	    set r [list true $v]
	} on error {msg} {
	    # unhandled error
	    set r [list false $msg]
	} on 10 {msg} {
	    # invalid spec (from application)
	    set r [list false $msg]
	} on 11 {msg} {
	    # invalid JSON value from user
	    set r [list false $msg]
	}
	return $r
    }

    proc _error-spec {msg ctxt} {
	if {$ctxt eq ""} then {
	    set ctxt "at top-level"
	} else {
	    set ctxt "in $ctxt"
	}
	return -code 10 "Internal error: invalid JSON spec ($msg) $ctxt"
    }

    proc _error-val {nmj msg ctxt} {
	set j [nmj2str $nmj]
	if {[string length $j] > 8} then {
	    set j [string range $j 0 7]
	    append j "..."
	}
	if {$ctxt eq ""} then {
	    set ctxt "at top-level"
	} else {
	    set ctxt "in $ctxt"
	}
	return -code 11 "Invalid JSON value '$j' ($msg) $ctxt"
    }

    proc _check-spec-internal {j spec ctxt} {
	lassign $spec type attr optreq defval

	switch -- $optreq {
	    opt { set opt 1 }
	    req { set opt 0 }
	    default {
		_error-spec "optreq '$optreq' should be opt|req" $ctxt
	    }
	}

	switch -- $type {
	    type {
		set v [_check-spec-simple $j $attr $opt $defval $ctxt]
	    }
	    array {
		set v [_check-spec-array $j $attr $opt $defval "$ctxt/array"]
	    }
	    object {
		set v [_check-spec-object $j $attr $opt $defval "$ctxt/object"]
	    }
	    default {
		_error-spec "type '$type' should be type|array|object" $ctxt
	    }
	}

	return $v
    }

    #
    # Internal procedure: check value against a single type spec
    # and return new NMJson value (changed if default value is used)
    #
    # j: NMJson value
    # type: int|float|inet|...
    # opt: 1 if optional values are authorized
    # defval: default value if opt==1
    # ctxt: context for error messages
    #

    proc _check-spec-simple {j type opt defval ctxt} {
	set jt [nmjtype $j]
	set jv [nmjval $j]
	if {$jt eq "null"} then {
	    if {$opt} then {
		return $defval
	    } else {
		_error-val $val "cannot be null" $ctxt
	    }
	}

	switch -- $type {
	    int {
		if {! ($jt eq "number" && [regexp {^-?[0-9]+$} $jv])} then {
		    _error-val $j "not an integer" $ctxt
		}
	    }
	    float {
		if {$jt ne "number" || [catch {expr 0+$jv}]} then {
		    _error-val $j "not a floating point number" $ctxt
		}
	    }
	    inet4 {
		if {! ($jt eq "string" && [::ip::version $jv] == 4)} then {
		    _error-val $j "not an IPv4 address" $ctxt
		}
	    }
	    inet6 {
		if {! ($jt eq "string" && [::ip::version $jv] == 6)} then {
		    _error-val $j "not an IPv6 address" $ctxt
		}
	    }
	    inet {
		if {! ($jt eq "string" && [::ip::version $jv] in {4 6})} then {
		    _error-val $j "not an IP address" $ctxt
		}
	    }
	    string {
		if {$jt ne "string"} then {
		    _error-val $j "not a string" $ctxt
		}
	    }
	    bool {
		if {$jt ne "bool"} then {
		    append ctxt "$jv"
		    _error-val $j "not a boolean" $ctxt
		}
	    }
	    default {
		_error-spec "type '$type' should be int|float|..." $ctxt
	    }
	}

	return $j
    }

    proc _check-spec-array {j type opt defval ctxt} {
	set jt [nmjtype $j]
	set jv [nmjval $j]
	if {$jt eq "null"} then {
	    if {$opt} then {
		return $defval
	    } else {
		_error-val $j "array required" $ctxt
	    }
	}

	set v {}
	foreach e $jv {
	    lappend v [_check-spec-internal $e $type $ctxt]
	}
	return [list $jt $v]
    }

    proc _check-spec-object {j members opt defval ctxt} {
	set jt [nmjtype $j]
	set jv [nmjval $j]
	if {$jt eq "null"} then {
	    if {$opt} then {
		return $defval
	    } else {
		_error-val $j "object required" $ctxt
	    }
	}

	# keep a copy of old dict for error messages
	set oldjv $jv
	# create a new directory to return the value
	set v [dict create]
	# traverse the list of members
	foreach m $members {
	    lassign $m key type optreq defval
	    if {[dict exists $jv $key]} then {
		set nv [dict get $jv $key]
		set nv [_check-spec-internal $nv $type "$ctxt/$key"]
		dict set v $key $nv
		dict unset jv $key
	    } else {
		if {$optreq eq "opt"} then {
		    dict set v $key $defval
		} else {
		    _error-val $oldjv "key '$key' required" $ctxt
		}
	    }
	}
	# check if unknown members are still in the old dict
	set dk [dict keys $jv]
	if {[llength $dk] > 0} then {
	    set dk [join $dk "', '"]
	    set dk "'$dk'"
	    _error-val $oldjv "unknown key(s) $dk" $ctxt
	}
	# return the new object
	return [list $jt $v]
    }

    ###################################################
    # Parse a JSON string into our NMJson internal representation
    #

    proc str2nmj {str} {
	# return structure
	try {
	    set ltok [_tokenize $str]
	    set json [_decode ltok]
	} on error msg {
	    error "cannot parse json ($msg)"
	}

	return $json
    }

    proc _get-next-token {_ltok} {
	upvar $_ltok ltok
	if {[llength $ltok] > 0} then {
	    set first [lindex $ltok 0]
	    set ltok [lreplace $ltok 0 0]
	} else {
	    set first END
	}
	return $first
    }

    proc _peek-next-token {_ltok} {
	upvar $_ltok ltok
	if {[llength $ltok] > 0} then {
	    set first [lindex $ltok 0]
	} else {
	    set first END
	}
	return $first
    }

    proc _decode {_ltok} {
	upvar $_ltok ltok

	lassign [_get-next-token ltok] type val
	switch $type {
	    STRING { set r [list "string" $val] }
	    BOOL   { set r [list "bool"   $val] }
	    NUMBER { set r [list "number" $val] }
	    NULL   { set r [list "null"] }
	    OPEN_CURLY { set r [list "object" [_decode_object ltok]] }
	    OPEN_BRACKET { set r [list "array" [_decode_array ltok]] }
	    default {
		error "Unexpected token $type"
	    }
	}
	return $r
    }

    proc _decode_object {_ltok} {
	upvar $_ltok ltok

	set o [dict create]
	while {[set tok [_get-next-token ltok]] ne "CLOSE_CURLY"} {
	    if {[dict size $o] > 0} then {
		if {$tok ne "COMMA"} then {
		    error "object expected a comma or closing curly brace, got $tok"
		}
		set tok [_get-next-token ltok]
	    }

	    lassign $tok type key
	    if {$type ne "STRING"} then {
		error "wrong key for object: $tok"
	    }

	    set tok [_get-next-token ltok]
	    if {$tok ne "COLON"} then {
		error "object expected a colon, got $tok"
	    }

	    set val [_decode ltok]
	    dict set o $key $val
	}

	return $o
    }

    proc _decode_array {_ltok} {
	upvar $_ltok ltok

	set a {}
	while {[set tok [_peek-next-token ltok]] ne "CLOSE_BRACKET"} {
	    if {[llength $a] > 0} then {
		if {$tok ne "COMMA"} then {
		    error "array expected a comma or closing bracket, got $tok"
		}
		set tok [_get-next-token ltok]
	    }
	    lappend a [_decode ltok]
	}
	# consume the closing bracket
	_get-next-token ltok

	return $a
    }

    ##########################################################################
    # The JSON tokenizer is part of Jim Tcl HTTP server
    #	https://github.com/dbohdan/jimhttp
    #
    # JSON parser / encoder.
    # Copyright (C) 2014, 2015, 2016, 2017 dbohdan.
    # License: MIT
    # Copyright (c) 2014, 2015, 2016, 2017 dbohdan
    # 
    # Permission is hereby granted, free of charge, to any person obtaining a copy
    # of this software and associated documentation files (the "Software"), to deal
    # in the Software without restriction, including without limitation the rights
    # to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    # copies of the Software, and to permit persons to whom the Software is
    # furnished to do so, subject to the following conditions:
    # 
    # The above copyright notice and this permission notice shall be included in
    # all copies or substantial portions of the Software.
    # 
    # THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    # IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    # FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    # AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    # LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    # OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    # THE SOFTWARE.

    # Transform a JSON blob into a list of tokens.
    proc _tokenize {json} {
	if {$json eq {}} {
	    error {empty JSON input}
	}

	set tokens {}
	for {set i 0} {$i < [string length $json]} {incr i} {
	    set char [string index $json $i]
	    switch -exact -- $char {
		\" {
		    set value [_analyze-string $json $i]
		    lappend tokens \
			    [list STRING [subst -nocommand -novariables $value]]

		    incr i [string length $value]
		    incr i ;# For the closing quote.
		}
		\{ {
		    lappend tokens OPEN_CURLY
		}
		\} {
		    lappend tokens CLOSE_CURLY
		}
		\[ {
		    lappend tokens OPEN_BRACKET
		}
		\] {
		    lappend tokens CLOSE_BRACKET
		}
		, {
		    lappend tokens COMMA
		}
		: {
		    lappend tokens COLON
		}
		{ } {}
		\t {}
		\n {}
		\r {}
		default {
		    if {$char in {- 0 1 2 3 4 5 6 7 8 9}} {
			set value [_analyze-number $json $i]
			lappend tokens [list NUMBER $value]

			incr i [expr {[string length $value] - 1}]
		    } elseif {$char in {t f n}} {
			set value [_analyze-boolean-or-null $json $i]
			if {$value eq "null"} then {
			    lappend tokens [list NULL $value]
			} else {
			    lappend tokens [list BOOL $value]
			}

			incr i [expr {[string length $value] - 1}]
		    } else {
			error "can't tokenize value as JSON: [list $json]"
		    }
		}
	    }
	}
	return $tokens
    }

    # Return the beginning of $str parsed as "true", "false" or "null".
    proc _analyze-boolean-or-null {str start} {
	regexp -start $start {(true|false|null)} $str value
	if {![info exists value]} {
	    error "can't parse value as JSON true/false/null: [list $str]"
	}
	return $value
    }

    # Return the beginning of $str parsed as a JSON string.
    proc _analyze-string {str start} {
	if {[regexp -start $start {"((?:[^"\\]|\\.)*)"} $str _ result]} {
	    return $result
	} else {
	    error "can't parse JSON string: [list $str]"
	}
    }

    # Return $str parsed as a JSON number.
    proc _analyze-number {str start} {
	if {[regexp -start $start -- \
		{-?(?:0|[1-9][0-9]*)(?:\.[0-9]*)?(:?(?:e|E)[+-]?[0-9]+)?} \
		$str result]} {
	    #    [][ integer part  ][ optional  ][  optional exponent  ]
	    #    ^ sign             [ frac. part]
	    return $result
	} else {
	    error "can't parse JSON number: [list $str]"
	}
    }
    ##########################################################################
}
