package require Tcl 8.6
package require snit

package provide dbconf 0.1

namespace eval ::dbconf {

    ##########################################################################
    # Configuration parameters from database
    ##########################################################################

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

    snit::type db-config {
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
		{apiexpire rw {string}}
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

	method setdb {db} {
	    set dbo $db
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
		$dbo exec "SELECT * FROM global.config WHERE key = '$key'" tab {
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
		error "Unknown configuration key '$key'"
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
		    set v [pg_quote $val]

		    set sql "DELETE FROM global.config WHERE key = $k"
		    $dbo exec $sql

		    set sql "INSERT INTO global.config (key, value) VALUES ($k, $v)"
		    $dbo exec $sql
		} else {
		    error "Cannot modify read-only key '$key'"
		}
	    } else {
		error "Unknown configuration key '$key'"
	    }

	    return $r
	}
    }
}
