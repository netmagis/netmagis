package require Tcl 8.6
package require snit

package provide lconf 0.1

namespace eval ::lconf {

    ##########################################################################
    # Configuration interface
    ##########################################################################

    snit::type lconf {
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
}
