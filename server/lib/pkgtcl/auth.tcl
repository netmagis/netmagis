package require md5			;# tcllib
package require md5crypt		;# tcllib
###package require uuid			;# tcllib

package provide auth 0.1

namespace eval ::auth {
    namespace export crypt genpw

    proc crypt {str} {
	return [md5crypt::md5crypt $str [::md5crypt::salt]]
    }

    proc random {nbytes} {
	############################
	set dev "/dev/urandom"
	############################
	if {[catch {set fd [open $dev {RDONLY BINARY}]} msg]} then {
	    #
	    # Silently fall-back to a non cryptographically secure random
	    # if /dev/random is not available
	    #
	    expr srand([clock clicks -microseconds])
	    set r ""
	    for {set i 0} {$i < $nbytes} {incr i} {
		append r [binary format "c" [expr int(rand()*256)]]
	    }
	} else {
	    #
	    # Successful open: read random bytes
	    #
	    set r [read $fd $nbytes]
	    close $fd
	}

	binary scan $r "H*" hex
	return $hex
    }

    proc genpw {} {
	set pw [random 12]
	return $pw
    }
}
