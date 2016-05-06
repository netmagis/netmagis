package require Tcl 8.6
package require snit
package require Pgtcl

package provide pgdb 0.1

namespace eval ::pgdb {

    snit::type db {
	# Database prefix in configuration file
	variable dbprefix

	# Access to local configuration file
	variable lc

	# Database handler (result of pg_connect)
	variable dbfd "not connected"

	# Expected schema version
	variable appver ""
	variable nver ""

	# prefix: "dns" or "mac" (according to local configuration file)
	# confobj: access to the local configuration file
	# check: version number (such as 3.0.5beta1) or ""

	method init {prefix confobj {check {}}} {
	    set dbprefix $prefix
	    set lc $confobj
	    if {$check ne ""} then {
		if {! [regsub {^(\d+)\.(\d+).*} $check {\1\2} nver]} then {
		    error "Netmagis version '$check' unrecognized"
		}
		set appver $check
	    }
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
	    # Build connlist
	    #
	    set connlist {}
	    foreach f {{host host} {port port} {dbname name}
				{user user} {password password}} {
		lassign $f connkey suffix
		set v [$lc get "${dbprefix}db${suffix}"]
		lappend connlist $connkey
		lappend connlist $v
	    }

	    try {
		set dbfd [pg_connect -connlist $connlist]
	    } on error msg {
		error "Database $dbprefix unavailable"
	    }

	    if {$appver ne ""} then {
		set sql "SELECT value FROM global.config
					WHERE key = 'schemaversion'"
		set sver ""
		$self exec $sql tab {
		    set sver $tab(value)
		}
		if {$sver != $nver} then {
		    error "DB version $sver does not match app version $appver"
		}
	    }
	}

	# exec sql [tab script]		(throws an error)
	# or
	# exec sql msgvar		(returns 0 or 1)
	method exec {sql args} {
	    set r 1
	    try {
		switch [llength $args] {
		    0 -
		    1 {
			uplevel 1 [list pg_execute $dbfd $sql]
		    }
		    2 {
			lassign $args tab script
			uplevel 1 [list pg_execute -array $tab $dbfd $sql $script]
		    }
		    default {
			error {wrong # args: should be "exec sql ?tab script?"}
		    }
		}

	    } trap {NONE} {msg err} {
		# Pgtcl 1.9 returns errorCode == NONE for all errors
		if {[llength $args] == 1} then {
		    upvar [lindex $args 0] umsg
		    set umsg $msg
		    set r 0
		} else {
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
	    return $r
	}

	# lock {table ...} script
	method lock {ltab script} {
	    # Lock tables
	    lappend sql "BEGIN WORK"
	    foreach t $ltab {
		lappend sql "LOCK $t"
	    }
	    $self exec [join $sql ";"]

	    try {
		uplevel 1 $script

	    } on ok {res dict} {
		# lock ... ok => commit
		$self exec "COMMIT WORK"
		return -code ok $res

	    } on return {res dict} {
		# lock ... ok => commit + return
		$self exec "COMMIT WORK"
		return -code return $res

	    } on continue {res dict} {
		# lock ... continue => commit + continue (a loop must exist)
		$self exec "COMMIT WORK"
		return -code continue $res

	    } on break {res dict} {
		# lock ... break => commit + break (a loop must exist)
		$self exec "COMMIT WORK"
		return -code break $res

	    } on error {res dict} {
		# lock ... error => abort with an error
		$self exec "ABORT WORK"
		error $res $::errorInfo

	    } on 6 {res dict} {
		# lock ... abort => abort without error
		$self exec "ABORT WORK"
		return -code ok $res

	    }
	}

	# valid only inside a "lock ... script" block
	# => exit the script with the result, without any error
	method abort {{res {}}} {
	    return -code 6 $res
	}
    }
}
