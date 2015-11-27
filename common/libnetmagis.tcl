#
# TCL library for Netmagis
#
#
# History
#   2002/03/27 : pda/jean : design
#   2002/05/23 : pda/jean : add info-groupe
#   2004/01/14 : pda/jean : add IPv6
#   2004/08/04 : pda/jean : aadd MAC
#   2004/08/06 : pda/jean : extension of network access rights
#   2006/01/26 : jean     : bug fix in check-authorized-host (case ip EXIST)
#   2006/01/30 : jean     : alias message in check-authorized-host
#   2010/11/29 : pda      : i18n
#   2010/12/17 : pda      : reworked installation and parameters
#   2011/01/02 : pda      : integration of libauth in libdns
#   2011/07/29 : pda      : renamed to libnetmagis
#

set libconf(version) %NMVERSION%

##############################################################################
# Configuration file processing
##############################################################################

#
# Read configuration file
#
# Input:
#   - parameters:
#	- file : configuration file
# Output:
#   - none (program ends if an error is encountered)
#
# History
#   2010/12/17 : pda      : design
#   2013/08/29 : pda/jean : reset the internal representation before file read
#   2014/02/26 : pda/jean : add the pseudo-parameter _conffile
#   2014/02/26 : pda/jean : add the pseudo-parameter _version
#

proc read-local-conf-file {file} {
    global netmagisconf

    if {[catch {set fd [open "$file" "r"]} msg]} then {
	puts stderr "Cannot open configuration file '$file'"
	exit 1
    }
    set lineno 1
    set errors false
    array unset netmagisconf
    while {[gets $fd line] >= 0} {
	regsub {#.*} $line {} line
	regsub {\s*$} $line {} line
	if {$line ne ""} then {
	    if {[regexp {(\S+)\s+"(.*)"} $line m key val]} then {
		set netmagisconf($key) $val
	    } elseif {[regexp {(\S+)\s+(.*)} $line m key val]} then {
		set netmagisconf($key) $val
	    } else {
		puts stderr "$file($lineno): unrecognized line $line"
		set errors true
	    }
	}
	incr lineno
    }
    close $fd
    if {$errors} then {
	exit 1
    }
    set netmagisconf(_conffile) $file
    set netmagisconf(_version) "%NMVERSION%"
}

#
# Get configuration key
#
# Input:
#   - parameters:
#	- key : configuration key
# Output:
#   - return value: configuration value or empty string
#
# History
#   2010/12/17 : pda      : design
#   2010/12/19 : pda      : empty string if key is not found
#

proc get-local-conf {key} {
    global netmagisconf

    if {[info exists netmagisconf($key)]} then {
	set v $netmagisconf($key)
    } else {
	set v ""
    }
    return $v
}

#
# Get database handle
#
# Input:
#   - parameters:
#	- prefix : prefix for configuration keys (e.g. db for dbhost/dbname/...)
# Output:
#   - return value: conninfo script for pg_connect
#
# History
#   2010/12/17 : pda      : design
#   2011/01/21 : pda      : add port specification
#   2013/02/08 : pda/jean : fix bug in values containing special characters
#

proc get-conninfo {prefix} {
    set conninfo {}
    foreach f {{host host} {port port} {dbname name}
			{user user} {password password}} {
	lassign $f connkey suffix
	set v [get-local-conf "$prefix$suffix"]
	regsub {['\\]} $v {\\&} v
	lappend conninfo "$connkey='$v'"
    }
    return [join $conninfo " "]
}

##############################################################################
# Library initialization
##############################################################################

read-local-conf-file %CONFFILE%

lappend auto_path [get-local-conf "pkgtcl"]
set debug [get-local-conf "debug"]

package require msgcat			;# tcl
namespace import ::msgcat::*

package require snit			;# tcllib
package require ip			;# tcllib
package require md5			;# tcllib
package require md5crypt		;# tcllib
package require uuid			;# tcllib

package require webapp
package require pgsql
package require arrgen

##############################################################################
# File installation class
##############################################################################

#
# File installation class
#
# This class is meant to simplify installation of new files in tree
# hierarchy.
#
# When a file is added, its contents are written in a ".new" file and
# the name is queued in internal instance variable fileq.
# When a commit is requested, all original files are renamed into ".old"
# files and ".new" file replace original files.
# When an abort is requested, all ".new" files are removed.
#
# Methods:
# - init
#	reset a new file list
# - add filename filecontent
#	add a new file based on its contents (as a textual value)
#	returns empty string if succeeds
# - abort
#	reset new files
# - commit
#	apply modifications
#	returns empty string if succeeds
# - uncommit
#	undo previous commit
#	returns empty string if succeeds
#
# History
#   2011/06/05 : pda      : design
#

snit::type ::fileinst {
    # file queue
    variable fileq {}

    # state
    variable state "init"

    # reset queue to empty state
    method init {} {
	set fileq {}
    }

    # add a file contents into the queue
    method add {name contents} {
	if {$state eq "init" || $state eq "nonempty"} then {
	    set nf "$name.new"
	    catch {file delete -force $nf}
	    if {! [catch {set fd [open "$nf" "w"]} err]} then {
		puts -nonewline $fd $contents
		if {! [catch {close $fd} err]} then {
		    lappend fileq $name
		    set err ""
		}
	    }
	    set state "nonempty"
	} else {
	    set err "cannot add file: state != 'init' && state != 'nonempty'"
	}
	return $err
    }

    # commit new files
    method commit {} {
	set err ""
	if {$state eq "init" || $state eq "nonempty"} then {

	    # we use a "for" loop instead of a "foreach" since the index i
	    # will be used if anything goes wrong
	    set n [llength $fileq]
	    for {set i 0} {$i < $n} {incr i} {
		set f [lindex $fileq $i]
		set nf "$f.new"
		set of "$f.old"

		# make a backup of original file if it exists
		catch {file delete -force $of}
		if {[file exists $f]} then {
		    if {[catch {file rename -force $f $of} msg]} then {
			set err "cannot rename $f to $of\n$msg"
			break
		    }
		}
		
		# install new file
		if {[catch {file rename $nf $f} msg]} then {
		    set err "cannot rename $nf to $f\n$msg"
		    break
		}
	    }

	    if {$err eq ""} then {
		set state "commit"
	    } else {
		for {set j 0} {$j <= $i} {incr j} {
		    set f [lindex $fileq $j]
		    set nf "$f.new"
		    set of "$f.old"

		    if {! [file exists $nf]} then {
			catch {file rename -force $f $nf}
		    }

		    if {[file exists $of]} then {
			catch {file rename -force $of $f}
		    }
		}
	    }
	} else {
	    set err "cannot add file: state != 'init' && state != 'nonempty'"
	}

	return $err
    }

    # undo previous commit
    method uncommit {} {
	if {$state eq "commit"} then {
	    set err ""
	    set n [llength $fileq]
	    for {set i 0} {$i < $n} {incr i} {
		set f [lindex $fileq $i]
		set nf "$f.new"
		set of "$f.old"

		if {[catch {file rename -force $f $nf} msg]} then {
		    append err "cannot rename $f to $nf\n$msg\n"
		} else {
		    if {[file exists $of]} then {
			if {[catch {file rename -force $of $f} msg]} then {
			    append err "cannot rename $of to $f\n$msg\n"
			}
		    }
		}
	    }
	} else {
	    set err "cannot commit: state != 'commit'"
	}
	return $err
    }

    # abort new files
    method abort {} {
	foreach f $fileq {
	    catch {file delete -force "$f.new"}
	}
	set fileq {}
    }
}

#
# Compare old file contents with new contents as a variable
#
# Input:
#   - parameters
#	- file: name of file
#	- text: new file content
#	- _errmsg: variable containing error message in return
# Output:
#   - return value: -1 (error), 0 (no change), or 1 (change)
#   - variable _errmsg: error message, if return value = -1
#
# History
#   2004/03/09 : pda/jean : design
#   2011/05/14 : pda      : use configuration variables
#   2011/05/22 : pda      : make it simpler
#

proc compare-file-with-text {file text _errmsg} {
    upvar $_errmsg errmsg

    set r 1
    if {[file exists $file]} then {
	if {[catch {set fd [open $file "r"]} errmsg]} then {
	    set r -1
	} else {
	    set old [read $fd]
	    close $fd

	    if {$old eq $text} then {
		set r 0
	    }
	}
    }

    return $r
}

#
# Show difference between old file and new contents
#
# Input:
#   - parameters
#	- fd : file descriptor
#	- cmd: diff command
#	- file: name of file
#	- text: new file content
#	- _errmsg: variable containing error message in return
# Output:
#   - return value: 1 (ok) or 0 (error)
#   - variable _errmsg: error message, if return value = 0
#
# History
#   2011/05/22 : pda      : specification
#   2011/06/10 : pda      : add fd parameter
#   2011/06/10 : pda      : add special case for non-existant file
#

proc show-diff-file-text {fd cmd file text} {
    if {! [file exists $file]} then {
	set file "/dev/null"
    }
    set c [format $cmd $file]
    append c "|| exit 0"
    catch {exec sh -c $c << $text} r
    puts $fd $r
}

##############################################################################
# Topo library
##############################################################################

#
# Read topo status
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- admin : 1 if user is administrator
# Output:
#   - return value: HTML status message, or empty (if user is not admin
#	or if there is no message)
#
# History
#   2010/11/15 : pda      : extract in an autonomous function
#   2010/11/23 : pda      : use keepstate table
#   2010/12/04 : pda      : i18n
#

proc topo-status {dbfd admin} {
    set msgsta ""
    if {$admin} then {
	set found 0
	set sql "SELECT * FROM topo.keepstate WHERE type = 'anaconf'"
	pg_select $dbfd $sql tab {
	    set date $tab(date)
	    set msg  $tab(message)
	    set found 1
	}
	if {! $found} then {
	    set msg [mc "No message from anaconf"]
	    set date [mc "(no date)"]
	} elseif {$msg eq "Resuming normal operation"} then {
	    set msg ""
	}

	if {$msg ne ""} then {
	    set msg [::webapp::html-string $msg]
	    regsub -all "\n" $msg "<br>" msg

	    set text [::webapp::helem "p" [mc "Topod messages"]]
	    append text [::webapp::helem "p" \
			    [::webapp::helem "font" $msg "color" "#ff0000"] \
			    ]
	    append text [::webapp::helem "p" [mc "... since %s" $date]]

	    set msgsta [::webapp::helem "div" $text "class" "alerte"]
	}
    }
    return $msgsta
}

#
# Wrapper function to call topo programs on topo host
#
# Input:
#   - cmd: topo program with arguments
#   - _msg : in return, text read from program or error message
# Output:
#   - return value: 1 if ok, 0 if failure
#   - parameter _msg: text read or error message
#
# History
#   2010/12/14 : pda/jean : design
#   2010/12/19 : pda      : added topouser
#   2012/04/24 : pda      : the graph file is local to the www server
#

proc call-topo {cmd _msg} {
    upvar $_msg msg

    #
    # Quote shell metacharacters to prevent interpretation
    #
    regsub -all {[<>|;'"${}()&\[\]*?]} $cmd {\\&} cmd

    set topobindir [get-local-conf "topobindir"]
    set topograph  [get-local-conf "topograph"]
    set topohost   [get-local-conf "topohost"]

    set cmd "$topobindir/$cmd < $topograph"
    set r [catch {exec sh -c $cmd} msg option]
    return [expr !$r]
}

#
# Compare two interface names (for sort function)
#
# Input:
#   - parameters:
#       - i1, i2 : interface names
# Output:
#   - return value: -1, 0 or 1 (see string compare)
#
# History
#   2006/12/29 : pda      : design
#   2010/12/04 : pda      : i18n
#

proc compare-interfaces {i1 i2} {
    #
    # Isolate all words
    # Eg: "GigabitEthernet1/0/1" -> " GigabitEthernet 1/0/1"
    #
    regsub -all {[A-Za-z]+} $i1 { & } i1
    regsub -all {[A-Za-z]+} $i2 { & } i2
    #
    # Remove all special characters
    # Eg: " GigabitEthernet 1/0/1" -> " GigabitEthernet 1 0 1"
    #
    regsub -all {[^A-Za-z0-9]+} $i1 { } i1
    regsub -all {[^A-Za-z0-9]+} $i2 { } i2
    #
    # Remove unneeded spaces
    #
    set i1 [string trim $i1]
    set i2 [string trim $i2]

    #
    # Compare word by word
    #
    set r 0
    foreach m1 [split $i1] m2 [split $i2] {
	if {[regexp {^[0-9]+$} $m1] && [regexp {^[0-9]+$} $m2]} then {
	    if {$m1 < $m2} then {
		set r -1
	    } elseif {$m1 > $m2} then {
		set r 1
	    } else {
		set r 0
	    }
	} else {
	    set r [string compare $m1 $m2]
	}
	if {$r != 0} then {
	    break
	}
    }

    return $r
}

#
# Compare two IP addresses, used in sort operations.
#
# Input:
#   - parameters:
#       - ip1, ip2 : IP addresses (IPv4 or IPv6)
# Output:
#   - return value: -1, 0 ou 1 (see string compare)
#
# History
#   2006/06/20 : pda      : design
#   2006/06/22 : pda      : documentation
#   2010/12/04 : pda      : i18n
#

proc compare-ip {ip1 ip2} {
    set ip1 [::ip::normalize $ip1]
    set v1  [::ip::version $ip1]
    set ip2 [::ip::normalize $ip2]
    set v2  [::ip::version $ip2]

    set r 0
    if {$v1 == 4 && $v2 == 4} then {
	set l1 [split [::ip::prefix $ip1] "."]
	set l2 [split [::ip::prefix $ip2] "."]
	foreach e1 $l1 e2 $l2 {
	    if {$e1 < $e2} then {
		set r -1
		break
	    } elseif {$e1 > $e2} then {
		set r 1
		break
	    }
	}
    } elseif {$v1 == 6 && $v2 == 6} then {
	set l1 [split [::ip::prefix $ip1] ":"]
	set l2 [split [::ip::prefix $ip2] ":"]
	foreach e1 $l1 e2 $l2 {
	    if {"0x$e1" < "0x$e2"} then {
		set r -1
		break
	    } elseif {"0x$e1" > "0x$e2"} then {
		set r 1
		break
	    }
	}
    } else {
	set r [expr $v1 < $v2]
    }
    return $r
}

#
# Check if an IP address (IPv4 or IPv6) is in an address range
#
# Input:
#   - parameters:
#       - ip : IP address (or CIDR) to check
#	- net : address range
# Output:
#   - return value: 0 (ip not in range) or 1 (ip is in range)
#
# History
#   2006/06/22 : pda      : design
#   2010/12/04 : pda      : i18n
#

proc ip-in {ip net} {
    set v [::ip::version $net]
    if {[::ip::version $ip] != $v} then {
	return 0
    }

    set defmask [expr "$v==4 ? 32 : 128"]

    set ip [::ip::normalize $ip]
    set net [::ip::normalize $net]

    set mask [::ip::mask $net]
    if {$mask eq ""} then {
	set mask $defmask
    }

    set prefnet [::ip::prefix $net]
    regsub {(/[0-9]+)?$} $ip "/$mask" ip2
    set prefip  [::ip::prefix $ip2]

    return [string equal $prefip $prefnet]
}

#
# Check metrology id against user permissions
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- id : id du point de collecte (ou id+id+...)
#	- _tabuid : user characteristics
#	- _title : title of graph
# Output:
#   - return value: empty string or error message
#   - parameter _title : title of graph found
#
# History
#   2006/08/09 : pda/boggia : design
#   2006/12/29 : pda        : parameter vlan
#   2008/07/30 : pda        : adapt to new extractcoll
#   2008/07/30 : pda        : multiple ids
#   2008/07/31 : pda        : add "|"
#   2010/12/04 : pda        : i18n
#

proc check-metro-id {dbfd id _tabuid _title} {
    upvar $_tabuid tabuid
    upvar $_title title
    global libconf

    #
    # If ids are more than one
    #

    set lid [split $id "+|"]

    #
    # Get the metrology sensor list, according to user permissions
    #

    set cmd [format $libconf(extractcoll) $tabuid(flagsr)]
    if {! [call-topo $cmd msg]} then {
	return [mc "Cannot read sensor list: %s" $msg]
    }
    foreach line [split $msg "\n"] {
	lassign [split $line] kw i
	set n [lsearch -exact $lid $i]
	if {$n >= 0} then {
	    set idtab($i) $line
	    if {[info exists firstkw]} then {
		if {$firstkw ne $kw} then {
		    return [mc "Divergent sensor types"]
		}
	    } else {
		set firstkw $kw
	    }
	    set lid [lreplace $lid $n $n]
	}
    }

    #
    # Error if id is not found
    #

    if {[llength $lid] > 0} then {
	return [mc "Sensor '%s' not found" $id]
    }

    #
    # Try to guess an appropriate title
    # 

    set lid [array names idtab]
    switch [llength $lid] {
	0 {
	    return [mc "No sensor selected"]
	}
	1 {
	    set i [lindex $lid 0]
	    set l $idtab($i)
	    switch $firstkw {
		trafic {
		    set eq    [lindex $l 2]
		    set iface [lindex $l 4]
		    set vlan  [lindex $l 5]

		    if {$vlan ne "-"} then {
			set t [mc {Traffic on vlan %1$s of interface %2$s of %3$s}]
		    } else {
			set t [mc {Traffic on interface %2$s of %3$s}]
		    }
		    set title [format $t $vlan $iface $eq]
		}
		nbauthwifi -
		nbassocwifi {
		    set eq    [lindex $l 2]
		    set iface [lindex $l 4]
		    set ssid  [lindex $l 5]

		    if {$firstkw eq "nbauthwifi"} then {
			set t [mc {Number of auhentified users on ssid %1$s of interface %2$s of %3$s}]
		    } else {
			set t [mc {Number of associated hosts on ssid %1$s of interface %2$s of %3$s}]
		    }
		    set title [format $t $ssid $iface $eq]
		}
		default {
		    return [mc "Internal error: invalid extractcoll output format"]
		}
	    }
	}
	default {
	    switch $firstkw {
		trafic {
		    set le {}
		    foreach i $lid {
			set l $idtab($i)
			set eq    [lindex $l 2]
			set iface [lindex $l 4]
			set vlan  [lindex $l 5]

			set e "$eq/$iface"
			if {$vlan ne "-"} then {
			    append e ".$vlan"
			}
			lappend le $e
		    }
		    set le [join $le ", "]
		    set title [mc "Traffic on interfaces %s" $le]
		}
		nbauthwifi -
		nbassocwifi {
		    if {$firstkw eq "nbauthwifi"} then {
			set t [mc "Number of auhentified users on %s"]
		    } else {
			set t [mc "Number of associated hosts on %s"]
		    }
		    foreach i $lid {
			set l $idtab($i)
			set eq    [lindex $l 2]
			set iface [lindex $l 4]
			set ssid  [lindex $l 5]

			set e "$eq/$iface ($ssid)"
			lappend le $e
		    }
		    set le [join $le ", "]
		    set title [format $t $le]
		}
		default {
		    return [mc "Internal error: invalid extractcoll output format"]
		}
	    }
	}
    }

    return ""
}

#
# Get regexp giving authorized equipments for a given group.
#
# Input:
#   - parameters:
#       - dbfd : database handle
#	- rw : read (0) or write (1)
#	- idgrp : group id
# Output:
#   - return value: {{re_allow_1 ... re_allow_n} {re_deny_1 ... re_deny_n}}
#
# History
#   2006/08/10 : pda/boggia : design with an on-disk file
#   2010/11/03 : pda/jean   : data are now in the database
#   2010/12/05 : pda        : i18n
#

proc read-authorized-eq {dbfd rw idgrp} {
    set r {}
    foreach allow_deny {1 0} {
	set sql "SELECT pattern
			FROM topo.p_eq
			WHERE idgrp = $idgrp
			    AND rw = $rw
			    AND allow_deny = $allow_deny"
	set d {}
	pg_select $dbfd $sql tab {
	    lappend d $tab(pattern)
	}
	lappend r $d
    }
    return $r
}

#
# Fetch a graph from the metrology host and return it back.
#
# Input:
#   - parameters:
#       - url : URL of the graph on the metrology host
# Output:
#   - none : the fetched graph is printed on stdout with usual HTTP headers
#
# History
#   2006/05/17 : jean       : design for dhcplog
#   2006/08/09 : pda/boggia : extract and use in this library
#   2010/11/15 : pda        : remove err parameter
#   2010/12/05 : pda        : i18n
#

proc gengraph {url} {
    package require http			;# tcllib

    set token [::http::geturl $url]
    set status [::http::status $token]

    if {$status ne "ok"} then {
	set code [::http::code $token]
	d error [mc "No access: %s" $code]
    }

    upvar #0 $token state

    # 
    # Determine image type
    # 

    array set meta $state(meta)
    switch -exact $meta(Content-Type) {
	image/png {
	    set contenttype "png"
	}
	image/jpeg {
	    set contenttype "jpeg"
	}
	image/gif {
	    set contenttype "gif"
	}
	default {
	    set contenttype "html"
	}
    }

    # 
    # Return the result back
    # 

    ::webapp::send $contenttype $state(body)
}

#
# Decode a date (supposed to be input by a human)
#
# Input:
#   - parameters:
#       - date : date imput by an user in a form
#	- hour : hour (from 00:00:00 to 23:59:59)
# Output:
#   - return value: converted date in potsgresql format, or "" if no date
#
# History
#   2000/07/18 : pda      : design
#   2000/07/23 : pda      : add hour
#   2001/03/12 : pda      : extract in this library
#   2008/07/30 : pda      : add special case for 24h (= 23:59:59)
#   2010/12/05 : pda      : i18n
#

proc decode-date {date hour} {
    set date [string trim $date]
    if {$date eq ""} then {
	set datepg ""
    }
    if {$hour eq "24"} then {
	set hour "23:59:59"
    }
    set l [split $date "/"]
    lassign $l dd mm yyyy
    switch [llength $l] {
	1	{
	    set mm   [clock format [clock seconds] -format "%m"]
	    set yyyy [clock format [clock seconds] -format "%Y"]
	    set datepg "$mm/$dd/$yyyy $hour"
	}
	2	{
	    set yyyy [clock format [clock seconds] -format "%Y"]
	    set datepg "$mm/$dd/$yyyy $hour"
	}
	3	{
	    set datepg "$mm/$dd/$yyyy $hour"
	}
	default	{
	    set datepg ""
	}
    }

    if {$datepg ne ""} then {
	if {[catch {clock scan $datepg}]} then {
	    set datepg ""
	}
    }
    return $datepg
}

#
# Convert a 802.11b/g radio frequency (2.4 GHz band) into a channel
#
# Input:
#   - parameters:
#       - freq : frequency
#   - global variable libconf(freq:<frequency>) : conversion table
# Output:
#   - return value: channel
#
# History
#   2008/07/30 : pda      : design
#   2008/10/17 : pda      : channel "dfs"
#   2010/12/05 : pda      : i18n
#

proc conv-channel {freq} {
    global libconf

    switch -- $freq {
	dfs {
	    set channel "auto"
	}
	default {
	    if {[info exists libconf(freq:$freq)]} then {
		set channel $libconf(freq:$freq)
	    } else {
		set channel "$freq MHz"
	    }
	}
    }
    return $channel
}

#
# Read list of interfaces on an equipment
#
# Input:
#   - parameters:
#	- eq : equipment name
#	- _tabuid : user's characteristics (including graph flags)
#   - global variables :
#	- libconf(extracteq) : call to extracteq
# Output:
#   - return value: {eq type model location iflist liferr arrayif arrayvlan}
#	where
#	- iflist is the sorted list of interfaces
#	- liferr is the list of interfaces which are are writable but not
#		readable (e.g. this is an error)
#	- arrayif (ready for "array set") gives an array indexed by
#		interface name:
#		tab(iface) {name edit radio stat mode desc link native {vlan...}}
#		(see extracteq output format)
#	- arrayvlan (ready for "array set") gives an array indexed by vlanid:
#		tab(id) {desc-in-hex voip-0-or-1}
#
# History
#   2010/11/03 : pda      : design
#   2010/11/15 : pda      : remove parameter err
#   2010/11/23 : pda/jean : get writable interfaces
#   2010/11/25 : pda      : add manual
#   2010/12/05 : pda      : i18n
#

proc eq-iflist {eq _tabuid} {
    global libconf
    upvar $_tabuid tabuid

    #
    # First call to extracteq : get the list of "readable" interfaces
    #

    set found 0

    set cmd [format $libconf(extracteq) $tabuid(flagsr) $eq]
    if {! [call-topo $cmd msg]} then {
	d error [mc {Error during extraction of readable interfaces from '%1$s': %2$s} $eq $msg]
    }
    foreach line [split $msg "\n"] {
	switch [lindex $line 0] {
	    eq {
		set r [lreplace $line 0 0]

		set location [lindex $r 3]
		if {$location eq "-"} then {
		    set location ""
		} else {
		    set location [binary format H* $location]
		}
		set r [lreplace $r 3 3 $location]

		# manual = "manual" or "auto"
		set manual [lindex $r 4]
		set r [lreplace $r 4 4]

		set found 1
	    }
	    iface {
		set if [lindex $line 1]
		# prepare "edit" item, which may be set in the second
		# call to extracteq
		set line [linsert $line 2 "-"]
		set tabiface($if) [lreplace $line 0 0]
	    }
	}
    }

    if {! $found} then {
	d error [mc "Equipment '%s' not found" $eq]
    }

    #
    # Second call to exctracteq : get the list of "writable" interfaces
    #

    set liferr {}

    if {$manual eq "auto"} then {
	set cmd [format $libconf(extracteq) $tabuid(flagsw) $eq]
	if {! [call-topo $cmd msg]} then {
	    d error [mc {Error during extraction of writable interfaces from '%1$s': %2$s} $eq $msg]
	}
	foreach line [split $msg "\n"] {
	    switch [lindex $line 0] {
		iface {
		    set if [lindex $line 1]
		    if {! [info exists tabiface($if)]} then {
			# add this interface to the list of error interfaces
			lappend liferr $if
		    } else {
			# set the "edit" attribute on this interface
			set tabiface($if) [lreplace $tabiface($if) 1 1 "edit"]
		    }
		}
		vlan {
		    lassign $line bidon id desc voip
		    set tabvlan($id) [list $desc $voip]
		}
	    }
	}
	set liferr [lsort -command compare-interfaces $liferr]
    }

    lappend r $liferr

    #
    # Sort interfaces
    #

    set iflist [lsort -command compare-interfaces [array names tabiface]]

    #
    # Return value
    #

    lappend r $iflist
    lappend r [array get tabiface]
    lappend r [array get tabvlan]

    return $r
}

#
# Get graph and equipment status
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- eq : equipment name
#	- iface (optional) : interface name
# Output:
#   - return value: HTML text giving graph and equipment status
#
# History:
#   2010/11/29 : pda/jean : design
#   2010/12/05 : pda      : i18n
#

proc eq-graph-status {dbfd eq {iface {}}} {
    global libconf

    #
    # Search for unprocessed modifications and build information.
    #

    set wif ""
    if {$iface ne ""} then {
	set qiface [::pgsql::quote $iface]
	set wif "AND iface = '$qiface'"
    }

    set qeq [::pgsql::quote $eq]

    set sql "SELECT * FROM topo.ifchanges
			WHERE eq = '$qeq' AND processed = 0 $wif
			ORDER BY reqdate DESC"
    set lines {}
    lappend lines [list Title4 [mc "Date"] [mc "Login"] [mc "Interface"] [mc "Change"]]
    pg_select $dbfd $sql tab {
	set ifdesc $tab(ifdesc)
	set ethervlan $tab(ethervlan)
	set voicevlan $tab(voicevlan)
	set chg [mc "description='%s'" $ifdesc]
	if {$ethervlan == -1} then {
	    append chg ", "
	    append chg [mc "deactivated interface"]
	} else {
	    append chg ", "
	    append chg [mc "vlan=%s" $ethervlan]
	    if {$voicevlan != -1} then {
		append chg ", "
		append chg [mc "voip=%s" $voicevlan]
	    }
	}
	lappend lines [list Normal4 $tab(reqdate) $tab(login) $tab(iface) $chg]
    }
    if {[llength $lines] == 1} then {
	set ifchg ""
    } else {
	set ifchg [::webapp::helem "p" [mc "Changes currently processed:"]]
	append ifchg [::arrgen::output "html" $libconf(tabeqstatus) $lines]
    }

    #
    # Search for current topod status
    #

    set sql "SELECT message FROM topo.keepstate WHERE type = 'status'"
    set action ""
    pg_select $dbfd $sql tab {
	catch {lassign [lindex $tab(message) 0] date action}
    }

    switch -nocase -glob $action {
	rancid* -
	building* {
	    set graph [::webapp::helem "p" [mc "Graph currenty re-builded. Informations presented here are not necessarily consistent with current equipement configuration."]]
	}
	default {
	    set graph ""
	}
    }

    #
    # Present information from $ifchg and $graph
    #

    if {$ifchg eq "" && $graph eq ""} then {
	set html ""
    } else {
	set html "$graph\n$ifchg"
	set html [::webapp::helem "font" $html "color" "#ff0000"]
	set html "<hr>$html<hr>"
    }

    return $html
}


#
# Check if a VLAN name is valid
#
# Input:
#   - parameters:
#       - name : VLAN name
#       - _msg : error message
#   - global variable libconf(vlan-chars) : authorized characters
# Output:
#   - return value: 1 if name is valid, 0 otherwise
#   - msg: error message
#
# History
#   2014/02/18 : jean      : converted to function from "list-vlans"
#

proc check-vlan-name {name _msg} {
    global libconf
    upvar $_msg msg


    if {[regexp "^\[$libconf(vlan-chars)\]+$" $name]} then {
	set ok 1
	set msg ""
    } else {
	set ok 0
	set msg "invalid characters in vlan name '$name' (not in $libconf(vlan-chars))"
    }

    return $ok
}


##############################################################################
# Topo*d subsystem
##############################################################################

#
# Set function tracing
#
# Input: 
#   - lfunct : list of function names
# Output: none
#
# History
#   2010/10/20 : pda/jean : minimal design
#   2010/12/15 : pda/jean : splitted in library
#

proc set-trace {lfunct} {
    foreach c $lfunct {
	trace add execution $c enter report-enter
	trace add execution $c leave report-leave
    }
}

proc report-enter {cmd enter} {
    puts "> $cmd"
}

proc report-leave {cmd code result leave} {
    puts "< $cmd -> $code/$result"
}

#
# Run a program as a daemon
#
# Input: 
#   - argv0  : path to the script
#   - argstr : argument string
# Output: none
#
# History
#   2012/03/27 : pda/jean : design
#

proc run-as-daemon {argv0 argstr} {
    exec sh -c "exec $argv0 $argstr" &
    exit 0
}

##############################################################################
# Utility functions
##############################################################################

#
# Initialize system logger
#
# Input: 
#   - logger : shell command line to log messages
# Output: none
#
# History
#   2010/12/15 : pda/jean : minimal design
#

set ctxt(logger) ""

proc set-log {logger} {
    global ctxt

    set ctxt(logger) $logger
}

#
# Add a message to the log
#
# Input: 
#   - msg : error/warning message
# Output: none
#
# History
#   2010/10/20 : pda/jean : minimal design
#

proc log-error {msg} {
    global ctxt

    if {[catch {open "|$ctxt(logger)" "w"} fd]} then {
	puts stderr "$msg (log to syslog: $fd)"
    } else {
	puts $fd $msg
	close $fd
    }
}

#
# Set verbosity level
#
# Input: 
#   - level : threshold (verbosity level) of messages to display
# Output:
#   - return value: none
#   - ctxt(verbose) : verbose threshold
#
# History
#   2010/10/21 : pda/jean : design
#

proc topo-set-verbose {level} {
    global ctxt

    set ctxt(verbose) $level
}

#
# Display debug message according to verbosity level
#
# Input: 
#   - msg : message
#   - level : verbosity level
# Output: none
#
# History
#   2010/10/21 : pda/jean : design
#

proc topo-verbositer {msg level} {
    global ctxt

    if {$level <= $ctxt(verbose)} then {
	puts stderr $msg
    }
}

##############################################################################
# Status management
##############################################################################

#
# Update status
# Status keeps last topo*d operations.
#
# Input: 
#   - status : current operation
# Output: none
#
# Note: status is in topo.keepstate table, topo.message is a list
# {{date1 msg1} {date2 msg2} ...} where 1 is the most recent entry.
# We keep only last N entries.
#
# History
#   2010/11/05 : pda/jean : design
#

proc reset-status {} {
    set sql "DELETE FROM topo.keepstate WHERE type = 'status'"
    toposqlexec $sql 2
}

proc set-status {status} {
    global ctxt

    set cur {}
    set sql "SELECT message FROM topo.keepstate WHERE type = 'status'"
    if {! [toposqlselect $sql tab { set cur $tab(message) } 2]} then {
	return
    }

    # insert new entry before all others
    set date [clock format [clock seconds]]
    set cur [linsert $cur 0 [list $date $status]]

    # remove oldest entries at the end
    if {[llength $cur] > $ctxt(maxstatus)} then {
	set cur [lreplace $cur $ctxt(maxstatus) end]
    }

    set qcur [::pgsql::quote $cur]

    set sql "DELETE FROM topo.keepstate WHERE type = 'status' ;
		INSERT INTO topo.keepstate (type, message)
			VALUES ('status', '$qcur')"
    toposqlexec $sql 2
}

##############################################################################
# Topo*d database handling
##############################################################################

#
# Connect to database if needed
#
# Input:
#   - chan : database channel
#   - ctxt(dbfd1), ctxt(dbfd2) : database handles for each channel
# Output:
#   - ctxt(dbfd<n>) : database handle updated
#
# History
#   2010/10/20 : pda/jean : documentation
#

proc lazy-connect {{chan 1}} {
    global ctxt

    set r 1
    if {[string equal $ctxt(dbfd$chan) ""]} then {
	set conninfo [get-conninfo "dnsdb"]
	set d [catch {set ctxt(dbfd$chan) [pg_connect -conninfo $conninfo]} msg]
	if {$d} then {
	    set r 0
	} else {
	    ::dnsconfig setdb $ctxt(dbfd$chan)
	    log-error "Connexion to database succeeded"
	}
    }
    return $r
}

#
# Execute a SQL request to get data (as with pg_select), and manage
# database reconnect
#
# Input: 
#   - sql : SQL request
#   - arrayname : array used in the script
#   - script : procedure ou script
#   - chan : optionnal channel (1 or 2)
# Output: 
#   - return value: 1 if ok, 0 if error
#
# History
#   2010/10/20 : pda/jean : design (woaw !)
#

proc toposqlselect {sql arrayname script {chan 1}} {
    global ctxt

    if {[lazy-connect $chan]} {
	set cmd [list pg_select $ctxt(dbfd$chan) $sql $arrayname $script]
	if {[catch {uplevel 1 $cmd} err]} then {
	    log-error "Connexion to database lost in toposqlselect ($err)"
	    catch {pg_disconnect $ctxt(dbfd$chan)}
	    set ctxt(dbfd$chan) ""
	    set r 0
	} else {
	    set r 1
	}
    } else {
	set r 0
    }
    return $r
}

#
# Execute a SQL request to modify data (INSERT, UPDATE or DELETE, as
# with pg_exec) and manage database reconnect
#
# Input: 
#   - sql : SQL request
#   - chan : optionnal channel (1 or 2)
# Output: 
#   - return value: 1 if ok, 0 if error
#
# History
#   2010/10/20 : pda/jean : design
#

proc toposqlexec {sql {chan 1}} {
    global ctxt

    if {[lazy-connect]} {
	if {[catch {pg_exec $ctxt(dbfd$chan) $sql} res]} then {
	    log-error "Connection to database lost in toposqlexec ($res)"
	    catch {pg_disconnect $ctxt(dbfd$chan)}
	    set ctxt(dbfd$chan) ""
	    set r 0
	} else {
	    switch -- [pg_result $res -status] {
		PGRES_COMMAND_OK -
		PGRES_TUPLES_OK -
		PGRES_EMPTY_QUERY {
		    set r 1
		    pg_result $res -clear
		}
		default {
		    set err [pg_result $res -error]
		    pg_result $res -clear
		    log-error "Internal error in toposqlexec. Connexion to database lost ($err)"
		    catch {pg_disconnect $ctxt(dbfd$chan)}
		    set ctxt(dbfd$chan) ""
		    set r 0
		}
	    }
	}
    } else {
	set r 0
    }
    return $r
}

#
# Start a SQL transaction and manage database reconnect
#
# Input: 
#   - chan : optionnal channel (1 or 2)
# Output: 
#   - return value: 1 if ok, 0 if error
#
# History
#   2010/10/21 : pda/jean : design
#

proc toposqllock {{chan 1}} {
    return [toposqlexec "START TRANSACTION" $chan]
}

#
# End a SQL transaction and manage database reconnect
#
# Input: 
#   - commit : "commit" or "abort"
# Output: 
#   - return value: 1 if ok, 0 if error
#
# History
#   2010/10/21 : pda/jean : design
#

proc toposqlunlock {commit {chan 1}} {
    switch $commit {
	commit { set sql "COMMIT WORK" }
	abort  { set sql "ABORT WORK" }
    }
    return [toposqlexec $sql $chan]
}


##############################################################################
# Topo*d mail management
##############################################################################

#
# Send a mail if event message changes
#
# Input:
#   - ev : event ("rancid", "anaconf", etc.)
#   - msg : event message
# Output:
#   - none
#
# History
#   2010/10/21 : pda/jean : design
#

proc keep-state-mail {ev msg} {
    #
    # Get previous message
    #

    set oldmsg ""
    set qev [::pgsql::quote $ev]
    set sql "SELECT message FROM topo.keepstate WHERE type = '$qev'"
    if {! [toposqlselect $sql tab { set oldmsg $tab(message) } 2]} then {
	# we don't know what to do...
	return
    }

    if {$msg ne $oldmsg} then {
	#
	# New message is different from previous one. We must
	# send it by mail and store it in keepstate table.
	#
	# Design choice: if database access is out of order, we
	# can't access keepstate. The choice is to not send mail.
	# The risk is we won't known new messages, but the advantage
	# is that our mailboxes will not be polluted by a new
	# identical mail every X seconds. On the other hand, risk
	# is minimized by the fact that no new change will be detected
	# and/or processed while database is out of order.
	#

	set qmsg [::pgsql::quote $msg]
	set sql "DELETE FROM topo.keepstate WHERE type = '$qev' ;
		    INSERT INTO topo.keepstate (type, message)
			    VALUES ('$qev', '$qmsg')"
	if {[toposqlexec $sql 2]} then {
	    #
	    # Database access is ok. Send the mail.
	    #

	    set from    [::dnsconfig get "topofrom"]
	    set to	[::dnsconfig get "topoto"]
	    set replyto	""
	    set cc	""
	    set bcc	""
	    set subject	"\[auto\] topod status changed for $ev"
	    ::webapp::mail $from $replyto $to $cc $bcc $subject $msg
	}
    }
}

##############################################################################
# Equipment types
##############################################################################

#
# Read type and model for all equipments in the graph.
#
# Input:
#   - _tabeq : name of array containing, in return, types and models
# Output:
#   - return value: empty string or error message
#   - tabeq : array, indexed by FQDN of equipement, containing:
#	tabeq(<eq>) {<type> <model>}
# 
# History
#   2010/02/25 : pda/jean : design
#   2010/10/21 : pda/jean : manage only fully qualified host names
#

set libconf(dumpgraph-read-eq-type) "dumpgraph -a -o eq"

proc read-eq-type {_tabeq} {
    global libconf
    upvar $_tabeq tabeq

    set-status "Reading equipement types"

    set defdom [dnsconfig get "defdomain"]

    set cmd $libconf(dumpgraph-read-eq-type)

    if {[call-topo $cmd msg]} then {
	foreach line [split $msg "\n"] {
	    switch [lindex $line 0] {
		eq {
		    array set t $line
		    set eq $t(eq)
		    set type $t(type)
		    set model $t(model)

		    append eq ".$defdom"

		    set tabeq($eq) [list $type $model]

		    array unset t
		}
	    }
	}
	set msg ""
    }

    return $msg
}

##############################################################################
# Detection of modifications in files
##############################################################################

#
# Detect modifications in a directory
#
# Input:
#   - dir : directory path
#   - _err : in return, empty string or error message
# Output:
#   - return value : list {{<code> <file> <date>} {<code> <file> <date>}...}
#	where <code> = "add", "del", "mod" or "err"
#	and <date> = date in clock_t format
#	if <code> = "err", error message is in "<date>"
#   - parameter err : in return, all error messages
# 
# History 
#   2010/11/12 : pda/jean : design
#

proc detect-dirmod {dir _err} {
    upvar $_err err

    set err ""

    #
    # First pass: get all files in directory and keep them in an array:
    #	ntab(<file>) <date>
    #
    foreach file [glob -nocomplain "$dir/*.eq"] {
	if {[catch {file mtime $file} date]} then {
	    append err "$date\n"
	} else {
	    set ntab($file) $date
	}
    }

    #
    # Second pass: get all files in database for this directory and
    # keep them in an array:
    #	otab(<file>) <date>
    #
    set sql "SELECT path, date FROM topo.filemonitor
				WHERE path ~ '^$dir/\[^/\]+$'"
    if {! [toposqlselect $sql tab { set otab($tab(path)) [clock scan $tab(date)] }]} then {
	append err "Cannot execute SQL SELECT query for $dir\n"
	return {}
    }

    #
    # Difference analysis
    #
    set r {}
    if {$err eq ""} then {
	foreach f [array names otab] {
	    if {[info exists ntab($f)]} then {
		if {$otab($f) != $ntab($f)} then {
		    lappend r [list "mod" $f $ntab($f)]
		}
		unset ntab($f)
	    } else {
		lappend r [list "del" $f ""]
	    }
	    unset otab($f)
	}

	foreach f [array names ntab] {
	    lappend r [list "add" $f $ntab($f)]
	}
    }

    return $r
}

#
# Detect if a file has been modified
#
# Input:
#   - path : directory path
# Output:
#   - return value : see detect-dirmod
#
# History 
#   2010/11/12 : pda/jean : design
#

proc detect-filemod {path} {
    set oldfmod -1
    set qpath [::pgsql::quote $path]
    set sql "SELECT date FROM topo.filemonitor WHERE path = '$qpath'"
    if {[toposqlselect $sql tab {set oldfmod [clock scan $tab(date)]}]} then {
	if {[catch {file mtime $path} newfmod]} then {
	    #
	    # Error: we suppose that file does not exist
	    #
	    if {$oldfmod == -1} then {
		# file did not exist before, does not exists now
		set r [list "err" $path "Error on '$path': $newfmod"]
	    } else {
		# file was existing, but not now
		set r [list "del" $path ""]
	    }
	    set newfmod ""
	} else {
	    #
	    # File exists
	    #
	    if {$oldfmod == -1} then {
		# the file is new
		set r [list "add" $path $newfmod]
	    } elseif {$oldfmod == $newfmod} then {
		# dates are the same: file has not been modified
		set r {}
	    } else {
		# file is modified
		set r [list "mod" $path $newfmod]
	    }
	}
    } else {
	set r [list $path "err" "Error on '$path' : SQL query failed"]
    }
    topo-verbositer "detect-filemod: $path => $r" 9

    return $r
}

#
# Update file modification times in database
#
# Input:
#   - lf : list (see detect-dirmod for format)
# Output:
#   - return value : 1 if ok, 0 if error
# 
# History 
#   2010/11/12 : pda/jean : design
#

proc sync-filemonitor {lf} {
    set sql {}
    foreach f $lf {
	lassign $f code path date
	set qpath [::pgsql::quote $path]
	switch $code {
	    add {
		set qdate [clock format $date]
		lappend sql "INSERT INTO topo.filemonitor (path, date)
					VALUES ('$qpath', '$qdate')"
	    }
	    mod {
		set qdate [clock format $date]
		lappend sql "UPDATE topo.filemonitor
					SET date = '$qdate'
					WHERE path = '$qpath'"
	    }
	    del {
		lappend sql "DELETE FROM topo.filemonitor
					WHERE path = '$qpath'"
	    }
	}
    }
    set r 1
    if {[llength $sql] > 0} then {
	set sql [join $sql ";"]
	set r [toposqlexec $sql]
    }

    return $r
}
