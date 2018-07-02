#
#
# Package d'analyse de fichiers de configuration JunOS
#
# Historique
#   2004/03/22 : pda/jean : d�but de la conception
#   2004/03/26 : pda/jean : fin de la r�daction
#   2004/06/08 : pda/jean : changement de format du fichier de sortie
#   2004/09/24 : pda/jean : nb d'arg variable pour les routes statiques
#   2005/04/04 : pda      : ajout family address arp
#   2005/06/01 : pda      : ajout family inet policer
#   2006/05/26 : pda/jean : ajout des points de collecte de m�trologie
#   2006/06/01 : pda/jean : ajout snmp
#   2007/01/06 : pda      : ajout desc interface
#   2009/12/21 : pda/jean : debut analyse junos switch
#   2010/09/01 : pda/jean : analyse des directives voip
#

###############################################################################
# Fonctions utilitaires
###############################################################################

proc juniper-init {} {
    global juniper_masques
    global juniper_where

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
	# remove comment lines
	regsub {^#.*} $ligne {} ligne

	# join bracketed statement running on consecutive lines
	if { [regexp {^\s*\S+\s\[[^\]]*$} $ligne]} then {
		while { ![eof $fd] && ![regexp {\]} $ligne]} {
		    append ligne [gets $fd]
		}
	}

	if {! [regexp {/\*.*\*/} $ligne]} then {
	    regsub -all { \[ (.*) \];$} $ligne { { \1 } ;} ligne
	    regsub -all {;$} $ligne { { } } ligne
	    append conf "\n $ligne"
	}
    }
    return $conf
}

#
# Convertit une adresse au format Juniper (adr d'i/f + "/" + longueur pr�fixe)
# en un CIDR de r�seau.
#
# Entr�e :
#   - ifadr : adresse au format Juniper
# Sortie :
#   - valeur de retour : cidr de r�seau ou cha�ne vide en cas d'erreur
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
	# un "::" situ� au d�but ou � la fin de l'adresse
	regsub {^::} $adr {0::} adr
	regsub {::$} $adr {::0} adr

	# Traitement du cas particulier des adresses compatibles
	# IPv4 : on les transforme en adresses en format IPv6
	# (i.e. uniquement avec de l'hexa s�par� par des ":")
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

	# Transformer chaque �l�ment en octet (en d�cimal)
	set nl {}
	foreach e $l {
	    lappend nl [expr ((0x$e >> 8) & 0xff)]
	    lappend nl [expr (0x$e & 0xff)]
	}

	# A ce stade, nl est une liste de 16 octets en d�cimal
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
# Teste l'appartenance d'une adresse IP (v4 ou v6) � un r�seau
#
# Entr�e :
#   - adr : adresse � tester
#   - cidr : cidr du r�seau
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
# Entr�e :
#   - libdir : r�pertoire contenant les greffons d'analyse
#   - model : mod�le de l'�quipement (ex: M20)
#   - fdin : descripteur de fichier en entr�e
#   - fdout : descripteur de fichier pour la g�n�ration
#   - conf : { interfaces ... system ... etc }
#   - eq : <eqname>
# Remplit :
#   - tab(eq)	{<eqname> ... <eqname>}
#
# Historique
#   2004/03/23 : pda/jean : conception
#   2004/06/08 : pda/jean : ajout de model
#   2008/07/07 : pda/jean : ajout param�tre libdir
#   2009/12/21 : pda/jean : debut analyse junos switch
#

proc juniper-parse {libdir model fdin fdout tab eq} {
    upvar $tab t

    array set kwtab {
	version				{2	NOP}
	groups				{1	NOP}
	apply-groups			{2	NOP}
	apply-groups-except		{2	NOP}
	interfaces			{1	juniper-parse-interfaces}
	snmp				{1	juniper-parse-snmp}
	routing-options			{1	juniper-parse-routing-options}
	ethernet-switching-options	{1	juniper-parse-ethernet-swopt}
	vlans				{1	juniper-parse-vlans}
	bridge-domains			{1	juniper-parse-bridge-domains}
	protocols			{1	juniper-parse-protocols}
	*				{1	NOP}

    }

    set conf [juniper-read-conf $fdin]

    # le nom de l'�quipement en cours d'analyse
    lappend t(eq) $eq

    set t(eq!$eq!if!disabled) {}
    set t(eq!$eq!brcandidate) {}
    set t(eq!$eq!brdomlist) {}
    set t(eq!$eq!ranges) {}
    set t(eq!$eq!voip!if!list) {}

    set error [juniper-parse-list kwtab $conf t "eq!$eq"]

    if {! $error} then {
	set error [juniper-post-process $model $fdout $eq t]
    }

    return $error
}

#
# Analyse un extrait de conf JunOS
#
# Entr�e :
#   - kwtab : tableau des mots-clefs autoris�s dans la fonction, sous la
#	forme kwtab(<kw>) { <nb args> <fct d'analyse> }
#		si <nb-args> n'est pas un entier, il s'agit d'une fonction
#		que l'on appelle, et qui doit retourner le nb d'arguments
#   - tab : tableau contenant les informations r�sultant de l'analyse
#   - conf : extrait de conf
#   - idx : index dans le tableau tab
#   - variable globale debug : affiche tous les mots-clefs en cours d'analyse
# Sortie :
#   - valeur de retour : 1 si erreur, 0 sinon
#
# Historique
#   2004/03/25 : pda/jean : conception (ouh la la !)
#

proc juniper-parse-list {kwtab conf tab idx} {
    global juniper_where
    global debug
    upvar $kwtab k
    upvar $tab t

    set inactive 0
    set error 0
    while {[llength $conf] > 0} {
	set kw [lindex $conf 0]

	if {$debug & 0x01} then {
	    juniper-debug "kw = <$kw>"
	}

	if {[string equal $kw "protect:"]} then {
	    set last 0
	} elseif {[string equal $kw "inactive:"]} then {
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
		if {$debug & 0x04} then {
		    juniper-debug "kw = <$kw>, fct = <$fct>"
		}
		if {$debug & 0x08} then {
		    juniper-debug "kw = <$kw>, fct = <$fct>, conf 0/1 = <[lindex $conf 0]><[lindex $conf 1]>"
		}
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
# Entr�e :
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
	apply-groups	{2	NOP}
	apply-groups-except	{2      NOP}
	interface-range	{2	juniper-parse-if-range}
	*		{1	juniper-parse-if}
    }

    return [juniper-parse-list kwtab [lindex $conf 1] t "$idx"]
}


#
# Entr�e :
#   - idx = eq!<eqname> ou eq!<eqname>!ifrange!<nom>
#   - conf = {ge-0/0/0 { description <desc> unit <nb> { ... }} ... }
#	ou {<range> { description <desc> unit <nb> { ... }} ... } si range
# Remplit :
#   - t(eq!<eqname>!ranges) {<range> ... <range>}
#   - t(eq!<eqname>!if) {<ifname> ... <ifname>}
#
# Historique :
#   2009/12/21 : pda/jean : debut analyse junos switch
#   2010/03/24 : pda      : interfaces d�sactiv�es
#

proc juniper-parse-if {conf tab idx} {
    upvar $tab t

    array set kwtab {
	mtu			{2	NOP}
	description		{2	juniper-parse-if-descr}
	disable			{1	juniper-parse-if-disable}
	native-vlan-id		{2	juniper-parse-if-nativevlan}
	unit			{2	juniper-parse-if-unit}
	gigether-options	{1	juniper-parse-if-gigopt}
	ether-options		{1	juniper-parse-if-gigopt}
	aggregated-ether-options {1	NOP}
	flexible-vlan-tagging   {1	NOP}
	encapsulation		{2	NOP}
	vlan-tagging		{1	juniper-parse-if-vlan-tagging}
	member-range		{4	juniper-parse-member-range}
	member			{2	juniper-parse-member}
	traceoptions		{1	NOP}
	apply-groups		{2	NOP}
	apply-groups-except     {2      NOP}
	*			{2	ERROR}
    }

    # ifname peut �tre un nom d'interface ou d'intervalle (range)
    set ifname [lindex $conf 0]
    set ifparm [lindex $conf 1]

    set t(current!iface) $ifname

    if {[info exists t(in-range)]} then {
	lappend t($idx!ranges) $ifname
	set idxin "$idx!range!$ifname"
    } else {
	# on diff�re l'ajout de l'interface dans la liste
	# des interfaces apr�s l'analyse, pour le cas o�
	# l'interface serait d�sactiv�e.
	set idxin "$idx!if!$ifname"
    }

    set error [juniper-parse-list kwtab $ifparm t $idxin]

    # ajout de l'interface dans la liste des interfaces
    # activ�es ou d�sactiv�es
    if {! [info exists t(in-range)]} then {
	if {! [info exists t($idx!if!$ifname!disable)]} then {
	    lappend t($idx!if) $ifname
	} else {
	    lappend t($idx!if!disabled) $ifname
	}
    }

    unset t(current!iface)

    return $error
}

#
# Entr�e :
#   - idx = eq!<eqname>
# Remplit :
#   - <plein de choses>
#
# Historique :
#   2009/12/21 : pda/jean : conception
#

proc juniper-parse-if-range {conf tab idx} {
    upvar $tab t

    set t(in-range) "n'importe quoi"
    set r [juniper-parse-if [lreplace $conf 0 0] t $idx]
    unset t(in-range)

    return $r
}

#
# Entr�e :
#   - idx = eq!<eqname>!range!<range>
#   - conf = { member-range <if1> to <if2> ... }
# Remplit :
#   - t(eq!<eqname>!range!<range>!members) {{<ifstart> <ifend>} ...}
#
# Historique :
#   2009/12/21 : pda/jean : conception
#

proc juniper-parse-member-range {conf tab idx} {
    upvar $tab t

    set if1 [lindex $conf 1]
    set if2 [lindex $conf 3]
    lappend t($idx!members) [list $if1 $if2]
    return 0
}

#
# Entr�e :
#   - idx = eq!<eqname>!range!<range>
#   - conf = { member <if> ... }
# Remplit :
#   - t(eq!<eqname>!range!<range>!members) {{<if> <if>} ...}
#
# Historique :
#   2009/12/21 : pda/jean : conception
#

proc juniper-parse-member {conf tab idx} {
    upvar $tab t

    set if [lindex $conf 1]
    lappend t($idx!members) [list $if $if]
    return 0
}

#
# Entr�e :
#   - idx = eq!<eqname>!if!<ifname> ou eq!<eqname>!range!<range>
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
# Entr�e :
#   - idx = eq!<eqname>!if!<ifname> ou eq!<eqname>!range!<range>
# Remplit :
#   tab(eq!<eqname>!if!<ifname>!disable) 1
#
# Historique :
#   2010/03/24 : pda      : conception
#

proc juniper-parse-if-disable {conf tab idx} {
    upvar $tab t

    set t($idx!disable) yes
    return 0
}

#
# Entr�e :
#   - idx = eq!<eqname>!if!<ifname> ou eq!<eqname>!range!<range>
# Remplit :
#

proc juniper-parse-if-unit {conf tab idx} {
    upvar $tab t

    array set kwtab {
	description	{2	juniper-parse-unit-descr}
	vlan-id		{2	juniper-parse-vlan-id}
	family		{2	juniper-parse-family}
	disable		{1	juniper-parse-unit-disable}
	encapsulation	{2	juniper-parse-unit-encap}
	tunnel		{1	NOP}
	apply-groups	{2	NOP}
	apply-groups-except	{2      NOP} 
	traceoptions	{1	NOP}
	*		{2	ERROR}
    }

    set unitnb   [lindex $conf 1]
    set unitparm [lindex $conf 2]

    set t(current!unitnb) $unitnb
    set t($idx!vlan!$unitnb!stat) ""
    set error [juniper-parse-list kwtab $unitparm t "$idx"]
    unset t(current!unitnb)

# XXX
# This code has been deactivated since some interface networks
# may be emtpy on JunOS routers (eg interface connected to a
# bridge domain) without being a switch.
#
#    #
#    # Cas particulier : s'il n'y a aucun network, l'interface
#    # est consid�r�e comme participant � un JunOS switch.
#    # Ce cas est n�cessaire pour g�rer la d�sactivation de
#    # port via l'interface Web.
#    #
#
#    if {! [info exists t($idx!vlan!$unitnb!networks)]} then {
#	set t($idx!l2switch) on
#    }

    return $error
}

#
# Entr�e :
#   - idx = eq!<eqname>!if!<ifname> ou eq!<eqname>!range!<range>
# Remplit :
#   tab(eq!<eqname>!if!<ifname>!disable) 1
#
# Historique :
#   2010/03/24 : pda      : conception
#

proc juniper-parse-unit-disable {conf tab idx} {
    upvar $tab t

    set unit $t(current!unitnb)
    set t($idx!vlan!$unit!disable) yes

    return 0
}


#
# Entr�e :
#   - idx = eq!<eqname>!if!<ifname> ou eq!<eqname>!range!<range>
# Remplit :
#   nothing
#
# Historique :
#   2010/03/24 : pda      : conception
#

proc juniper-parse-unit-encap {conf tab idx} {
    upvar $tab t

    # placeholder for future
    return 0
}


#
# Entr�e :
#   - idx = eq!<eqname>!if!<ifname> ou eq!<eqname>!range!<range>
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
	# 1) linkname peut contenir n'importe quoi (compatibilit� avec
	#    l'ancienne syntaxe), donc on l'ignore
	# 2) on fait toujours l'approximation : num�ro d'unit� = no de vlan
	# 3) m�me s'il n'y a pas de d�finition d'un point de collecte
	#    de m�trologie (statname = cha�ne vide), on remplit
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
# Entr�e :
#   - idx = eq!<eqname>!if!<ifname> ou eq!<eqname>!range!<range>
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

    # approximation : num�ro d'unit� = no de vlan
    if {$unitnb != $parm} then {
	juniper-warning "$idx: vlan-id $parm does not match unit $unitnb"
	return 1
    }

    lappend t($idx!vlans) $unitnb
    return 0
}

#
# Entr�e :
#   - idx = eq!<eqname>!if!<ifname> ou eq!<eqname>!range!<range>
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
		targeted-broadcast	{1	NOP}
		filter			{1	NOP}
		sampling		{1	NOP}
		policer			{1	NOP}
		address			{2	juniper-parse-if-address}
		apply-groups		{2	NOP}
		apply-groups-except	{2      NOP}
		traceoptions		{1	NOP}
		*			{2	NOP}
	    }
	    set unitnb $t(current!unitnb)
	    set parm [lindex $conf 2]
	    set error [juniper-parse-list kwtab $parm t "$idx!vlan!$unitnb"]
	}
	mpls -
	iso {
	    set error 0
	}
	ethernet-switching {
	    array set kwtab {
		interface-mode	{2	juniper-parse-l2switch-portmode}
		port-mode	{2	juniper-parse-l2switch-portmode}
		vlan		{1	juniper-parse-l2switch-vlan}
		native-vlan-id	{2	juniper-parse-l2switch-nativevlan}
		traceoptions	{1	NOP}
		*		{2	NOP}
	    }
	    set t($idx!l2switch) on
	    set parm [lindex $conf 2]
	    set error [juniper-parse-list kwtab $parm t $idx]
	}
	bridge {
	    array set kwtab {
		filter		{1	NOP}
		interface-mode	{2	juniper-parse-fbridge-ifmode}
		vlan-id		{2	juniper-parse-fbridge-vlanid}
		vlan-id-list	{2	juniper-parse-fbridge-vlanidlist}
		*		{2	NOP}
	    }
	    set t($idx!link!allowedvlans) {}
	    set parm [lindex $conf 2]
	    set error [juniper-parse-list kwtab $parm t $idx]
	    # append this interface to the list of candidates to a bridge domain
	    set eq $t(eq)
	    lappend t(eq!$eq!brcandidate) $t(current!iface)
	}
	default {
	    juniper-warning "$idx: family '$fam' not supported"
	    set error 1
	}
    }
    return $error
}

#
# Entr�e :
#   - idx = eq!<eqname>!if!<ifname> ou eq!<eqname>!range!<range>
#
# Historique
#   2009/12/22 : pda/jean : conception
#

proc juniper-parse-l2switch-portmode {conf tab idx} {
    upvar $tab t

    set error 0
    set mode [lindex $conf 1]
    switch $mode {
	trunk {
	    set t($idx!link!type) "trunk"
	}
	access {
	    set t($idx!link!type) "ether"
	}
	default {
	    juniper-warning "$idx: port-mode '$mode' not supported"
	    set error 1
	}
    }
    return $error
}

#
# Entr�e :
#   - idx = eq!<eqname>!if!<ifname> ou eq!<eqname>!range!<range>
#
# Historique
#   2009/12/22 : pda/jean : conception
#

proc juniper-parse-l2switch-vlan {conf tab idx} {
    upvar $tab t

    array set kwtab {
	members		{3	juniper-parse-l2switch-vlan-members}
	apply-groups	{2	NOP}
	apply-groups-except	{2      NOP}
	traceoptions	{1	NOP}
	*		{1	ERROR}
    }
    set error [juniper-parse-list kwtab [lindex $conf 1] t "$idx"]
    return $error
}

#
# Entr�e :
#   - idx = eq!<eqname>!if!<ifname> ou eq!<eqname>!range!<range>
#
# Historique
#   2009/12/22 : pda/jean : conception
#

proc juniper-parse-l2switch-vlan-members {conf tab idx} {
    upvar $tab t

    set vlans [lindex $conf 1]
    foreach v $vlans {
	if {[regexp {^(\d+)-(\d+)$} $v bidon min max]} then {
	    set l [list $min $max]
	} else {
	    set l [list $v $v]
	}
	lappend t($idx!link!allowedvlans) $l
    }
    return 0
}

#
# Entrée :
#   - idx = eq!<eqname>!if!<ifname> ou eq!<eqname>!range!<range>
#   - tab(current!unitnb) = <unit number>
# Remplit :
#   tab(eq!<eqname>!if!<ifname>!link!allowedvlans) {<vlan-id|vlan-name> ...}
#   tab(eq!<eqname>!if!<ifname>!native-vlan) <vlan-id|vlan-name>
#
# Historique
#   2009/12/22 : pda/jean : conception
#   2010/08/31 : pda/jean : gestion effective du vlan natif
#

proc juniper-parse-l2switch-nativevlan {conf tab idx} {
    upvar $tab t

    set vlan [lindex $conf 1]
    lappend t($idx!link!allowedvlans) [list $vlan $vlan]
    set t($idx!native-vlan) $vlan
    return 0
}

#
# Entr�e :
#   - idx = eq!<eqname>!if!<ifname> ou eq!<eqname>!range!<range>
# Remplit :
#   tab(eq!<eqname>!if!<ifname>!native-vlan) <vlan-id|vlan-name>
#
# Apparently used only for bridge family
#
# Historique
#   2012/07/03 : pda/jean : conception
#

proc juniper-parse-if-nativevlan {conf tab idx} {
    upvar $tab t

    set vlan [lindex $conf 1]
    set t($idx!native-vlan) $vlan
    return 0
}

#
# Entr�e :
#   - idx = eq!<eqname>!if!<ifname> ou eq!<eqname>!range!<range>
#   - tab(current!unitnb) = <unit number>
# Remplit :
#   tab(eq!<eqname>!if!<ifname>!link!type) trunk|ether
#
# Historique
#   2012/07/03 : pda/jean : conception
#

proc juniper-parse-fbridge-ifmode {conf tab idx} {
    upvar $tab t

    set error 0
    set mode [lindex $conf 1]
    switch $mode {
	trunk {
	    set t($idx!link!type) "trunk"
	}
	access {
	    set t($idx!link!type) "ether"
	}
	default {
	    juniper-warning "$idx: interface-mode '$mode' not supported"
	    set error 1
	}
    }
    return $error
}

#
# Entr�e :
#   - idx = eq!<eqname>!if!<ifname> ou eq!<eqname>!range!<range>
# Remplit :
#   tab(eq!<eqname>!if!<ifname>!link!allowedvlans) {id id}
#
# Historique
#   2012/07/03 : pda/jean : conception
#

proc juniper-parse-fbridge-vlanid {conf tab idx} {
    upvar $tab t

    set vlan [lindex $conf 1]
    lappend t($idx!link!allowedvlans) [list $vlan $vlan]
    return 0
}

#
# Entr�e :
#   - idx = eq!<eqname>!if!<ifname> ou eq!<eqname>!range!<range>
# Remplit :
#   tab(eq!<eqname>!if!<ifname>!bridge!<vlanid>!mode) trunk (for all $vlanid)
#   tab(eq!<eqname>!if!<ifname>!link!allowed-vlans) {{ min max } ...}
#		(except native-vlan)
#
# Historique
#   2012/07/03 : pda/jean : conception
#

proc juniper-parse-fbridge-vlanidlist {conf tab idx} {
    upvar $tab t

    # native vlan (if any) will be checked during post processing
    # t(eq!<eq>!if!<ifname>!nativevlan) <vland-id>

    set vlans [lindex $conf 1]
    foreach v $vlans {
	if {[regexp {^(\d+)-(\d+)$} $v bidon min max]} then {
	    set l [list $min $max]
	} else {
	    set l [list $v $v]
	}
	lappend t($idx!link!allowedvlans) $l
    }
    return 0
}

#
# Entr�e :
#   - idx = eq!<eqname>!if!<ifname>!unit!<unitnb>
# Remplit :
#   tab(eq!<eqname>!if!<ifname>!vlan!<unitnb>!networks) {<cidr46> ...}
#   tab(eq!<eqname>!if!<ifname>!vlan!<unitnb>!net!<cidr46>) <adr46>
#   tab(eq!<eqname>!if!<ifname>!vlan!<unitnb>!net!<cidr46>!preflen) <preflen>
#

proc juniper-parse-if-address {conf tab idx} {
    upvar $tab t

    array set kwtab {
	vrrp-group	    {2	juniper-parse-vrrp}
	vrrp-inet6-group    {2	juniper-parse-vrrp}
	arp		    {4	NOP}
	destination	    {2	NOP}
	apply-groups	    {2	NOP}
	apply-groups-except	{2      NOP}
	traceoptions	    {1	NOP}
	*		    {2	ERROR}
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
# Entr�e :
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
	virtual-inet6-address	{2	juniper-parse-vrrp-vadr}
	accept-data		{1	NOP}
	apply-groups	    	{2	NOP}
	apply-groups-except	{2      NOP}
	traceoptions	    	{1	NOP}
	*			{2	NOP}
    }

    return [juniper-parse-list kwtab [lindex $conf 2] t $idx]
}

#
# Entr�e :
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
# Entr�e :
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
# Entr�e :
#   - idx = eq!<eqname>!if!<ifname>
# Remplit :
#   - rien
#
# Historique :
#   2004/03/23 : pda/jean : conception
#   2010/06/17 : pda      : ajout link-mode
#   2010/09/?? : saillard : ajout no-auto-nego + no-flow-control
#

proc juniper-parse-if-gigopt {conf tab idx} {
    upvar $tab t

    array set kwtab {
	802.3ad			{2	juniper-parse-802-3ad}
	link-mode		{2	NOP}
	speed			{1	NOP}
        auto-negotiation	{1	NOP}
        no-auto-negotiation	{1	NOP}
        no-flow-control		{1	NOP}
	apply-groups	    	{2	NOP}
	apply-groups-except	{2      NOP}
	traceoptions	    	{1	NOP}
	*			{2	ERROR}
    }
    return [juniper-parse-list kwtab [lindex $conf 1] t $idx]
}

#
# Entr�e :
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
# Entr�e :
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
# Entr�e :
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
	apply-groups	    	{2	NOP}
	apply-groups-except     {2      NOP}
	traceoptions	    	{1	NOP}
	*			{1	NOP}
    }

    return [juniper-parse-list kwtab [lindex $conf 1] t $idx]
}

#
# Entr�e :
#   - idx = eq!<eqname>
# Remplit :
#   - rien
#
# Historique :
#   2004/03/25 : pda/jean : conception
#   2010/06/21 : pda      : ignorer rib-group
#

proc juniper-parse-static-routes {conf tab idx} {
    upvar $tab t

    array set kwtab {
	route		{juniper-parse-count-route juniper-parse-route-entry}
	rib-group	{2	NOP}
	apply-groups	{2	NOP}
	apply-groups-except	{2      NOP}
	traceoptions	{1	NOP}
	*		{1	ERROR}
    }

    return [juniper-parse-list kwtab [lindex $conf 1] t $idx]
}

#
# Entr�e :
#   - idx = eq!<eqname>
# Remplit :
#   - tab(eq!<eqname>!static!gw) {<gwadr46> ... }
#   - tab(eq!<eqname>!static!<gwadr46>) {<cidr46> ... }
#
# Historique :
#   2004/03/25 : pda/jean : conception
#   2004/03/26 : pda/jean : inversion des donn�es dans le tableau
#   2004/09/21 : pda/jean : nb d'arguments variable pour les entr�es statiques
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
	    # on ne conserve que la premi�re
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
# Entr�e :
#   - idx = eq!<eqname>
# Remplit :
#   - rien
#
# Historique :
#   2006/06/01 : pda/jean : conception
#   2008/05/06 : pda      : ajout location
#

proc juniper-parse-snmp {conf tab idx} {
    upvar $tab t

    array set kwtab {
	trap-options	        {1	NOP}
	trap-group	        {2	NOP}
	community	        {2	juniper-parse-snmp-community}
	location	        {2	juniper-parse-snmp-location}
	apply-groups	        {2	NOP}
	apply-groups-except	{2      NOP}
	traceoptions	        {1	NOP}
	routing-instance-access	{1	NOP}
	*		        {1	ERROR}
    }

    return [juniper-parse-list kwtab [lindex $conf 1] t $idx]
}

#
# Entr�e :
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

#
# Entr�e :
#   - idx = eq!<eqname>
# Remplit :
#   - tab(eq!<eqname>!location) {<location> <blablah> }
#
# Historique :
#   2008/05/06 : pda      : conception
#

proc juniper-parse-snmp-location {conf tab idx} {
    upvar $tab t

    set error 0
    set ipmac 0
    set portmac 0
    set line [lindex $conf 1]
    if {[parse-location $line location ipmac portmac blablah msg]} then {
	if {! [string equal $location ""]} then {
	    set t($idx!location) [list $location $blablah]
	}
    } else {
	juniper-warning "$idx: $msg ($line)"
	set error 1
    }

    set t($idx!ipmac) $ipmac
    set t($idx!portmac) $portmac

    return $error
}

#
# Entr�e :
#   - idx = eq!<eqname>
# Remplit :
#   - rien
#
# Historique :
#   2010/09/01 : pda/jean : conception
#

proc juniper-parse-ethernet-swopt {conf tab idx} {
    upvar $tab t

    array set kwtab {
	voip		{1	juniper-parse-voip}
	analyzer	{2	NOP}
	apply-groups	{2	NOP}
	apply-groups-except	{2      NOP}
	traceoptions	{1	NOP}
	*		{1	NOP}
    }

    return [juniper-parse-list kwtab [lindex $conf 1] t $idx]
}

#
# Entr�e :
#   - idx = eq!<eqname>
# Remplit :
#   - rien
#
# Historique :
#   2010/09/01 : pda/jean : conception
#

proc juniper-parse-voip {conf tab idx} {
    upvar $tab t

    array set kwtab {
	interface	{2	juniper-parse-voip-iface}
	apply-groups	{2	NOP}
	apply-groups-except	{2      NOP}
	traceoptions	{1	NOP}
	*		{1	NOP}
    }

    return [juniper-parse-list kwtab [lindex $conf 1] t $idx]
}

#
# Entr�e :
#   - idx = eq!<eqname>
# Remplit :
#   - tab(eq!<eqname>!voip!if!list) {ge-0/0/0 ...}
#   - tab(eq!<eqname>!voip!if!all) <existe ou non>
#   - tab(eq!<eqname>!voip!if!access-ports) <existe ou non>
#
# Historique :
#   2010/09/01 : pda/jean : conception
#

proc juniper-parse-voip-iface {conf tab idx} {
    upvar $tab t

    array set kwtab {
	vlan		{2	juniper-parse-voip-iface-vlan}
	apply-groups	{2	NOP}
	apply-groups-except	{2      NOP}
	traceoptions	{1	NOP}
	*		{2	NOP}
    }

    #
    # l'interface peut �tre
    #	- all
    #	- access-ports : tous les ports access d�clar�s sur le switch
    #   - ge-n/n/n.0 : supprimer la "unit"
    #

    set iface [lindex $conf 1]

    switch $iface {
	all		{ set t($idx!voip!if!all) "yes" }
	access-ports	{ set t($idx!voip!if!access-ports) "yes" }
	default		{
	    if {[regexp {(.*)\.(\d)$} $iface bidon iface unit]} then {
		if {$unit != 0} then {
		    juniper-warning "$idx: invalid unit '$iface.$unit'"
		}
	    }
	    lappend t($idx!voip!if!list) $iface
	}
    }

    set idx "$idx!voip!iface!$iface"

    return [juniper-parse-list kwtab [lindex $conf 2] t $idx]
}

#
# Entr�e :
#   - idx = eq!<eqname>!voip!iface!<iface>
# Remplit :
#   - tab(eq!<eqname>!voip!iface!<iface>!vlan) <id|nom|"untagged">
#
# Historique :
#   2010/09/01 : pda/jean : conception
#

proc juniper-parse-voip-iface-vlan {conf tab idx} {
    upvar $tab t

    set vlan [lindex $conf 1]
    set t($idx!vlan) $vlan
    return 0
}

#
# Entr�e :
#   - idx = eq!<eqname>
# Remplit :
#   - rien
#
# Historique :
#   2009/12/21 : pda/jean : conception
#

proc juniper-parse-vlans {conf tab idx} {
    upvar $tab t

    array set kwtab {
	apply-groups	{2	NOP}
	apply-groups-except	{2      NOP}
	traceoptions	{1	NOP}
	*		{1	juniper-parse-vlans-entry}
    }

    return [juniper-parse-list kwtab [lindex $conf 1] t $idx]
}

#
# Entr�e :
#   - idx = eq!<eqname>
# Remplit :
#   - tab(eq!<eqname>!vlans!names) {<nom> <nom> ...}
#
# Historique :
#   2010/01/04 : pda/jean : conception
#

proc juniper-parse-vlans-entry {conf tab idx} {
    upvar $tab t

    array set kwtab {
	description	{2	juniper-parse-vlans-entry-desc}
	vlan-id		{2	juniper-parse-vlans-entry-vlan-id}
	l3-interface	{2	juniper-parse-vlans-entry-l3-interface}
	interface	{1	juniper-parse-vlans-entry-interface}
    }

    set nom [lindex $conf 0]
    set t(current!vlan-name) $nom

    lappend t($idx!vlans!names) $nom

    set r [juniper-parse-list kwtab [lindex $conf 1] t "$idx!vlans!name!$nom"]
    unset t(current!vlan-name)

    return $r
}

#
# Entr�e :
#   - idx = eq!<eqname>
# Remplit :
#   - tab(eq!<eqname>!vlans!names) {<nom> <nom> ...}
#
# Historique :
#   2010/03/24 : pda      : conception
#

proc juniper-parse-vlans-entry-desc {conf tab idx} {
    upvar $tab t

    # NOP pour l'instant

    return 0
}

#
# Entr�e :
#   - idx = eq!<eqname>!vlans!name!<nom>
# Remplit :
#   - tab(eq!<eqname>!vlans!name!<nom>!id) <vlanid>
#
# Historique :
#   2010/01/04 : pda/jean : conception
#

proc juniper-parse-vlans-entry-vlan-id {conf tab idx} {
    upvar $tab t

    set vlanid [lindex $conf 1]
    set t($idx!id) $vlanid
    return 0
}

#
# Entr�e :
#   - idx = eq!<eqname>!vlans!name!<nom>
# Remplit :
#   - tab(eq!<eqname>!if!....!link!allowedvlans) {... {vlanid vlanid} ...}
#
# Historique :
#   2016/03/04 : boggia/jean : conception
#

proc juniper-parse-vlans-entry-interface {conf tab idx} {
    upvar $tab t

    #
    # get equipment name, current vlanid and interface bloc
    #

    set eq [lindex [split $idx !] 1]
    set vlanid $t($idx!id)
    set ifaces [lindex $conf 1]

    #
    # interface bloc is a list { ge-0/0/1.0 {} xe-0/2/1.0 {} ... }
    #

    foreach {iface dummy} $ifaces {
        #
        # remove unit number
        #
        regexp {(.+)\.0$} $iface dummy iface
        set ifidx "eq!$eq!if!$iface!link!allowedvlans"
        lappend t($ifidx) [list $vlanid $vlanid]
    }

    return 0
}


#
# Entr�e :
#   - idx = eq!<eqname>!vlans!name!<nom>
# Remplit :
#   - tab(eq!<eqname>!vlans!name!<nom>!l3) {<iface> <unit>}
#
# Historique :
#   2010/01/04 : pda/jean : conception
#

proc juniper-parse-vlans-entry-l3-interface {conf tab idx} {
    upvar $tab t

    set ifaceunit [lindex $conf 1]
    if {! [regexp {^(vlan|irb)\.([0-9]+)} $ifaceunit bidon iface unit]} then {
	juniper-warning "$idx: invalid l3-interface '$ifaceunit'"
    } else {
	set t($idx!l3) [list $iface $unit]
    }
    return 0
}

#
# Entr�e :
#   - idx = eq!<eqname>
# Remplit :
#   - rien
#
# Historique :
#   2012/07/03 : pda/jean : conception
#

proc juniper-parse-bridge-domains {conf tab idx} {
    upvar $tab t

    array set kwtab {
	*		{1	juniper-parse-bridge-domains-entry}
    }

    return [juniper-parse-list kwtab [lindex $conf 1] t $idx]
}


#
# Entr�e :
#   - idx = eq!<eqname>
# Remplit :
#   - t(eq!<eq>!brdomlist) { <bdname> ...}
#
# Historique :
#   2012/07/03 : pda/jean : conception
#

proc juniper-parse-bridge-domains-entry {conf tab idx} {
    upvar $tab t

    array set kwtab {
	description		{2	NOP}
	domain-type		{2	NOP}
	bridge-options		{1	NOP}
	vlan-id			{2	juniper-parse-bridged-vlanid}
	vlan-id-list		{2	juniper-parse-bridged-vlanidlist}
	interface		{2	juniper-parse-bridged-if}
	routing-interface	{2	juniper-parse-bridged-routif}
	*			{2	ERROR}
    }

    set bdname [lindex $conf 0]
    set bdparm [lindex $conf 1]
    set t(current!brdom) $bdname
    set t($idx!brdom!$bdname!iflist) {}
    set error [juniper-parse-list kwtab $bdparm t "$idx!brdom!$bdname"]
    if {! $error} then {
	lappend t($idx!brdomlist) $bdname
    }
    unset t(current!brdom)

    return $error
}

#
# Entr�e :
#   - idx = eq!<eqname>!brdom!<bdname>
# Remplit :
#   - t(eq!<eqname>!brdom!<bdname>!vlans) {{<vlanid> <vlanid>}}
#
# Historique :
#   2012/07/10 : pda/jean : conception
#

proc juniper-parse-bridged-vlanid {conf tab idx} {
    upvar $tab t

    set vlanid [lindex $conf 1]
    set t($idx!vlans) [list [list $vlanid $vlanid]]
    return 0
}

#
# Entr�e :
#   - idx = eq!<eqname>!brdom!<bdname>
# Remplit :
#   - t(eq!<eqname>!brdom!<bdname>!vlans) {{<vlanid> <vlanid>} ... }
#
# Historique :
#   2012/07/10 : pda/jean : conception
#

proc juniper-parse-bridged-vlanidlist {conf tab idx} {
    upvar $tab t

    set t($idx!vlans) {}
    set vlans [lindex $conf 1]
    foreach v $vlans {
	if {[regexp {^(\d+)-(\d+)$} $v bidon min max]} then {
	    set l [list $min $max]
	} else {
	    set l [list $v $v]
	}
	lappend t($idx!vlans) $l
    }
    return 0
}

#
# Entr�e :
#   - idx = eq!<eqname>!brdom!<bdname>
# Remplit :
#   - t(eq!<eqname>!brdom!<bdname>!vlans) {{<vlanid> <vlanid>} ... }
#
# Historique :
#   2012/07/10 : pda/jean : conception
#

proc juniper-parse-bridged-if {conf tab idx} {
    upvar $tab t

    set eq $t(eq)
    set brdom $t(current!brdom)

    set ifname_unit [lindex $conf 1]
    if {[regexp {^(.*)\.(\d+)$} $ifname_unit bidon iface unit]} then {
	set error 0
	if {[info exists t(eq!$eq!if!$iface!vlans)]
	    && [lsearch -exact $t(eq!$eq!if!$iface!vlans) $unit] != -1} then {
	    #
	    # Mark this interface as participating to this bridge-domain
	    #
	    lappend t($idx!iflist) [list $iface $unit]
	    lappend t(eq!$eq!if!$iface!brdom) $brdom

	} else {
	    juniper-warning "$eq: interface '$ifname_unit' not found in bridge domain"
	    set error 1
	}
    } else {
	juniper-warning "$eq: invalid interface '$ifname_unit' in bridge domain"
	set error 1
    }

    return $error
}

#
# Entr�e :
#   - idx = eq!<eqname>!brdom!<bdname>
# Remplit :
#	???????????????????????????????????????
#   - t(eq!<eqname>!brdom!<bdname>!vlans) {{<vlanid> <vlanid>} ... }
#
# Historique :
#   2012/07/10 : pda/jean : conception
#

proc juniper-parse-bridged-routif {conf tab idx} {
    upvar $tab t

    return 0
}

#
# Entr�e :
#   - idx = eq!<eqname>
# Remplit :
#   - rien
#
# Historique :
#   2015/09/28 : jean : conception
#

proc juniper-parse-protocols {conf tab idx} {
    upvar $tab t

    array set kwtab {
	mvrp		{1	juniper-parse-protocols-mvrp}
	*		{1	NOP}
    }

    return [juniper-parse-list kwtab [lindex $conf 1] t $idx]
}

#
# Entr�e :
#   - idx = eq!<eqname>
# Remplit :
#   - rien
#
# Historique :
#   2015/09/28 : jean : conception
#

proc juniper-parse-protocols-mvrp {conf tab idx} {
    upvar $tab t

    array set kwtab {
        interface                    {2      juniper-parse-mvrp-iface}
        apply-groups                 {2      NOP}
        apply-groups-except          {2      NOP}
        traceoptions                 {1      NOP}
        *                            {1      NOP}
    }

    return [juniper-parse-list kwtab [lindex $conf 1] t $idx]
}


#
# Entr�e :
#   - idx = eq!<eqname>
# Remplit :
#   - tab(eq!<eqname>!if!<ifname>!link!allowvlans) ... {1 4094}
#
# Historique :
#   2015/09/28 : jean : adapted from parse-voip-iface
#

proc juniper-parse-mvrp-iface {conf tab idx} {
    upvar $tab t

    #
    # interface :
    #   - ge-n/n/n.0 : remove unit number
    #   - all : unsupported yet
    #

    set iface [lindex $conf 1]

    set error 0
    switch $iface {
	all		{ 
	    juniper-warning "$eq: mvrp interface all not supported"
            set error 1
	}
	default		{
	    if {[regexp {(.*)\.(\d)$} $iface bidon iface unit]} then {
		if {$unit != 0} then {
		    juniper-warning "$idx: invalid unit '$iface.$unit'"
		}
	    }
    	    set idx "$idx!if!$iface"
	    lappend t($idx!link!allowedvlans) [list 1 4094]
	}
    }

    return $error
}

###############################################################################
# Traitement apr�s analyse
###############################################################################

#
# Traite le tableau r�sultant de l'analyse pour permettre d'acc�der
# plus facilement aux r�seaux (de niveau 3) et aux liens (de niveau 2)
# g�r�s par cet �quipement
#
# Entr�e :
#   - model : mod�le de l'�quipement
#   - fdout : descripteur de fichier pour la g�n�ration
#   - eq : nom de l'�quipement
#   - tab : tableau rempli au cours de l'analyse
# Sortie :
#   - valeur de retour : 0 si pas d'erreur, 1 si erreur
#   - tab : tableau modifi�
#
# Historique
#   2004/03/26 : pda/jean : conception
#   2004/06/08 : pda/jean : ajout du mod�le
#   2004/06/08 : pda/jean : changement de format du fichier de sortie
#   2006/06/01 : pda/jean : ajout snmp
#   2006/08/21 : pda/pegon : liens X+X+X+...+X deviennent X
#   2007/01/06 : pda       : ajout desc interface
#   2007/07/13 : pda       : ajout sortie tableau si debug
#   2010/03/25 : pda       : ajout "members all"
#   2010/09/01 : pda/jean  : ajout voip
#

proc juniper-post-process {model fdout eq tab} {
    global debug
    upvar $tab t

    if {$debug & 0x02} then {
	debug-array t
    }

    if {[info exists t(eq!$eq!snmp)]} then {
	# XXX : on ne prend que la premi�re communaut� trouv�e
	set c [lindex $t(eq!$eq!snmp) 0]
    } else {
	set c "-"
    }
    if {[info exists t(eq!$eq!location)]} then {
	# XXX : on ne prend que la partie reconnue <...>
	set l [lindex $t(eq!$eq!location) 0]
    } else {
	set l "-"
    }
    if {[info exists t(eq!$eq!ipmac)]} then {
	set ipmac $t(eq!$eq!ipmac)
    } else {
	set ipmac 0
    }
    if {[info exists t(eq!$eq!portmac)]} then {
	set portmac $t(eq!$eq!portmac)
    } else {
	set portmac 0
    }
    puts $fdout "eq $eq type juniper model $model snmp $c location $l ipmac $ipmac portmac $portmac manual 0"

    #
    # Parcourir la liste des interfaces, dont on compl�tera les
    # caract�ristiques selon les d�finitions des intervalles d�finis.
    # (JunOS switch)
    #

    foreach if $t(eq!$eq!if) {
	set ranges [juniper-find-ranges t $eq $if]
	foreach r $ranges {
	    juniper-completer-iface t $eq $if $r
	}

	#
	# Les interfaces non typ�es sont "ether" par d�faut
	#

	set idx "eq!$eq!if!$if"
	if {! [info exists t($idx!link!type)]} then {
	    set t($idx!link!type) "ether"
	}

	#
	# V�rifier que chaque interface a une description
	# 

	if {! [info exists t($idx!link!name)]} then {
	    juniper-warning "$eq/$if: link name in 'description' not found"
	    set error 1
	}
    }

    #
    # Convertir les noms de vlans en id num�riques, phase 0
    # D�terminer les intervalles dans la liste des vlan-id trouv�s
    # sur cet �quipement
    #

    if {[info exists t(eq!$eq!vlans!names)]} then {
	# d�terminer les vlan-id
	set lid {}
	foreach id [array names t -glob "*!vlans!name!*!id"] {
	    lappend lid $t($id)
	}
	set lid [lsort -integer $lid]

	# d�terminer les intervalles
	set ranges {}
	set min [lindex $lid 0]
	set max [lindex $lid 0]
	foreach id [lreplace $lid 0 0] {
	    if {$max != $id - 1} then {
		lappend ranges [list $min $max]
		set min $id
	    }
	    set max $id
	}
	lappend ranges [list $min $max]
	set t(eq!$eq!vlans!ranges) $ranges
    }

    #
    # Convertir les noms de vlans en id num�riques, phase 1
    # Remplacer "all" (members all) par la liste des vlans
    # connus dans la section "vlans"
    # (JunOS switch)
    #

    if {[info exists t(eq!$eq!vlans!names)] && [info exists t(eq!$eq!vlans!ranges)]} then {
	# Parcourir toutes les "!allowedvlans" positionn�s
	# � "all all"
	foreach i [array names t -glob "*!link!allowedvlans"] {
	    set l {}
	    foreach c $t($i) {
		set v1 [lindex $c 0]
		set v2 [lindex $c 1]
		if {[string equal $v1 "all"] && [string equal $v2 "all"]} then {
		    set l [concat $l $t(eq!$eq!vlans!ranges)]
		} else {
		    lappend l [list $v1 $v2]
		}
	    }
	    set t($i) $l
	}
    }

    #
    # Convertir les noms de vlans en id num�riques, phase 2
    # Mettre les interfaces vlan.<unit> dans le bon vlan-id
    # (JunOS switch)
    #

    if {[info exists t(eq!$eq!vlans!names)]} then {
	foreach name $t(eq!$eq!vlans!names) {
	    #
	    # Conversion des noms de vlans : parcourir toutes les
	    # "!allowedvlans" pour convertir les noms
	    #
	    foreach i [array names t -glob "*!link!allowedvlans"] {
		set l {}
		foreach c $t($i) {
		    set v1 [lindex $c 0]
		    if {[info exists t(eq!$eq!vlans!name!$v1!id)]} then {
			set v1 $t(eq!$eq!vlans!name!$v1!id)
		    }
		    set v2 [lindex $c 1]
		    if {[info exists t(eq!$eq!vlans!name!$v2!id)]} then {
			set v2 $t(eq!$eq!vlans!name!$v2!id)
		    }
		    lappend l [list $v1 $v2]
		}
		set t($i) $l
	    }

	    #
	    # Inscription des interfaces vlan.<unit> et irb.<unit> dans le bon
	    # vlan-id
	    #
	    foreach iftype {vlan irb} {
		array unset nt
		if {[info exists t(eq!$eq!vlans!name!$name!l3)]} then {
		    set ifaceunit $t(eq!$eq!vlans!name!$name!l3)
		    set iface [lindex $ifaceunit 0]
		    set unit  [lindex $ifaceunit 1]
		    if [string eq $iface $iftype] {
			set vlanid $t(eq!$eq!vlans!name!$name!id)
			lappend nt(eq!$eq!if!$iftype!vlans) $vlanid
			foreach i [array names t -glob "eq!$eq!if!$iface!vlan!$unit!*"] {
			    regexp "!$iface!vlan!$unit!(.*)" $i bidon reste
			    set nt(eq!$eq!if!$iface!vlan!$vlanid!$reste) $t($i)
			    unset t($i)
			}
			foreach i [array names nt] {
			    if {![info exists t($i)]} then {
			    	set t($i) {}
			    }
			    foreach e $nt($i) {
			    	lappend t($i) $e
			    }
			}
		    }
		}
	    }
	}
    }

    #
    # Convertir les noms de vlans en id num�riques, phase 3
    # Convertir les native-vlan
    # (JunOS switch)
    #

    if {[info exists t(eq!$eq!vlans!names)]} then {
	foreach name $t(eq!$eq!vlans!names) {
	    #
	    # Conversion des noms de vlans : parcourir toutes les
	    # "!allowedvlans" pour convertir les noms
	    #
	    set vlanid $t(eq!$eq!vlans!name!$name!id)
	    foreach i [array names t -glob "*!native-vlan"] {
		if {[string equal $name $t($i)]} then {
		    set t($i) $vlanid
		}
	    }
	}
    }

    #
    # Convertir les noms de vlans en id num�riques, phase 4
    # Convertir les vlans sp�cifi�s dans les blocs "voip"
    # (JunOS switch)
    #

    foreach iface [concat $t(eq!$eq!voip!if!list) {access-ports all}]] {
	if {[info exists t(eq!$eq!voip!iface!$iface!vlan)]} then {
	    set vlan $t(eq!$eq!voip!iface!$iface!vlan)
	    if {[info exists t(eq!$eq!vlans!name!$vlan!id)]} then {
		set vlanid $t(eq!$eq!vlans!name!$vlan!id)
		set t(eq!$eq!voip!iface!$iface!vlan) $vlanid
	    }
	}
    }

    #
    # Traiter les sp�cifications "voip" sur les interfaces, phase 1
    # G�n�raliser les directives "access-ports" et "all" aux
    # interfaces concern�es.
    #

    # pr�-traitement des access-ports
    if {[info exists t(eq!$eq!voip!if!access-ports)]} then {
	set vlanid $t(eq!$eq!voip!iface!access-ports!vlan)
	foreach iface $t(eq!$eq!if) {
	    if {! [string equal $iface "vlan"]} then {
		set linktype $t(eq!$eq!if!$iface!link!type)
		if {[string equal $linktype "ether"]} then {
		    if {! [info exists t(eq!$eq!voip!iface!$iface!vlan)]} then {
			set t(eq!$eq!voip!iface!$iface!vlan) $vlanid
			lappend t(eq!$eq!voip!if!list) $iface
		    }

		}
	    }
	}
    }

    # pr�-traitement des all
    if {[info exists t(eq!$eq!voip!if!all)]} then {
	set vlanid $t(eq!$eq!voip!iface!all!vlan)
	foreach iface $t(eq!$eq!if) {
	    if {! [string equal $iface "vlan"]} then {
		set linktype $t(eq!$eq!if!$iface!link!type)
		if {! [info exists t(eq!$eq!voip!iface!$iface!vlan)]} then {
		    set t(eq!$eq!voip!iface!$iface!vlan) $vlanid
		    lappend t(eq!$eq!voip!if!list) $iface
		}
	    }
	}
    }

    # Propagate native-vlan information into allowed vlans
    foreach iface $t(eq!$eq!if) {
	if {[info exists t(eq!$eq!if!$iface!native-vlan)] &&
		[info exists t(eq!$eq!if!$iface!link!allowedvlans)]} then {
	    set nvlan $t(eq!$eq!if!$iface!native-vlan)
	    set allow {}
	    foreach cv $t(eq!$eq!if!$iface!link!allowedvlans) {
		lassign $cv min max
		if {$nvlan == $min} then {
		    incr min
		    if {$min < $max} then {
			lappend allow [list $min $max]
		    }
		} elseif {$nvlan == $max} then {
		    incr max -1
		    if {$min < $max} then {
			lappend allow [list $min $max]
		    }
		} elseif {$nvlan > $min && $nvlan < $max} then {
		    set nmax [expr $nvlan-1]
		    if {$min < $nmax} then {
			lappend allow [list $min $nmax]
		    }
		    set nmin [expr $nvlan+1]
		    if {$nmin < $max} then {
			lappend allow [list $nmin $max]
		    }
		} else {
		    lappend allow [list $min $max]
		}
	    }
	    set t(eq!$eq!if!$iface!link!allowedvlans) $allow
	}
    }

    # Traiter les sp�cifications "voip" sur les interfaces, phase 2
    #
    # Ce qui est � faire d�pend du statut actuel de l'interface
    #	type	directive	action
    #	actuel	voip->vlan
    #	-------	------------	----------------------------------
    #	ether	<id>		passer en trunk pour <id> + native pour
    #				le vlan d�clar� en ether
    #	ether	untagged	aucun changement
    #	trunk	<id>		aucun changement de type + v�rifier que
    #				<id> figure dans les "allowedvlans"
    #	trunk	untagged	erreur
    #

    foreach iface $t(eq!$eq!voip!if!list) {
	set disabled [info exists t(eq!$eq!if!$iface!disable)]
	if {! $disabled} then {
	    set id $t(eq!$eq!voip!iface!$iface!vlan)
	    set new "id"
	    if {[string equal $id "untagged"]} then {
		set new "untagged"
	    }

	    set linktype $t(eq!$eq!if!$iface!link!type)

	    switch "$linktype-$new" {
		ether-id {
		    set t(eq!$eq!if!$iface!link!type) trunk

		    if {[info exist t(eq!$eq!if!$iface!link!allowedvlans)]} then {
			set a [lindex $t(eq!$eq!if!$iface!link!allowedvlans) 0]
			set oldvlan [lindex $a 0]
			set t(eq!$eq!if!$iface!native-vlan) $oldvlan
		    }
		    lappend t(eq!$eq!if!$iface!link!allowedvlans) [list $id $id]
		}
		ether-untagged {
		    # aucun changement
		}
		trunk-id {
		    set found 0
		    foreach c $t(eq!$eq!if!$iface!link!allowedvlans) {
			set v1 [lindex $c 0]
			set v2 [lindex $c 1]
			if {$id >= $v1 && $id <= $v2} then {
			    set found 1
			    break
			}
		    }
		    if {! $found} then {
			lappend t(eq!$eq!if!$iface!link!allowedvlans) [list $id $id]
		    }
		}
		trunk-untagged {
		    juniper-warning "Inconsistent voip specification on '$eq/$iface'"
		}
		default {
		    juniper-warning "Internal error for voip on '$eq/$iface'"
		}
	    }
	}
    }

    #
    # Chercher tous les liens. Pour cela, parcourir la liste
    # des interfaces
    #
    catch {unset agtab}

    # premi�re boucle pour constituer les noms des liens agr�g�s
    foreach iface $t(eq!$eq!if) {
	set linkname $t(eq!$eq!if!$iface!link!name)
	set linktype $t(eq!$eq!if!$iface!link!type)
	if {[string equal $linktype "aggregate"]} then {
	    set parentif $t(eq!$eq!if!$iface!link!ifname)
	    lappend agtab($parentif) $linkname
	}
    }

    #
    # On JunOS router, interface may candidate to some declared
    # bridge domains or may be explicitely named by a bridge domain
    # declaration.
    # Explore all bridge domains to generate bridge (or bridge pattern)
    # nodes, and mark selected interfaces.
    #

    foreach brdom $t(eq!$eq!brdomlist) {
	#
	# If this is a bridge domain with only one specified
	# vlan, instantiate a bridge node specific for this vlan
	# and not a bridge pattern (brpat) to instanciate.
	#

	set brnode 0
	set vlans $t(eq!$eq!brdom!$brdom!vlans)
	if {[llength $vlans] <= 1} then {
	    lassign [lindex $vlans 0] min max
	    if {$min eq $max} then {
		set brnode [newnode]
		puts $fdout "node $brnode type bridge eq $eq"
		set t(eq!$eq!brdom!$brdom!brnode) $brnode

		#
		# Mark (with the bridge node) all interfaces explicitely
		# named in this bridge domain
		#

		foreach iface_unit $t(eq!$eq!brdom!$brdom!iflist) {
		    lassign $iface_unit iface unit
		    lappend t(eq!$eq!if!$iface!bridges) [list $brnode $unit $unit]
		}
	    }
	}

	#
	# Gathers all interfaces which candidate to this bridge
	#

	foreach cv $vlans {
	    # vlans allowed on the bridge
	    lassign $cv brmin brmax

	    foreach iface $t(eq!$eq!brcandidate) {
		set allow {}
		foreach ca $t(eq!$eq!if!$iface!link!allowedvlans) {
		    lassign $ca amin amax

		    #
		    # Check intersection of intervals by computing
		    # the resulting interval.
		    #
		    # nmin = max (amin, brmin)
		    # nmax = min (amax, brmax)
		    #
		    set nmin [expr $amin < $brmin ? $brmin : $amin]
		    set nmax [expr $amax > $brmax ? $brmax : $amax]
		    if {$nmin <= $nmax} then {
			lappend t(eq!$eq!if!$iface!bridges) [list $brnode $nmin $nmax]
		    }
		}
	    }
	}
    }

    # XXX : pour l'instant, il n'y a qu'une seule instance de routage
    # dans *nos* Juniper...
    # En fait, il y en a deux : la "default" pour v4 et la "default" pour v6

    set nodeR4 ""
    set nodeR6 ""

    #
    # Boucle principale : retrouver les liens de niveau 2
    # (sans le d�tail des constituants d'un lien agr�g�)
    # Parcourir la liste des interfaces.
    #

    # par d�faut, pas de brpat
    set nodebrpat 0

    if {$debug & 0x02} then {
	debug-array t
    }

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

	if {[string equal $iface "vlan"] || [string equal $iface "irb"]} then {
	    #
	    # Traitement sp�cial pour les interface "vlan" et "irb" qu'on
	    # trouve sur les JunOS switch
	    # Cas r�duit d'une interface physique sur JunOS routeur
	    #

	    if {[info exists t(eq!$eq!if!$iface!vlans)]} then {
		foreach v $t(eq!$eq!if!$iface!vlans) {
		    set nodeL2 [newnode]
		    set t(eq!$eq!if!$iface!vlan!$v!node) $nodeL2
		    if {![info exists t(eq!$eq!if!$iface!vlan!$v!stat)]} {
			juniper-warning "Warning: '$iface.$v' l3-interface not defined"
			continue
		    }
		    set statname $t(eq!$eq!if!$iface!vlan!$v!stat)
		    if {[string equal $statname ""]} then {
			set statname "-"
		    }
		    puts $fdout "node $nodeL2 type L2 eq $eq vlan $v stat $statname native 0 ifname -"
		    puts $fdout "link $nodeL2 $nodebrpat"

		    #
		    # Parcourir la liste des r�seaux support�s par cette
		    # sous-interface.
		    #
		    foreach cidr $t(eq!$eq!if!$iface!vlan!$v!networks) {
			set ifname "$iface.$v"
			set idx "eq!$eq!if!$iface!vlan!$v!net!$cidr"

			# r�cup�rer l'adresse du routeur dans ce r�seau
			# (i.e. l'adresse IP de l'interface)
			set gwadr $t($idx)
			set preflen $t($idx!preflen)
			set nodeL3 [newnode]

			puts $fdout "node $nodeL3 type L3 eq $eq addr $gwadr/$preflen"
			puts $fdout "link $nodeL3 $nodeL2"
		    }
		}
	    }

	} elseif {! [string equal $linktype "aggregate"]} then {
	    #
	    # Cas standard pour toutes les interfaces physiques
	    # (non constituant un lien aggr�g�)
	    #

	    set nodeL1 [newnode]
	    puts $fdout "node $nodeL1 type L1 eq $eq name $iface link $linkname encap $linktype stat $statname desc $desc"

	    if {[info exists t(eq!$eq!if!$iface!l2switch)]} then {
		#
		# Interface de JunOS switch : "family ethernet-switching"
		#

		set nodeL2 [newnode]

		switch -- $t(eq!$eq!if!$iface!link!type) {
		    ether {
			if {[info exists t(eq!$eq!if!$iface!link!allowedvlans)]} then {
			    set a [lindex $t(eq!$eq!if!$iface!link!allowedvlans) 0]
			    set v [lindex $a 0]
			    puts $fdout "node $nodeL2 type L2 eq $eq vlan $v stat - native 1 ifname -"
			} else {
			    set nodeL2 ""
			}
		    }
		    trunk {
			puts -nonewline $fdout "node $nodeL2 type L2pat eq $eq"
			foreach allowedvlans $t(eq!$eq!if!$iface!link!allowedvlans) {
			    set v1 [lindex $allowedvlans 0]
			    set v2 [lindex $allowedvlans 1]
			    puts -nonewline $fdout " allow $v1 $v2"
			}
			if {[info exists t(eq!$eq!if!$iface!native-vlan)]} then {
			    set nv $t(eq!$eq!if!$iface!native-vlan)
			    puts -nonewline $fdout " native $nv"
			}
			puts $fdout ""
		    }
		    default {
			juniper-warning "Unknown link type for '$eq/$iface'"
		    }
		}

		if {! [string equal $nodeL2 ""]} then {
		    puts $fdout "link $nodeL1 $nodeL2"
		    if {$nodebrpat == 0} then {
			set nodebrpat [newnode]
			puts $fdout "node $nodebrpat type brpat eq $eq"
		    }
		    puts $fdout "link $nodeL2 $nodebrpat"
		}

	    } else {
		#
		# Interface de JunOS routeur : "family inet[6]"
		#

		switch $linktype {
		    ether {
			# VLAN = 0 pour un lien Ether
			set arg 0
		    }
		    trunk {
			set arg {}
			if {[info exists t(eq!$eq!if!$iface!vlans)]} then {
			    # Liste des vlans pour ce lien
			    set arg $t(eq!$eq!if!$iface!vlans)
			}
		    }
		    default {
			juniper-warning "Unknown link type for '$eq/$iface"
		    }
		}

		foreach v $arg {
		    if {! [info exists t(eq!$eq!if!$iface!vlan!$v!disable)]} then {
			if {[info exists t(eq!$eq!if!$iface!vlan!$v!networks)]} then {
			    #
			    # Interconnexion des VLAN aux interfaces physiques
			    #
			    set nodeL2 [newnode]
			    set t(eq!$eq!if!$iface!vlan!$v!node) $nodeL2
			    set statname $t(eq!$eq!if!$iface!vlan!$v!stat)
			    if {[string equal $statname ""]} then {
				set statname "-"
			    }
			    if {$v == 0} then {
				set native 1
			    } else {
				set native 0
			    }
			    puts $fdout "node $nodeL2 type L2 eq $eq vlan $v stat $statname native $native ifname -"
			    puts $fdout "link $nodeL1 $nodeL2"

			    #
			    # Parcourir la liste des r�seaux support�s par cette
			    # sous-interface.
			    #
			    foreach cidr $t(eq!$eq!if!$iface!vlan!$v!networks) {
				set ifname "$iface.$v"
				set idx "eq!$eq!if!$iface!vlan!$v!net!$cidr"

				# r�cup�rer l'adresse du routeur dans ce r�seau
				# (i.e. l'adresse IP de l'interface)
				set gwadr $t($idx)
				set preflen $t($idx!preflen)
				set nodeL3 [newnode]

				puts $fdout "node $nodeL3 type L3 eq $eq addr $gwadr/$preflen"
				puts $fdout "link $nodeL3 $nodeL2"

				if {[string first ":" $gwadr] != -1} then {
				    if {[string equal $nodeR6 ""]} then {
					set nodeR6 [newnode]
					puts $fdout "node $nodeR6 type router eq $eq instance _v6"
				    }
				    set nodeR $nodeR6
				} else {
				    if {[string equal $nodeR4 ""]} then {
					set nodeR4 [newnode]
					puts $fdout "node $nodeR4 type router eq $eq instance _v4"
				    }
				    set nodeR $nodeR4
				}

				puts $fdout "link $nodeL3 $nodeR"

				set static {}

				# parcourir les passerelles cit�es dans les routes statiques,
				# pour d�terminer celles qui sont dans *ce* r�seau
				if {[info exists t(eq!$eq!static!gw)]} then {
				    foreach gw $t(eq!$eq!static!gw) {
					set r [juniper-match-network $gw $cidr]
					if {$r == -1} then {
					    return 1
					} elseif {$r} then {
					    foreach n $t(eq!$eq!static!$gw) {
						append static "$n $gw "
					    }
					}
				    }
				}

				# est-ce qu'il y a du VRRP sur cette interface pour ce r�seau ?
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

		#
		# Output interfaces (on JunOS router) marked as
		# participating to a bridge domain
		# 

		if {[info exists t(eq!$eq!if!$iface!bridges)]} then {
		    #
		    # This interface has at least one unit which
		    # participates to a bridge-domain
		    #
		    foreach b $t(eq!$eq!if!$iface!bridges) {
			lassign $b brnode min max

			if {$brnode == 0} then {
			    if {$nodebrpat == 0} then {
				set nodebrpat [newnode]
				puts $fdout "node $nodebrpat type brpat eq $eq"
			    }
			    set brnode $nodebrpat
			}

			# Is there a sensor?
			set statname ""
			if {$min == $max} then {
			    # if this unit has a specific description
			    # it may have a declared sensor
			    if {[info exists t(eq!$eq!if!$iface!vlan!$min!stat)]} then {
				set statname $t(eq!$eq!if!$iface!vlan!$min!stat)
			    }
			}
			if {$statname eq ""} then {
			    set statname "-"
			}

			# native vlan ?
			set native 0
			if {$t(eq!$eq!if!$iface!link!type) eq "ether"} then {
			    set native 1
			}
			if {[info exists t(eq!$eq!if!$iface!native-vlan)]} then {
			    set nv $t(eq!$eq!if!$iface!native-vlan)
			    if {$min == $max && $min == $nv} then {
				set native 1
			    }
			}

			set nodeL2 [newnode]
			if {$min == $max} then {
			    set ntype "L2"
			    set allow "vlan $min"
			} else {
			    set ntype "L2pat"
			    set allow "allow $min $max"
			}
			puts $fdout "node $nodeL2 type $ntype eq $eq $allow stat $statname native $native ifname -"
			puts $fdout "link $nodeL1 $nodeL2"
			puts $fdout "link $nodeL2 $brnode"
		    }
		}
	    }
	}
    }

    #
    # Parcourir la liste des interfaces marqu�es "disable"
    #

    foreach iface $t(eq!$eq!if!disabled) {
	if {! [string equal $iface "vlan"]} then {
	    set nodeL1 [newnode]
	    puts $fdout "node $nodeL1 type L1 eq $eq name $iface link X encap disabled stat - desc -"
	}
    }

    return 0
}

proc juniper-find-ranges {tab eq if} {
    upvar $tab t

    set lr {}
    if {[regexp {^[A-Za-z]+-.*} $if]} then {
	foreach r $t(eq!$eq!ranges) {
	    set lc $t(eq!$eq!range!$r!members)
	    foreach c $lc {
		set min [lindex $c 0]
		set max [lindex $c 1]
		if {[juniper-iface-cmp $if $min]>=0 && [juniper-iface-cmp $if $max]<=0} then {
		    lappend lr $r
		    break
		}
	    }
	}
    }
    return $lr
}

proc juniper-iface-cmp {i1 i2} {
    if {! [regexp {^([A-Za-z]+)-(.*)} $i1 bidon n1 r1]} then {
	puts stderr "Invalid interface name '$i1' (range $i1 $i2)"
	return -1
    }
    if {! [regexp {^([A-Za-z]+)-(.*)} $i2 bidon n2 r2]} then {
	puts stderr "Invalid interface name '$i2'"
	return -1
    }

    set l1 [split $r1 "/"]
    set l2 [split $r2 "/"]

    set r [string compare $n1 $n2]
    if {$r == 0} then {
	foreach e1 $l1 e2 $l2 {
	    if {$e1 < $e2} then {
		set r -1
		break
	    } elseif {$e1 > $e2} then {
		set r 1
		break
	    }
	}
    }

    return $r
}

proc juniper-completer-iface {tab eq if range} {
    upvar $tab t

    foreach e {link!name link!desc link!stat link!type link!ifname} {
	if {[info exists t(eq!$eq!if!$if!$e)] && ! [string equal $t(eq!$eq!if!$if!$e) ""]} then {
	    # rien � faire
	} else {
	    if {[info exists t(eq!$eq!range!$range!$e)]} then {
		set t(eq!$eq!if!$if!$e) $t(eq!$eq!range!$range!$e)
	    }
	}
    }
}

###############################################################################
# Initialisation du module
###############################################################################

juniper-init
