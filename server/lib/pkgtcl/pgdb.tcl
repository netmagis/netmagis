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
	    set dbfd "not connected"
	    $self reconnect
	}

	destructor {
	    $self disconnect
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

	#
	# exec sql [msgvar] [tab script]
	# - msgvar: if present, exec returns 1 if ok, or 0 if error (and
	#	error message in msg variable)
	#	If not present, exec simply throws an error
	# - tab script: if present, execute the script for each returned row
	#
	# So, the authorized forms are:
	#	exec sql			(throws an error)
	#	exec sql msgvar			(returns 0/1 and msg)
	#	exec sql tab script		(throws an error)
	#	exec sql msgvar tab script	(returns 0/1 and msg)
	#

	method exec {sql args} {
	    set r 1
	    try {
		switch [llength $args] {
		    0 {
			set report false
			uplevel 1 [list pg_execute $dbfd $sql]
		    }
		    1 {
			lassign $args _msg
			set report true
			upvar $_msg umsg
			uplevel 1 [list pg_execute $dbfd $sql]
		    }
		    2 {
			lassign $args t scr
			set report false
			uplevel 1 [list pg_execute -array $t $dbfd $sql $scr]
		    }
		    3 {
			lassign $args _msg t scr
			set report true
			upvar $_msg umsg
			uplevel 1 [list pg_execute -array $t $dbfd $sql $scr]
		    }
		    default {
			error {wrong # args: should be "exec sql ?msgvar? ?tab script?"}
		    }
		}

	    } trap {NONE} {errmsg errdict} {
		# Pgtcl 1.9 returns errorCode == NONE for all errors
		if {$report} then {
		    set umsg $errmsg
		    set r 0
		} else {
		    set errinfo [dict get $errdict -errorinfo]
		    if {[regexp "^PGRES_FATAL_ERROR" $errinfo]} then {
			# reset db handle
			set info [pg_dbinfo status $dbfd]
			if {$info ne "connection_ok"} then {
			    $self disconnect
			}
			error $errmsg
		    } else {
			# it is not a Pgtcl error
			error $errmsg $errinfo NONE
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
