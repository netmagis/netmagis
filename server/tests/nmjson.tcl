#	{ ... } -> {object <dict>}
#	[ ... ] -> {array <list>}
#	true    -> {bool true}
#	123	-> {number <val>}
#	"foo"   -> {string <str>}
#	null	-> {null}

proc json2str {json} {
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
		append s [json2str $v]
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
		append s [json2str $v]
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

proc jsoneq {j1 j2} {
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


proc str2json {str} {
    # return structure
    try {
	set ltok [nmjson_tokenize $str]
	set json [nmjson_decode ltok]
    } on error msg {
	puts stderr "cannot parse json ($msg)"
	exit 1
    }

    return $json
}

proc nmjson_get-next-token {_ltok} {
    upvar $_ltok ltok
    if {[llength $ltok] > 0} then {
	set first [lindex $ltok 0]
	set ltok [lreplace $ltok 0 0]
    } else {
	set first END
    }
    return $first
}

proc nmjson_peek-next-token {_ltok} {
    upvar $_ltok ltok
    if {[llength $ltok] > 0} then {
	set first [lindex $ltok 0]
    } else {
	set first END
    }
    return $first
}

proc nmjson_decode {_ltok} {
    upvar $_ltok ltok

    lassign [nmjson_get-next-token ltok] type val
    switch $type {
	STRING { set r [list "string" $val] }
	BOOL   { set r [list "bool"   $val] }
	NUMBER { set r [list "number" $val] }
	NULL   { set r [list "null"] }
	OPEN_CURLY { set r [list "object" [nmjson_decode_object ltok]] }
	OPEN_BRACKET { set r [list "array" [nmjson_decode_array ltok]] }
	default {
	    error "Unexpected token $type"
	}
    }
    return $r
}

proc nmjson_decode_object {_ltok} {
    upvar $_ltok ltok

    set o [dict create]
    while {[set tok [nmjson_get-next-token ltok]] ne "CLOSE_CURLY"} {
	if {[dict size $o] > 0} then {
	    if {$tok ne "COMMA"} then {
		error "object expected a comma or closing curly brace, got $tok"
	    }
	    set tok [nmjson_get-next-token ltok]
	}

	lassign $tok type key
	if {$type ne "STRING"} then {
	    error "wrong key for object: $tok"
	}

	set tok [nmjson_get-next-token ltok]
	if {$tok ne "COLON"} then {
	    error "object expected a colon, got $tok"
	}

	set val [nmjson_decode ltok]
	dict set o $key $val
    }

    return $o
}

proc nmjson_decode_array {_ltok} {
    upvar $_ltok ltok

    set a {}
    while {[set tok [nmjson_peek-next-token ltok]] ne "CLOSE_BRACKET"} {
	if {[llength $a] > 0} then {
	    if {$tok ne "COMMA"} then {
		error "array expected a comma or closing bracket, got $tok"
	    }
	    set tok [nmjson_get-next-token ltok]
	}
	lappend a [nmjson_decode ltok]
    }
    # consume the closing bracket
    nmjson_get-next-token ltok

    return $a
}

##############################################################################
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
proc nmjson_tokenize {json} {
    if {$json eq {}} {
        error {empty JSON input}
    }

    set tokens {}
    for {set i 0} {$i < [string length $json]} {incr i} {
        set char [string index $json $i]
        switch -exact -- $char {
            \" {
                set value [nmjson_analyze-string $json $i]
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
                    set value [nmjson_analyze-number $json $i]
                    lappend tokens [list NUMBER $value]

                    incr i [expr {[string length $value] - 1}]
                } elseif {$char in {t f n}} {
                    set value [nmjson_analyze-boolean-or-null $json $i]
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
proc nmjson_analyze-boolean-or-null {str start} {
    regexp -start $start {(true|false|null)} $str value
    if {![info exists value]} {
        error "can't parse value as JSON true/false/null: [list $str]"
    }
    return $value
}

# Return the beginning of $str parsed as a JSON string.
proc nmjson_analyze-string {str start} {
    if {[regexp -start $start {"((?:[^"\\]|\\.)*)"} $str _ result]} {
        return $result
    } else {
        error "can't parse JSON string: [list $str]"
    }
}

# Return $str parsed as a JSON number.
proc nmjson_analyze-number {str start} {
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
##############################################################################

puts [nmjson_tokenize [lindex $argv 0]]
set j [str2json [lindex $argv 0]]
puts [json2str $j]
# set j1 [str2json [lindex $argv 0]]
# set j2 [str2json [lindex $argv 1]]
# puts [jsoneq $j1 $j2]
