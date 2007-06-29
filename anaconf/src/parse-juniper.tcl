#
# $Id: parse-juniper.tcl,v 1.3 2007-06-29 15:44:14 jean Exp $
#
# Package d'analyse de fichiers de configuration JunOS
#
# Historique
#   2004/03/22 : pda/jean : début de la conception
#   2004/03/26 : pda/jean : fin de la rédaction
#   2004/06/08 : pda/jean : changement de format du fichier de sortie
#   2004/09/24 : pda/jean : nb d'arg variable pour les routes statiques
#   2005/04/04 : pda      : ajout family address arp
#   2005/06/01 : pda      : ajout family inet policer
#   2006/05/26 : pda/jean : ajout des points de collecte de métrologie
#   2006/06/01 : pda/jean : ajout snmp
#   2007/01/06 : pda      : ajout desc interface
#

###############################################################################
# Fonctions utilitaires
###############################################################################

proc juniper-init {} {
    global juniper_masques
    global juniper_where
    global juniper_debuglevel

    # masques(24) {0xff 0xff 0xff 0x00 0x00 ... 0x00 }
    # masques(25) {0xff 0xff 0xff 0x80 0x00 ... 0x00 }
    # masques(64) {0xff 0xff 0xff 0xff 0xff 0xff 0xff 0xff 0x00 ... 0x00 }

    for {set i 1} {$i <= 128} {incr i} {
	set juniper_masques($i) {}
	set v 0
	for {set j 0} {$j < 128} {incr j} {
	    if {$j < $i} then {
		set v [expr (($v << 1) | 1)]
	    } else {
		set v [expr (($v << 1) | 0)]
	    }
	    if {$j % 8 == 7} then {
		set juniper_masques($i) [concat $juniper_masques($i) $v]
		set v 0
	    }
	}
    }

    set juniper_where {}
    set juniper_debuglevel 0
}

proc juniper-warning {msg} {
    global juniper_where

    if {[llength $juniper_where] > 0} then {
	puts -nonewline stderr "$juniper_where: "
    }
    puts stderr "$msg"
}

proc juniper-debug {msg} {
    juniper-warning $msg
}


proc juniper-read-conf {fd} {
    set conf ""
    while {[gets $fd ligne] > -1} {
	regsub { ## SECRET-DATA$} $ligne {} ligne
	if {! [regexp {/\*.*\*/} $ligne]} then {
	    regsub -all { \[ (.*) \];$} $ligne { { \1 } ;} ligne
	    regsub -all {;$} $ligne { { } } ligne
	    append conf "\n $ligne"
	}
    }
    return $conf
}



#
# Convertit une adresse au format Juniper (adr d'i/f + "/" + longueur préfixe)
# en un CIDR de réseau.
#
# Entrée :
#   - ifadr : adresse au format Juniper
# Sortie :
#   - valeur de retour : cidr de réseau ou chaîne vide en cas d'erreur
#
# Historique
#   2004/03/25 : pda/jean : conception
#   2004/03/26 : pda/jean : documentation
#

proc juniper-convert-ifadr-to-cidr {ifadr} {
    global juniper_masques

    if {! [regexp {^(.*)/(.*)$} $ifadr bidon adr preflen]} then {
	juniper-warning "invalid interface address ($ifadr)"
	return ""
    }

    set v6 [regexp ":" $adr]

    if {$v6} then {
	# Elimination des cas particuliers des adresses contenant
	# un "::" situé au début ou à la fin de l'adresse
	regsub {^::} $adr {0::} adr
	regsub {::$} $adr {::0} adr

	# Traitement du cas particulier des adresses compatibles
	# IPv4 : on les transforme en adresses en format IPv6
	# (i.e. uniquement avec de l'hexa séparé par des ":")
	set l [split $adr ":"]

	# cas particulier des adresses compatibles v4 (dernier = a.b.c.d)
	set ip4 [split [lindex $l end] "."]
	if {[llength $ip4] == 4} then {
	    set l [lreplace $l end end]
	    set p1 [format "%x" [expr [lindex $ip4 0] * 256 + [lindex $ip4 1]]]

	    lappend l $p1
	    set p2 [format "%x" [expr [lindex $ip4 2] * 256 + [lindex $ip4 3]]]
	    lappend l $p2
	}

	# Traitement du cas des "::" dans l'adresse
	set n [llength $l]
	set lg0 [expr 8 - $n]
	set posvide [lsearch $l {}]
	if {$posvide >= 0} then {
	     set l [concat [lrange $l 0 [expr $posvide - 1]] \
				[lrange {0 0 0 0 0 0 0 0} 0 $lg0] \
				[lrange $l [expr $posvide + 1] end] \
			]
	}
	# A ce stade, l est une liste de 8 valeurs sur 16 bits en hexa (sans 0x)

	# Transformer chaque élément en octet (en décimal)
	set nl {}
	foreach e $l {
	    lappend nl [expr ((0x$e >> 8) & 0xff)]
	    lappend nl [expr (0x$e & 0xff)]
	}

	# A ce stade, nl est une liste de 16 octets en décimal
	set m $juniper_masques($preflen)
	set na {}
	for {set i 0} {$i < 16} {incr i} {
	    lappend na [expr [lindex $nl $i] & [lindex $m $i]]
	}

	# Reconstituer l'adresse IPv6
	set l {}
	for {set i 0} {$i < 8} {incr i} {
	    set o1 [lindex $na [expr $i * 2]]
	    set o2 [lindex $na [expr ($i * 2) + 1]]
	    lappend l [format "%x" [expr ($o1 << 8) + $o2]]
	}
	set a [join $l ":"]

	# supprimer les 0 finaux
	regsub -expanded {(:0)+$} $a {::} a

	set na $a
    } else {
	#
	# IPv4
	#
	set a [split $adr "."]
	set m $juniper_masques($preflen)
	set na {}
	for {set i 0} {$i < 4} {incr i} {
	    lappend na [expr [lindex $a $i] & [lindex $m $i]]
	}
	set na [join $na "."]
    }

    return "$na/$preflen"
}

#
# Teste l'appartenance d'une adresse IP (v4 ou v6) à un réseau
#
# Entrée :
#   - adr : adresse à tester
#   - cidr : cidr du réseau
# Sortie :
#   - valeur de retour : -1 (erreur), 1 (appartenance) ou 0 (pas d'appartenance)
#
# Historique
#   2004/03/25 : pda/jean : conception
#   2004/03/26 : pda/jean : documentation
#

proc juniper-match-network {adr cidr} {
    if {! [regexp {^(.*)/(.*)$} $cidr bidon bidon2 preflen]} then {
	juniper-warning "invalid network address ($cidr)"
	set r -1
    } else {
	set na [juniper-convert-ifadr-to-cidr "$adr/$preflen"]
	set r [string equal $na $cidr]
    }
    return $r
}

###############################################################################
# Analyse du fichier de configuration
###############################################################################

#
# Entrée :
#   - model : modèle de l'équipement (ex: M20)
#   - fdin : descripteur de fichier en entrée
#   - fdout : descripteur de fichier pour la génération
#   - conf : { interfaces ... system ... etc }
#   - eq : <eqname>
# Remplit :
#   - tab(eq)	{<eqname> ... <eqname>}
#
# Historique
#   2004/03/23 : pda/jean : conception
#   2004/06/08 : pda/jean : ajout de model
#

proc juniper-parse {debug model fdin fdout tab eq} {
    global juniper_debuglevel
    upvar $tab t

    array set kwtab {
	version		{2	NOP}
	interfaces	{1	juniper-parse-interfaces}
	routing-options	{1	juniper-parse-routing-options}
	snmp		{1	juniper-parse-snmp}
	*		{1	NOP}

    }

    set conf [juniper-read-conf $fdin]

    # le nom de l'équipement en cours d'analyse
    lappend t(eq) $eq

    set juniper_debuglevel $debug
    set error [juniper-parse-list kwtab $conf t "eq!$eq"]

    if {! $error} then {
	set error [juniper-post-process $model $fdout $eq t]
    }

    return $error
}

#
# Analyse un extrait de conf JunOS
#
# Entrée :
#   - kwtab : tableau des mots-clefs autorisés dans la fonction, sous la
#	forme kwtab(<kw>) { <nb args> <fct d'analyse> }
#		si <nb-args> n'est pas un entier, il s'agit d'une fonction
#		que l'on appelle, et qui doit retourner le nb d'arguments
#   - tab : tableau contenant les informations résultant de l'analyse
#   - conf : extrait de conf
#   - idx : index dans le tableau tab
#   - variable globale juniper_debuglevel : si > 0, affiche tous les
#		mots-clefs en cours d'analyse de profondeur >= niveau demandé
# Sortie :
#   - valeur de retour : 1 si erreur, 0 sinon
#
# Historique
#   2004/03/25 : pda/jean : conception (ouh la la !)
#

proc juniper-parse-list {kwtab conf tab idx} {
    global juniper_where
    global juniper_debuglevel
    upvar $kwtab k
    upvar $tab t

    set inactive 0
    set error 0
    while {[llength $conf] > 0} {
	set kw [lindex $conf 0]

	if {$juniper_debuglevel > 0 &&
		[llength $juniper_where] >= $juniper_debuglevel} then {
	    juniper-debug "kw = <$kw>"
	}

	if {[string equal $kw "inactive:"]} then {
	    set inactive 1
	    set last 0
	} else {
	    if {[info exists k($kw)]} then {
		set l $k($kw)
	    } else {
		set l $k(*)
	    }
	    set last [lindex $l 0]
	    if {! [regexp {^[0-9]+$} $last]} then {
		set fct $last
		if {[catch [list $fct $conf t $idx] last]} then {
		    juniper-warning "$idx: error while fetching arg count ($kw)"
		    set last end
		    set inactive 1
		}
	    }
	    if {! $inactive} then {
		set fct  [lindex $l 1]
		switch $fct {
		    NOP {
			set error 0
		    }
		    ERROR {
			juniper-warning "$idx: unrecognized keyword ($kw)"
			set error 1
		    }
		    default {
			lappend juniper_where $kw
			set error [$fct $conf t $idx]
			set juniper_where [lreplace $juniper_where end end]
		    }
		}

		if {$error} then {
		    break
		}
	    }
	    set inactive 0
	}
	set conf [lreplace $conf 0 $last]
    }
    return $error
}


#
# Entrée :
#   - conf = <ifname> { <parm> } <ifname> { <parm> } ...
#   - idx = eq!<eqname>
# Remplit
#   - tab(eq!<nom eq>!if) {<ifname> ... <ifname>}
#
# Historique
#   2004/03/23 : pda/jean : conception
#   2005/05/26 : pda      : ignorer l'i/f tap
#

proc juniper-parse-interfaces {conf tab idx} {
    upvar $tab t

    array set kwtab {
	fxp0		{1	NOP}
	fxp1		{1	NOP}
	lo0		{1	NOP}
	tap		{1	NOP}
	traceoptions	{1	NOP}
	*		{1	juniper-parse-if}
    }

    return [juniper-parse-list kwtab [lindex $conf 1] t "$idx"]
}


#
# Entrée :
#   - idx = eq!<eqname>
#   - conf = { description <desc> unit <nb> { ... } etc }
# Remplit :
#   A VOIR
#   - tab(eq!<nom eq>!if!<ifname>!units) { <unitnb> ... }
#   - tab(eq!<nom eq>!if!<ifname>!link!name) <link-name>
#   - tab(eq!<nom eq>!if!<ifname>!link!vlans) {<vlanid> ... <vlanid>}
#

proc juniper-parse-if {conf tab idx} {
    upvar $tab t

    array set kwtab {
	description		{2	juniper-parse-if-descr}
	unit			{2	juniper-parse-if-unit}
	gigether-options	{1	juniper-parse-if-gigopt}
	aggregated-ether-options {1	NOP}
	vlan-tagging		{1	juniper-parse-if-vlan-tagging}
	traceoptions		{1	NOP}
	*			{2	ERROR}
    }

    set ifname [lindex $conf 0]
    set ifparm [lindex $conf 1]

    lappend t($idx!if) $ifname
    set idx "$idx!if!$ifname"

    set error [juniper-parse-list kwtab $ifparm t $idx]

    if {! [info exists t($idx!link!type)]} then {
	set t($idx!link!type) "ether"
    }

    if {! $error} then {
	foreach l {
			{!link!name {link name in 'description'}}
		    } {
	set v [lindex $l 0]
	set d [lindex $l 1]
	    if {! [info exists t($idx$v)]} then {
		juniper-warning "$idx: $d not found"
		set error 1
	    }
	}
    }

    return $error
}

#
# Entrée :
#   - idx = eq!<eqname>!if!<ifname>
# Remplit :
#   tab(eq!<eqname>!if!<ifname>!link!name) <linkname>
#   tab(eq!<nom eq>!if!<ifname>!link!stat) <statname> ou vide
#   tab(eq!<nom eq>!if!<ifname>!link!desc) <desc>
#
# Historique :
#   2004/03/23 : pda/jean : conception
#   2006/05/23 : pda/jean : ajout de stat
#   2007/01/06 : pda      : ajout de desc
#

proc juniper-parse-if-descr {conf tab idx} {
    upvar $tab t

    set line [lindex $conf 1]

    if {[parse-desc $line linkname statname descname msg]} then {
	if {[string equal $linkname ""]} then {
	    juniper-warning "$idx: no link name found ($line)"
	    set error 1
	} else {
	    set t($idx!link!name) $linkname
	    set t($idx!link!stat) $statname
	    set t($idx!link!desc) $descname
	    set error 0
	}
    } else {
	juniper-warning "$idx: $msg ($line)"
	set error 1
    }

    return $error
}

#
# Entrée :
#   - idx = eq!<eqname>!if!<ifname>
# Remplit :
#   tab(eq!<eqname>!if!<ifname>!vlans) {<vlan-id> ...}
#   A VOIR
#

proc juniper-parse-if-unit {conf tab idx} {
    upvar $tab t

    array set kwtab {
	description	{2	juniper-parse-unit-descr}
	vlan-id		{2	juniper-parse-vlan-id}
	family		{2	juniper-parse-family}
	tunnel		{1	NOP}
	*		{2	ERROR}
    }

    set unitnb   [lindex $conf 1]
    set unitparm [lindex $conf 2]

    set t(current!unitnb) $unitnb
    set t($idx!vlan!$unitnb!stat) ""
    set error [juniper-parse-list kwtab $unitparm t "$idx"]
    unset t(current!unitnb)

    return $error
}

#
# Entrée :
#   - idx = eq!<eqname>!if!<ifname>
#   - tab(current!unitnb) = <unit number>
# Remplit :
#   tab(eq!<nom eq>!if!<ifname>!vlan!<vlan-id>!stat) <statname> ou vide
#
# Historique :
#   2006/05/26 : pda/jean : conception
#

proc juniper-parse-unit-descr {conf tab idx} {
    upvar $tab t

    set unitnb $t(current!unitnb)
    set line [lindex $conf 1]

    if {[parse-desc $line linkname statname descname msg]} then {
	#
	# 1) linkname peut contenir n'importe quoi (compatibilité avec
	#    l'ancienne syntaxe), donc on l'ignore
	# 2) on fait toujours l'approximation : numéro d'unité = no de vlan
	# 3) même s'il n'y a pas de définition d'un point de collecte
	#    de métrologie (statname = chaîne vide), on remplit
	#    le tableau
	#
	set t($idx!vlan!$unitnb!stat) $statname
	set error 0
    } else {
	juniper-warning "$idx: $msg ($line)"
	set error 1
    }

    return $error
}


#
# Entrée :
#   - idx = eq!<eqname>!if!<ifname>
#   - tab(current!unitnb) = <unit number>
# Remplit :
#   tab(eq!<eqname>!if!<ifname>!vlans) {<vlan-id> ...}
#
# Historique :
#   2004/03/23 : pda/jean : conception
#

proc juniper-parse-vlan-id {conf tab idx} {
    upvar $tab t

    set unitnb $t(current!unitnb)
    set parm [lindex $conf 1]

    # approximation : numéro d'unité = no de vlan
    if {$unitnb != $parm} then {
	juniper-warning "$idx: vlan-id $parm does not match unit $unitnb"
	return 1
    }

    lappend t($idx!vlans) $unitnb
    return 0
}

#
# Entrée :
#   - idx = eq!<eqname>!if!<ifname>
#   - tab(current!unitnb) = <unit number>
# Remplit :
#   tab(eq!<eqname>!if!<ifname>!vlan!<unitnb>!adr) {<adr46> ...}
#
#   tab(eq!<eqname>!if!<ifname>!vlan!<unitnb>!networks) {<cidr46> ...}
#   tab(eq!<eqname>!if!<ifname>!vlan!<unitnb>!net!<cidr46>) { <adr46> [<poidsvrrp> <virtadr>]}
#

proc juniper-parse-family {conf tab idx} {
    upvar $tab t

    set fam [lindex $conf 1]
    switch $fam {
	inet -
	inet6 {
	    array set kwtab {
		filter		{1	NOP}
		sampling	{1	NOP}
		policer		{1	NOP}
		address		{2	juniper-parse-if-address}
		*		{2	NOP}
	    }
	    set unitnb $t(current!unitnb)
	    set parm [lindex $conf 2]
	    set error [juniper-parse-list kwtab $parm t "$idx!vlan!$unitnb"]
	}
	mpls -
	iso {
	    set error 0
	}
	default {
	    juniper-warning "$idx: family '$kw' not supported"
	    set error 1
	}
    }
    return $error
}


#
# Entrée :
#   - idx = eq!<eqname>!if!<ifname>!unit!<unitnb>
# Remplit :
#   tab(eq!<eqname>!if!<ifname>!vlan!<unitnb>!networks) {<cidr46> ...}
#   tab(eq!<eqname>!if!<ifname>!vlan!<unitnb>!net!<cidr46>) <adr46>
#   tab(eq!<eqname>!if!<ifname>!vlan!<unitnb>!net!<cidr46>!preflen) <preflen>
#

proc juniper-parse-if-address {conf tab idx} {
    upvar $tab t

    array set kwtab {
	vrrp-group	{2	juniper-parse-vrrp}
	arp		{4	NOP}
	destination	{2	NOP}
	*		{2	ERROR}
    }

    set parm [lindex $conf 1]
    if {! [regexp {^(.*)/(.*)$} $parm bidon ifadr preflen]} then {
	juniper-warning "$idx: invalid address ($parm)"
    }
    set cidr [juniper-convert-ifadr-to-cidr $parm]
    if {[string equal $cidr ""]} then {
	set error 1
    } else {
	lappend t($idx!networks) $cidr
	set idx "$idx!net!$cidr"
	set t($idx) $ifadr
	set t($idx!preflen) $preflen
	set error [juniper-parse-list kwtab [lindex $conf 2] t "$idx"]
    }

    return $error
}

#
# Entrée :
#   - idx = eq!<eqname>!if!<ifname>!net!<cidr>
# Remplit :
#   - rien
#
# Historique :
#   2004/03/23 : pda/jean : conception
#

proc juniper-parse-vrrp {conf tab idx} {
    upvar $tab t

    array set kwtab {
	virtual-address		{2	juniper-parse-vrrp-vadr}
	priority		{2	juniper-parse-vrrp-prio}
	accept-data		{1	NOP}
	*			{2	NOP}
    }

    return [juniper-parse-list kwtab [lindex $conf 2] t $idx]
}

#
# Entrée :
#   - idx = eq!<eqname>!if!<ifname>!net!<cidr>
# Remplit :
#   - tab(eq!<eqname>!if!<ifname>!net!<cidr>!vrrp!virtual) <adrvirt>
#
# Historique :
#   2004/03/25 : pda/jean : conception
#

proc juniper-parse-vrrp-vadr {conf tab idx} {
    upvar $tab t

    set t($idx!vrrp!virtual) [lindex $conf 1]
    return 0
}

#
# Entrée :
#   - idx = eq!<eqname>!if!<ifname>!net!<cidr>
# Remplit :
#   - tab(eq!<eqname>!if!<ifname>!net!<cidr>!vrrp!priority) <prio>
#
# Historique :
#   2004/03/25 : pda/jean : conception
#

proc juniper-parse-vrrp-prio {conf tab idx} {
    upvar $tab t

    set t($idx!vrrp!priority) [lindex $conf 1]
    return 0
}

#
# Entrée :
#   - idx = eq!<eqname>!if!<ifname>
# Remplit :
#   - rien
#
# Historique :
#   2004/03/23 : pda/jean : conception
#

proc juniper-parse-if-gigopt {conf tab idx} {
    upvar $tab t

    array set kwtab {
	802.3ad		{2	juniper-parse-802-3ad}
	*		{2	ERROR}
    }

    return [juniper-parse-list kwtab [lindex $conf 1] t $idx]
}

#
# Entrée :
#   - idx = eq!<eqname>!if!<ifname>
# Remplit :
#   - tab(eq!<eqname>!if!<ifname>!link!type) aggregate
#   - tab(eq!<eqname>!if!<ifname>!link!ifname) <ifname2>
#
# Historique :
#   2004/03/23 : pda/jean : conception
#

proc juniper-parse-802-3ad {conf tab idx} {
    upvar $tab t

    set ifname [lindex $conf 1]
    set t($idx!link!type) "aggregate"
    set t($idx!link!ifname) $ifname
    return 0
}

#
# Entrée :
#   - idx = eq!<eqname>!if!<ifname>
# Remplit :
#   - tab(eq!<eqname>!if!<ifname>!link!type) trunk
#
# Historique :
#   2004/03/23 : pda/jean : conception
#

proc juniper-parse-if-vlan-tagging {conf tab idx} {
    upvar $tab t

    set t($idx!link!type) "trunk"
    return 0
}

#
# Entrée :
#   - idx = eq!<eqname>
# Remplit :
#   - rien
#
# Historique :
#   2004/03/25 : pda/jean : conception
#

proc juniper-parse-routing-options {conf tab idx} {
    upvar $tab t

    array set kwtab {
	rib			{2	NOP}
	static			{1	juniper-parse-static-routes}
	autonomous-system	{2	NOP}
	*			{1	NOP}
    }

    return [juniper-parse-list kwtab [lindex $conf 1] t $idx]
}

#
# Entrée :
#   - idx = eq!<eqname>
# Remplit :
#   - rien
#
# Historique :
#   2004/03/25 : pda/jean : conception
#

proc juniper-parse-static-routes {conf tab idx} {
    upvar $tab t

    array set kwtab {
	route		{juniper-parse-count-route juniper-parse-route-entry}
	*		{1	ERROR}
    }

    return [juniper-parse-list kwtab [lindex $conf 1] t $idx]
}

#
# Entrée :
#   - idx = eq!<eqname>
# Remplit :
#   - tab(eq!<eqname>!static!gw) {<gwadr46> ... }
#   - tab(eq!<eqname>!static!<gwadr46>) {<cidr46> ... }
#
# Historique :
#   2004/03/25 : pda/jean : conception
#   2004/03/26 : pda/jean : inversion des données dans le tableau
#   2004/09/21 : pda/jean : nb d'arguments variable pour les entrées statiques
#

# cette fonction ne fait que retourner le nombre d'arguments
proc juniper-parse-count-route {conf tab idx} {
    upvar $tab t

    set n 2
    if {[string equal [lindex $conf 2] "next-hop"]} then {
	set n 4
    }
    return $n
}


proc juniper-parse-route-entry {conf tab idx} {
    upvar $tab t

    set cidr  [lindex $conf 1]

    if {[string equal [lindex $conf 2] "next-hop"]} then {
	set gwadr [lindex $conf 3]
	if {[llength $gwadr] > 1} then {
	    # XXX : il y a plusieurs passerelles pour cette route
	    # on ne conserve que la première
	    set gwadr [lindex $gwadr 0]
	}

	if {! [info exists t($idx!static!$gwadr)]} then {
	    lappend t($idx!static!gw) $gwadr
	}
	lappend t($idx!static!$gwadr) $cidr
    }

    return 0
}



#
# Entrée :
#   - idx = eq!<eqname>
# Remplit :
#   - rien
#
# Historique :
#   2006/06/01 : pda/jean : conception
#

proc juniper-parse-snmp {conf tab idx} {
    upvar $tab t

    array set kwtab {
	community	{2	juniper-parse-snmp-community}
	*		{1	ERROR}
    }

    return [juniper-parse-list kwtab [lindex $conf 1] t $idx]
}

#
# Entrée :
#   - idx = eq!<eqname>
# Remplit :
#   - tab(eq!<eqname>!snmp) {<community string> ... }
#
# Historique :
#   2006/06/01 : pda/jean : conception
#

proc juniper-parse-snmp-community {conf tab idx} {
    upvar $tab t

    set comm  [lindex $conf 1]
    lappend t($idx!snmp) $comm
    return 0
}



###############################################################################
# Traitement après analyse
###############################################################################

#
# Traite le tableau résultant de l'analyse pour permettre d'accéder
# plus facilement aux réseaux (de niveau 3) et aux liens (de niveau 2)
# gérés par cet équipement
#
# Entrée :
#   - model : modèle de l'équipement
#   - fdout : descripteur de fichier pour la génération
#   - eq : nom de l'équipement
#   - tab : tableau rempli au cours de l'analyse
# Sortie :
#   - valeur de retour : 0 si pas d'erreur, 1 si erreur
#   - tab : tableau modifié
#
# Historique
#   2004/03/26 : pda/jean : conception
#   2004/06/08 : pda/jean : ajout du modèle
#   2004/06/08 : pda/jean : changement de format du fichier de sortie
#   2006/06/01 : pda/jean : ajout snmp
#   2006/08/21 : pda/pegon : liens X+X+X+...+X deviennent X
#   2007/01/06 : pda       : ajout desc interface
#

proc juniper-post-process {model fdout eq tab} {
    upvar $tab t

    set fmtnode "$eq:%d"
    set numnode 0

    if {[info exists t(eq!$eq!snmp)]} then {
	# XXX : on ne prend que la première communauté trouvée
	set c [lindex $t(eq!$eq!snmp) 0]
    } else {
	set c "-"
    }
    puts $fdout "eq $eq type juniper model $model snmp $c"

    #
    # Chercher tous les liens. Pour cela, parcourir la liste
    # des interfaces
    #
    catch {unset agtab}

    # première boucle pour constituer les noms des liens agrégés
    foreach iface $t(eq!$eq!if) {
	set linkname $t(eq!$eq!if!$iface!link!name)
	set linktype $t(eq!$eq!if!$iface!link!type)
	if {[string equal $linktype "aggregate"]} then {
	    set parentif $t(eq!$eq!if!$iface!link!ifname)
	    lappend agtab($parentif) $linkname
	}
    }

    # XXX : pour l'instant, il n'y a qu'une seule instance de routage
    # dans *nos* Juniper...
    # En fait, il y en a deux : la "default" pour v4 et la "default" pour v6

    set nodeR4 ""
    set nodeR6 ""

    #
    # deuxième boucle pour retrouver les liens de niveau 2
    # (sans le détail des constituants d'un lien agrégé)
    # Parcourir la liste des interfaces.
    #

    foreach iface $t(eq!$eq!if) {
	if {[info exists agtab($iface)]} then {
	    #
	    # Si tous les liens sont "X", constituer un lien "X"
	    # au lieu d'un lien "X+X+X+..+X"
	    #
	    set tousX 1
	    foreach l $agtab($iface) {
		if {! [string equal $l "X"]} then {
		    set tousX 0
		    break
		}
	    }
	    if {$tousX} then {
		set linkname "X"
	    } else {
		set linkname [join [lsort $agtab($iface)] "+"]
	    }
	} else {
	    set linkname $t(eq!$eq!if!$iface!link!name)
	}
	set statname $t(eq!$eq!if!$iface!link!stat)
	if {[string equal $statname ""]} then {
	    set statname "-"
	}
	set desc $t(eq!$eq!if!$iface!link!desc)
	if {[string equal $desc ""]} then {
	    set desc "-"
	}
	set linktype $t(eq!$eq!if!$iface!link!type)

	if {! [string equal $linktype "aggregate"]} then {
	    switch $linktype {
		ether {
		    # VLAN = 0 pour un lien Ether
		    set arg 0
		}
		trunk {
		    # Liste des vlans pour ce lien
		    set arg $t(eq!$eq!if!$iface!vlans)
		}
		default {
		    juniper-warning "Unknown link type for '$eq/$iface"
		}
	    }

	    set nodeL1 [format $fmtnode [incr numnode]]

	    puts $fdout "node $nodeL1 type L1 eq $eq name $iface link $linkname encap $linktype stat $statname desc $desc"

	    foreach v $arg {
		#
		# Interconnexion des VLAN aux interfaces physiques
		#
		set nodeL2 [format $fmtnode [incr numnode]]
		set t(eq!$eq!if!$iface!vlan!$v!node) $nodeL2
		set statname $t(eq!$eq!if!$iface!vlan!$v!stat)
		if {[string equal $statname ""]} then {
		    set statname "-"
		}
		puts $fdout "node $nodeL2 type L2 eq $eq vlan $v stat $statname"
		puts $fdout "link $nodeL1 $nodeL2"

		#
		# Parcourir la liste des réseaux supportés par cette
		# sous-interface.
		#
		foreach cidr $t(eq!$eq!if!$iface!vlan!$v!networks) {
		    set ifname "$iface.$v"
		    set idx "eq!$eq!if!$iface!vlan!$v!net!$cidr"

		    # récupérer l'adresse du routeur dans ce réseau
		    # (i.e. l'adresse IP de l'interface)
		    set gwadr $t($idx)
		    set preflen $t($idx!preflen)
		    set nodeL3 [format $fmtnode [incr numnode]]

		    puts $fdout "node $nodeL3 type L3 eq $eq addr $gwadr/$preflen"
		    puts $fdout "link $nodeL3 $nodeL2"

		    if {[string first ":" $gwadr] != -1} then {
			if {[string equal $nodeR6 ""]} then {
			    set nodeR6 [format $fmtnode [incr numnode]]
			    puts $fdout "node $nodeR6 type router eq $eq instance _v6"
			}
			set nodeR $nodeR6
		    } else {
			if {[string equal $nodeR4 ""]} then {
			    set nodeR4 [format $fmtnode [incr numnode]]
			    puts $fdout "node $nodeR4 type router eq $eq instance _v4"
			}
			set nodeR $nodeR4
		    }

		    puts $fdout "link $nodeL3 $nodeR"

		    set static {}

		    # parcourir les passerelles citées dans les routes statiques,
		    # pour déterminer celles qui sont dans *ce* réseau
		    if {[info exists t(eq!$eq!static!gw)]} then {
			foreach gw $t(eq!$eq!static!gw) {
			    set r [ juniper-match-network $gw $cidr]
			    if {$r == -1} then {
				return 1
			    } elseif {$r} then {
				foreach n $t(eq!$eq!static!$gw) {
				    append static "$n $gw "
				}
			    }
			}
		    }

		    # est-ce qu'il y a du VRRP sur cette interface pour ce réseau ?
		    if {[info exists t($idx!vrrp!virtual)]} then {
			set vrrp "$t($idx!vrrp!virtual) $t($idx!vrrp!priority)"
		    } else {
			set vrrp "- -"
		    }

		    puts $fdout "rnet $cidr $nodeR $nodeL3 $nodeL2 $nodeL1 $vrrp $static"
		}
	    }
	}
    }

    return 0
}

###############################################################################
# Initialisation du module
###############################################################################

juniper-init
