#
# Librairie TCL pour l'application de topologie
#
# Historique
#   2006/06/05 : pda      : conception
#

set libconf(topodir)	%TOPODIR%
set libconf(graph)	%GRAPH%

set libconf(dumpgraph)	"%TOPODIR%/bin/dumpgraph < %GRAPH%"

#
# Retourne une liste de vlans dans un tableau
#
# Entrée :
#   - paramètres :
#	- dumpcmd : commande pour afficher le graphe en ascii
#	- _tabvlan : tableau en retour
# Sortie :
#   - valeur de retour : message d'erreur ou chaîne vide
#   - paramètre _tabvlan : tableau indexé par les vlan-ids, contenant :
#	{<desc> {<net> ... <net>}}
#
# Historique
#   2006/06/22 : pda             : conception
#   2007/01/09 : pda             : adaptation au nouveau format
#

proc lire-vlans {_tabvlan} {
    global libconf
    upvar $_tabvlan tabvlan

    if {[catch {set fd [open "|$libconf(dumpgraph)" "r"]} msg]} then {
	return $msg
    }

    while {[gets $fd ligne] > -1} {
	if {[regexp {^vlan ([0-9]+) +(.*)} $ligne bidon id reste]} then {
	    set desc ""
	    set lnet {}
	    while {[llength $reste] > 0} {
		set key [lindex $reste 0]
		set val [lindex $reste 1]
		switch $key {
		    desc {
			if {[string equal $val "-"]} then {
			    set desc ""
			} else {
			    set desc [binary format H* $val]
			}
		    }
		    net {
			lappend lnet $val
		    }
		}
		set reste [lreplace $reste 0 1]
	    }
	    set tabvlan($id) [list $desc $lnet]
	}
    }
    if {[catch {close $fd} msg]} then {
	return $msg
    }
    return ""
}

#
# Retourne une liste de réseaux dans un tableau
#
# Entrée :
#   - paramètres :
#	- dumpcmd : commande pour afficher le graphe en ascii
#	- _tabip : tableau en retour
# Sortie :
#   - valeur de retour : message d'erreur ou chaîne vide
#   - paramètre _tabip : tableau des adresses IP, indexé par les adresses IP
#
# Historique
#   2006/06/22 : pda             : conception
#

proc lire-reseaux {_tabip} {
    global libconf
    upvar $_tabip tabip

    if {[catch {set fd [open "|$libconf(dumpgraph)" "r"]} msg]} then {
	return $msg
    }

    while {[gets $fd ligne] > -1} {
	if {[regexp {^rnet ([^ ]+)} $ligne bidon addr]} then {
	    set tabip($addr) ""
	}
    }
    if {[catch {close $fd} msg]} then {
	return $msg
    }
    return ""
}

#
# Utilitaire pour le tri des adresses IP : compare deux adresses IP
#
# Entrée :
#   - paramètres :
#       - ip1, ip2 : les adresses à comparer
# Sortie :
#   - valeur de retour : -1, 0 ou 1
#
# Historique
#   2006/06/20 : pda             : conception
#   2006/06/22 : pda             : documentation
#

proc comparer-ip {ip1 ip2} {
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
# Indique si une adresse IP est dans une classe
#
# Entrée :
#   - paramètres :
#       - ip : adresse IP (ou CIDR) à tester
#	- net : CIDR de référence
# Sortie :
#   - valeur de retour : 0 (ip pas dans net) ou 1 (ip dans net)
#
# Historique
#   2006/06/22 : pda             : conception
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
    if {[string equal $mask ""]} then {
	set mask $defmask
    }

    set prefnet [::ip::prefix $net]
    regsub {(/[0-9]+)?$} $ip "/$mask" ip2
    set prefip  [::ip::prefix $ip2]

    return [string equal $prefip $prefnet]
}
