#
# $Id: parse-cisco.tcl,v 1.5 2007-07-17 12:55:39 pda Exp $
#
# Package d'analyse de fichiers de configuration IOS Cisco
#
# Historique
#   2004/03/26 : pda/jean : début de la conception
#   2004/06/08 : pda/jean : changement de format du fichier de sortie
#   2006/05/26 : pda/jean : ajout des points de collecte de métrologie
#   2006/06/01 : pda/jean : ajout snmp
#   2006/09/25 : lauce    : ajout encapsulation-dot1Q pour VPN
#   2006/09/25 : lauce    : modification cisco-parse-shutdown 
#   2007/01/06 : pda      : ajout desc interface
#   2007/06/15 : pda/jean : ajout desc vlan local
#   2007/07/12 : pda      : debut codage ios router
#   2007/07/13 : pda      : retrait cisco_debug et ajout flag debug en global
#

###############################################################################
# Fonctions utilitaires
###############################################################################

proc cisco-init {} {
    global cisco_masques
    global cisco_rfc1878

    # masques(24) {0xff 0xff 0xff 0x00 0x00 ... 0x00 }
    # masques(25) {0xff 0xff 0xff 0x80 0x00 ... 0x00 }
    # masques(64) {0xff 0xff 0xff 0xff 0xff 0xff 0xff 0xff 0x00 ... 0x00 }

    for {set i 1} {$i <= 128} {incr i} {
	set cisco_masques($i) {}
	set v 0
	for {set j 0} {$j < 128} {incr j} {
	    if {$j < $i} then {
		set v [expr (($v << 1) | 1)]
	    } else {
		set v [expr (($v << 1) | 0)]
	    }
	    if {$j % 8 == 7} then {
		set cisco_masques($i) [concat $cisco_masques($i) $v]
		set v 0
	    }
	}
    }

    array set cisco_rfc1878 {
	128.0.0.0	1
	192.0.0.0	2
	224.0.0.0	3
	240.0.0.0	4
	248.0.0.0	5
	252.0.0.0	6
	254.0.0.0	7
	255.0.0.0	8
	255.128.0.0	9
	255.192.0.0	10
	255.224.0.0	11
	255.240.0.0	12
	255.248.0.0	13
	255.252.0.0	14
	255.254.0.0	15
	255.255.0.0	16
	255.255.128.0	17
	255.255.192.0	18
	255.255.224.0	19
	255.255.240.0	20
	255.255.248.0	21
	255.255.252.0	22
	255.255.254.0	23
	255.255.255.0	24
	255.255.255.128	25
	255.255.255.192	26
	255.255.255.224	27
	255.255.255.240	28
	255.255.255.248	29
	255.255.255.252	30
	255.255.255.254	31
	255.255.255.255	32
    }

}

proc cisco-warning {msg} {
    puts stderr "$msg"
}

proc cisco-debug {msg} {
    cisco-warning $msg
}


proc cisco-read-conf {fd} {
    set conf ""
    while {[gets $fd line] > -1} {
	if {! [regexp {/\*.*\*/} $line]} then {
	    regsub -all {;$} $line { { } } line
	    append conf "\n $line"
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

proc cisco-convert-ifadr-to-cidr {ifadr} {
    global cisco_masques

    if {! [regexp {^(.*)/(.*)$} $ifadr bidon adr preflen]} then {
	cisco-warning "Invalid interface address ($ifadr)"
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
	set m $cisco_masques($preflen)
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
	set m $cisco_masques($preflen)
	set na {}
	for {set i 0} {$i < 4} {incr i} {
	    lappend na [expr [lindex $a $i] & [lindex $m $i]]
	}
	set na [join $na "."]
    }

    return "$na/$preflen"
}

#
# Convertit un subnet-mask (ex: 255.255.0.0) en longueur de préfixe (ex: 16)
#
# Entrée :
#   - mask : masque au format IPv4
# Sortie :
#   - valeur de retour : longueur de préfixe
#
# Historique
#   2004/07/16 : pda/jean : conception
#

proc cisco-convert-mask-to-preflen {mask} {
    global cisco_rfc1878

    if {[info exists cisco_rfc1878($mask)]} then {
	set preflen $cisco_rfc1878($mask)
    } else {
	cisco-warning "Invalid subnet mask ($mask)"
	set preflen 32
    }
    return $preflen
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

proc cisco-match-network {adr cidr} {
    if {! [regexp {^(.*)/(.*)$} $cidr bidon bidon2 preflen]} then {
	cisco-warning "Invalid network address ($cidr)"
	set r -1
    } else {
	set na [cisco-convert-ifadr-to-cidr "$adr/$preflen"]
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
#   - fdout : fichier de sortie pour la génération
#   - eq = <eqname>
# Remplit :
#   - tab(eq)	{<eqname> ... <eqname>}
#   - tab(eq!ios) "unsure|router|switch"
#
# Historique
#   2004/03/23 : pda/jean : conception
#   2004/06/08 : pda/jean : ajout de model
#   2007/07/12 : pda      : ajout de ios
#

proc cisco-parse {model fdin fdout tab eq} {
    upvar $tab t

    lappend t(eq) $eq
    set idx "eq!$eq"
    set t($idx!ios) "unsure"
    while {[gets $fdin line] > -1} {
	if {! [regexp {^!} $line]} then {
	    set error [cisco-parse-line $line t $idx]
	}
    }

    if {! $error} then {
	set error [cisco-post-process $model $fdout $eq t]
    }

    return $error
}

array set cisco_kwtab {
    interface				{CALL cisco-parse-interface}
    vlan				{CALL cisco-parse-vlan}
    name				{CALL cisco-parse-vlan-name}
    switchport				NEXT
    switchport-access			NEXT
    switchport-access-vlan		{CALL cisco-parse-access-vlan}
    switchport-mode			{CALL cisco-parse-mode}
    switchport-trunk			NEXT
    switchport-trunk-encapsulation	{CALL cisco-parse-encap}
    switchport-trunk-allowed		NEXT
    switchport-trunk-allowed-vlan	{CALL cisco-parse-allowed-vlan}
    ip					NEXT
    ip-address				{CALL cisco-parse-ip-address}
    ipv6				NEXT
    ipv6-address			{CALL cisco-parse-ipv6-address}
    description				{CALL cisco-parse-desc}
    channel-group			{CALL cisco-parse-channel-group}
    shutdown				{CALL cisco-parse-shutdown}
    snmp-server				NEXT
    snmp-server-community		{CALL cisco-parse-snmp-community}
    encapsulation			NEXT
    encapsulation-dot1Q			{CALL cisco-parse-encapsulation-dot1q}
    bridge-group			{CALL cisco-parse-bridge-group}
    router				{CALL cisco-parse-router}
}

#
# Analyse une ligne de conf IOS
#
# Entrée :
#   - line : extrait de conf
#   - tab : tableau contenant les informations résultant de l'analyse
#   - idx : index dans le tableau tab
#   - variable globale debug : affiche les mots-clefs
# Sortie :
#   - valeur de retour : 1 si erreur, 0 sinon
#
# Historique
#   2004/03/26 : pda/jean : conception (ouh la la !)
#

proc cisco-parse-line {line tab idx} {
    global debug
    global cisco_kwtab
    upvar $tab t

    if {$debug & 0x01} then {
	cisco-debug "$line"
    }

    set active 1
    set error 0
    set first 1
    set kwlist {}
    set finished 0
    while {! $finished} {
	#
	# Prendre le premier élément de la ligne
	#
	if {[regexp {^\s*(\S+)\s*(.*)$} $line bidon kw line]} then {
	    #
	    # cas spécial de "no ..." : on passe au suivant
	    #
	    if {$first} then {
		set first 0
		if {[string equal $kw "no"]} then {
		    set active 0
		    continue
		}
	    }

	    #
	    # Chercher
	    #

	    lappend kwlist $kw
	    set fullkw [join $kwlist "-"]
	    if {[info exists cisco_kwtab($fullkw)]} then {
		if {$debug & 0x01} then {
		    cisco-debug "match $fullkw ($line) -> $cisco_kwtab($fullkw)"
		}
		set action $cisco_kwtab($fullkw)
		switch [lindex $action 0] {
		    NEXT {
			# rien
		    }
		    CALL {
			set fct [lindex $action 1]
			set error [$fct $active $line t $idx]
			set finished 1
		    }
		    default {
			cisco-warning "Unvalid value in kwtab($fullkw) ($action)"
			set error 1
			set finished 1
		    }
		}
	    } else {
		set finished 1
	    }
	} else {
	    set finished 1
	}
    }

    return $error
}


#
# Entrée :
#   - line = "1,2,5-10,16" ou <autres commandes>
#   - idx = eq!<eqname>
# Remplit
#   - tab(eq!<nom eq>!lvlan) {<id> ... <id>}
#   - tab(eq!<nom eq>!lvlan!lastid) <id>
#   - tab(eq!<nom eq>!lvlan!<id>!desc) ""  (sera remplacé par parse-vlan-name)
#
# Historique
#   2007/06/15 : pda/jean : conception
#

proc cisco-parse-vlan {active line tab idx} {
    upvar $tab t

    set idx "$idx!lvlan"

    set line [string trim $line]
    if {[regexp {^[-,0-9]+$} $line]} then {
	set lvlan [split $line ","]
	foreach lv $lvlan {
	    set rg [split $lv "-"]
	    switch [llength $rg] {
		1 {
		    set v [lindex $rg 0]
		    set min $v
		    set max $v
		}
		2 {
		    set min [lindex $rg 0]
		    set max [lindex $rg 1]
		}
		default {
		    cisco-warning "Unrecognized vlan range ($vr) on $ifname"
		    set error 1
		    break
		}
	    }
	    for {set v $min} {$v <= $max} {incr v} {
		lappend t($idx) $v
		set t($idx!$v!desc) ""
	    }
	    set t($idx!lastid) $max
	}
    }

    return 0
}

#
# Entrée :
#   - line = <nom de vlan>
#   - idx = eq!<eqname>
#   - tab(eq!<nom eq>!lvlan!lastid) <id>
# Remplit
#   - tab(eq!<nom eq>!lvlan!<id>!desc) <desc>
#   - tab(eq!<nom eq>!lvlan!lastid) (remis à 0)
#
# Historique
#   2007/06/15 : pda/jean : conception
#

proc cisco-parse-vlan-name {active line tab idx} {
    upvar $tab t

    set idx "$idx!lvlan"
    if {[info exists t($idx!lastid)]} then {
	set id $t($idx!lastid)

	# traduction en hexa : cf analyser, fct parse-desc
	binary scan $line H* line
	set t($idx!$id!desc) $line
	unset t($idx!lastid)
    }

    return 0
}


#
# Entrée :
#   - line = "GigaEthernet1/2/6"
#	ou "ATM1/0.1 point-to-point"
#	ou "FastEthernet0.128"
#   - idx = eq!<eqname>
# Remplit en cas d'interface physique :
#   - tab(eq!<nom eq>!if) {<ifname> ... <ifname>}
#   - tab(eq!<nom eq>!current!physif) <physifname>
# Remplit en cas de sous-interface :
#   - tab(eq!<nom eq>!if!<physifname>!subif) { <ifname> ...} (liste des sous-i/f)
# Remplit dans tous les cas :
#   - tab(eq!<nom eq>!current!if) <ifname>
#
# Historique
#   2004/03/26 : pda/jean : conception
#   2007/07/12 : pda      : gestion des sous-interfaces
#

proc cisco-parse-interface {active line tab idx} {
    upvar $tab t

    set error 0

    set ifname [lindex $line 0]

    if {[regsub -- {\.[0-9]+$} $ifname {} physifname]} then {
	#
	# sous-interface d'une interface physique
	#

	if {! [string equal $physifname $t($idx!current!physif)]} then {
	    cisco-warning "Interface '$ifname' is not a sub-interface of '$t(idx!current!physif)'"
	    set error 1
	}
	lappend t($idx!if!$physifname!subif) $ifname

    } else {
	#
	# interface physique (ou Tunnel, ou Loopback, ou ...) mais en
	# en tous cas pas une sous-interface
	#

	lappend t($idx!if) $ifname
	set t($idx!current!physif) $ifname
    }

    #
    # dans tous les cas
    #

    set t($idx!current!if) $ifname

    return $error
}

#
# Entrée :
#   - line = "dot1q"
#   - idx = eq!<eqname>
# Remplit
#   - tab(eq!<nom eq>!if!<ifname>!link!type) trunk
#
# Historique
#   2004/03/26 : pda/jean : conception
#

proc cisco-parse-encap {active line tab idx} {
    upvar $tab t

    set ifname $t($idx!current!if)
    return [cisco-set-ifattr t $idx!if!$ifname type "trunk"]
}

#
# Entrée :
#   - line = "<vlan-id>"
#   - idx = eq!<eqname>
# Remplit
#   - tab(eq!<nom eq>!if!<ifname>!link!type) ether
#   - tab(eq!<nom eq>!if!<ifname>!link!vlans) {<vlan-id>}	(forcément 1 seul)
#
# Historique
#   2004/03/26 : pda/jean : conception
#

proc cisco-parse-access-vlan {active line tab idx} {
    upvar $tab t

    set error 0
    set ifname $t($idx!current!if)
    set vlanid [lindex $line 0]
    set error [cisco-set-ifattr t $idx!if!$ifname type "ether"]
    if {! $error} then {
	set error [cisco-set-ifattr t $idx!if!$ifname vlan $vlanid]
    }
    return $error
}

#
# Spécifique IOS-R
#
# Entrée :
#   - line = "<vlan-id>"
#   - idx = eq!<eqname>
#   - tab(eq!<nom eq>!current!if) <ifname>
#   - tab(eq!<nom eq>!current!physif) <physifname>
# Remplit
#   - tab(eq!<nom eq>!if!<physifname>!link!type) trunk
#   - tab(eq!<nom eq>!if!<ifname>!link!type) ether
#   - tab(eq!<nom eq>!if!<ifname>!vlans) <vlanid>
# Historique
#   2006/09/25 : lauce : conception
#   2007/07/12 : pda   : généralisation
#

proc cisco-parse-encapsulation-dot1q {active line tab idx} {
    upvar $tab t

    set error 0

    set vlanid [lindex $line 0]

    # nom de l'interface
    set ifname $t($idx!current!if)

    set error [expr [cisco-set-ifattr t $idx!if!$ifname type "ether"] \
		|| [cisco-set-ifattr t $idx!if!$ifname vlan $vlanid] \
		]

    if {! $error} then {
	if {[info exists t($idx!current!physif)]} then {
	    set physifname $t($idx!current!physif)
	    set error [cisco-set-ifattr t $idx!if!$physifname type "trunk"]
	}
    }

    return $error
}

#
# Entrée :
#   - line = "1,3-13,15-4094" ou "add 820" ou "none"
#   - idx = eq!<eqname>
#   - tab(eq!<nom eq>!current!if) <ifname>
# Remplit
#   - tab(eq!<nom eq>!if!<ifname>!link!allowedvlans) {{1 1} {3 13} {15 4094}}
#
# Historique
#   2004/03/26 : pda/jean : conception
#   2004/10/15 : pda      : ajout du cas "none"
#

proc cisco-parse-allowed-vlan {active line tab idx} {
    upvar $tab t

    set error 0

    set ifname $t($idx!current!if)
    set l {}
    if {[string equal [lindex $line 0] "none"]} then {
	set line [lreplace $line 0 0]
    } elseif {[string equal [lindex $line 0] "add"]} then {
	set line [lreplace $line 0 0]
	if {[info exists t($idx!if!$ifname!link!allowedvlans)]} then {
	    set l $t($idx!if!$ifname!link!allowedvlans)
	} else {
	    cisco-warning "Incorrect use of 'vlan add' on $ifname"
	    set error 1
	}
    }

    if {! $error} then {
	set alvlan [split [lindex $line 0] ","]
	foreach vr $alvlan {
	    set rg [split $vr "-"]
	    switch [llength $rg] {
		1 {
		    set v [lindex $rg 0]
		    lappend l [list $v $v]
		}
		2 {
		    lappend l $rg
		}
		default {
		    cisco-warning "Unrecognized vlan range ($vr) on $ifname"
		    set error 1
		    break
		}
	    }
	}
    }

    if {! $error} then {
	set error [cisco-set-ifattr t $idx!if!$ifname allowed-vlans $l]
    }

    return $error
}

#
# Entrée :
#   - line = "130.79.15.82 255.255.255.0 [secondary]"
#   - idx = eq!<eqname>
#   - tab(eq!<nom eq>!current!if) <ifname>
# Remplit
#   - tab(eq!<eqname>!if!<ifname>!networks) {<cidr46> ...}
#   - tab(eq!<nom eq>!if!<ifname>!net!<cidr46) <adr46>
#   - tab(eq!<eqname>!if!<ifname>!net!<cidr46>!preflen) <preflen>
#
# Historique
#   2004/07/16 : pda/jean : conception
#

proc cisco-parse-ip-address {active line tab idx} {
    upvar $tab t

    if {$active && ![string equal $t($idx!current!if) ""]} then {
	set ifname $t($idx!current!if)

	set addr [lindex $line 0]
	set mask [lindex $line 1]

	# extraire la longueur du préfixe à partir du masque
	set preflen [cisco-convert-mask-to-preflen $mask]

	# convertir l'adresse et le masque en CIDR du réseau
	set cidr [cisco-convert-ifadr-to-cidr $addr/$preflen]
	lappend t($idx!if!$ifname!networks) $cidr

	# stockage final
	lappend t($idx!if!$ifname!net!$cidr) $addr
	lappend t($idx!if!$ifname!net!$cidr!preflen) $preflen
    }

    return 0
}

#
# Entrée :
#   - line = "2001:660::/48 [secondary]"
#   - idx = eq!<eqname>
#   - tab(eq!<nom eq>!current!if) <ifname>
# Remplit
#   - tab(eq!<eqname>!if!<ifname>!networks) {<cidr46> ...}
#   - tab(eq!<nom eq>!if!<ifname>!net!<cidr46) <adr46>
#   - tab(eq!<eqname>!if!<ifname>!net!<cidr46>!preflen) <preflen>
#
# Historique
#   2004/07/16 : pda/jean : conception
#

proc cisco-parse-ipv6-address {active line tab idx} {
    upvar $tab t

    set error 0

    if {$active && ![string equal $t($idx!current!if) ""]} then {
	set ifname $t($idx!current!if)

	set parm [lindex $line 0]
	if {! [regexp {^(.*)/(.*)$} $parm bidon ifadr preflen]} then {
	    cisco-warning "$ifname: invalid address ($parm)"
	}

	set cidr [cisco-convert-ifadr-to-cidr $parm]
	if {[string equal $cidr ""]} then {
	    set error 1
	} else {
	    lappend t($idx!if!$ifname!networks) $cidr
	    set idx "$idx!if!$ifname!net!$cidr"
	    set t($idx) $ifadr
	    set t($idx!preflen) $preflen
	}
    }

    return $error
}

#
# Entrée :
#   - line = <description de l'interface>
#   - idx = eq!<eqname>
#   - tab(eq!<nom eq>!current!if) <ifname>
# Remplit
#   - tab(eq!<nom eq>!if!<ifname>!link!name) <linkname>
#   - tab(eq!<nom eq>!if!<ifname>!link!stat) <statname> ou vide
#   - tab(eq!<nom eq>!if!<ifname>!link!desc) <desc>
#
# Historique
#   2004/03/26 : pda/jean : conception
#   2006/05/23 : pda/jean : ajout de stat
#   2007/01/06 : pda      : ajout desc interface
#

proc cisco-parse-desc {active line tab idx} {
    upvar $tab t

    set error 0
    if {! [string equal $t($idx!current!if) ""]} then {
	set ifname $t($idx!current!if)

	if {[parse-desc $line linkname statname descname msg]} then {
	    if {[string equal $linkname ""]} then {
		cisco-warning "$idx: no link name found ($line)"
		set error 1
	    } else {
		set error [cisco-set-ifattr t $idx!if!$ifname name $linkname]
	    }
	    if {! $error} then {
		set error [cisco-set-ifattr t $idx!if!$ifname stat $statname]
	    }
	    if {! $error} then {
		set error [cisco-set-ifattr t $idx!if!$ifname desc $descname]
	    }
	} else {
	    cisco-warning "$idx: $msg ($line)"
	    set error 1
	}
    }

    return $error
}

#
# Entrée :
#   - line = "1 mode active" ou "1 mode on" ou "1 mode n'importequoi"
#   - idx = eq!<eqname>
#   - tab(eq!<nom eq>!current!if) <ifname>
# Remplit
#   - tab(eq!<nom eq>!if!<ifname>!link!parentif) "Port-channelN"
#
# Historique
#   2004/03/26 : pda/jean : conception
#

proc cisco-parse-channel-group {active line tab idx} {
    upvar $tab t

    set ifname $t($idx!current!if)
    set parentif [lindex $line 0]
    set i $idx!if!$ifname
    return [cisco-set-ifattr t $i parentif "Port-channel$parentif"]
}


#
# Entrée :
#   - line = ""
#   - idx = eq!<eqname>
#   - tab(eq!<nom eq>!current!if) <ifname>
# Enleve le nom de l'interface courante de tab(eq!<nom eq>!if)
#
# Historique
#   2004/03/26 : pda/jean : conception
#   2006/09/25 : lauce    : ajout if {$active} pour le "no shutdown"
#

proc cisco-parse-shutdown {active line tab idx} {
    upvar $tab t

    set error 0
    if {$active
	    && ![string equal $t($idx!current!if) ""]
	    && [string equal $t($idx!current!if) $t($idx!current!physif)]
	    } then {
	set error [cisco-remove-if t($idx!if) $t($idx!current!if)]
    }
    return $error
}

proc cisco-remove-if {var ifname} {
    upvar $var v

    set error 0
    set pos [lsearch -exact $v $ifname]
    if {$pos == -1} then {
	cisco-warning "Cannot remove $ifname from list of active interfaces"
	set error 1
    } else {
	set v [lreplace $v $pos $pos]
    }
    return $error
}


#
# Entrée :
#   - line = "trunk" ou "access"
#   - idx = eq!<eqname>
#   - tab(eq!<nom eq>!current!if) <ifname>
# Remplit :
#   - tab(eq!<nom eq>!ios) "switch"
#   - tab(eq!<nom eq>!if!<ifname>!type) access|trunk
#
# Historique
#   2004/03/26 : pda/jean : conception
#

proc cisco-parse-mode {active line tab idx} {
    upvar $tab t

    set t($idx!ios) "switch"

    set ifname $t($idx!current!if)
    set ty [lindex $line 0]
    set error 0
    switch -- $ty {
	access {
	    set error [cisco-set-ifattr t $idx!if!$ifname type "ether"]
	}
	trunk {
	    set error [cisco-set-ifattr t $idx!if!$ifname type "trunk"]
	}
	default {
	    cisco-warning "Unknown switchport-mode ($ty)"
	    set error 1
	}
    }
    return $error
}


#
# Entrée :
#   - line = <communaute> <blah blah>
#   - idx = eq!<eqname>
# Remplit :
#   - tab(eq!<nom eq>!snmp) {<communaute> ...}
#
# Historique
#   2006/01/06 : pda/jean : conception
#

proc cisco-parse-snmp-community {active line tab idx} {
    upvar $tab t

    if {[regexp {^\s*(\S+)\s*(.*)$} $line bidon comm reste]} then {
	lappend t($idx!snmp) $comm
	set error 0
    } else {
	cisco-warning "Inconsistent SNMP community string ($line)"
	set error 1
    }
    return $error
}

#
#
# Entrée :
#   - line = "<bg-id> [ ... ]"
#   - idx = eq!<eqname>
#   - tab(eq!<nom eq>!current!if) <ifname>
# Remplit
#   - tab(eq!<nom eq>!bridge) {<bgid> ...}
#   - tab(eq!<nom eq>!if!<ifname>!bridge) <bgid>
#   - tab(eq!<nom eq>!bridge!<bgid>!if) <ifname>
# Historique
#   2007/07/12 : pda   : conception
#

proc cisco-parse-bridge-group {active line tab idx} {
    upvar $tab t

    set error 0

    # nom de l'interface
    set ifname $t($idx!current!if)

    if {[regexp {^[0-9]+$} $line bgid]} then {
	set t($idx!if!$ifname!bridge) $bgid
	lappend t($idx!bridge) $bgid
	lappend t($idx!bridge!$bgid!if) $ifname
    }

    return $error
}

#
# Entrée :
#   - line = ""
#   - idx = eq!<eqname>
#   - tab(eq!<nom eq>!current!if) <ifname>
#   - tab(eq!<nom eq>!current!physif) <ifname>
# Vilain hack pour supprimer la notion d'interface courante
#
# Historique
#   2007/07/16 : pda      : conception
#

proc cisco-parse-router {active line tab idx} {
    upvar $tab t

    set t($idx!current!if) ""
    set t($idx!current!physif) ""
    return 0
}


###############################################################################
# Attributs d'une interface
###############################################################################

#
# Spécifie les attributs d'une interface
#
# Entrée :
#   - tab : nom du tableau
#   - idx : index (jusqu'au nom de l'interface : "eq!<nom eq>!if!<ifname>")
#   - attr : name, stat, type, ifname, vlan, allowed-vlans
#   - val : valeur de l'attribut
#
# Sortie :
# - Si lien trunk :
#   - tab(eq!<nom eq>!if!<ifname>!link!type) trunk
#   - tab(eq!<nom eq>!if!<ifname>!link!allowedvlans) {{1 1} {3 13} {15 4094}}
# - Si lien ether :
#   - tab(eq!<nom eq>!if!<ifname>!link!type) ether
#   - tab(eq!<nom eq>!if!<ifname>!link!vlans) {<vlan-id>}    (forcément 1 seul)
# - Si lien aggregate : idem trunk ou ether, avec en plus :
#   - tab(eq!<nom eq>!if!<ifname>!link!parentif) <parent-if-name>
#
# Historique
#   2004/06/09 : pda/jean : conception
#   2006/05/23 : pda/jean : ajout des points de collecte (stat)
#

proc cisco-set-ifattr {tab idx attr val} {
    upvar $tab t

    set error 0
    switch $attr {
	name {
	    set t($idx!link!name) $val
	}
	stat {
	    set t($idx!link!stat) $val
	}
	desc {
	    set t($idx!link!desc) $val
	}
	type {
	    if {[info exists t($idx!link!type)]} then {
		if {[string equal $t($idx!link!type) $val]} then {
		    set error 0
		} else {
		    cisco-warning "Incoherent switchport-mode ($val) for $idx"
		    set error 1
		}
	    } else {
		set t($idx!link!type) $val
		switch -- $val {
		    ether {
			if {! [info exists t($idx!link!vlans)]} then {
			    set t($idx!link!vlans) {1}
			}
		    }
		    trunk {
			if {! [info exists t($idx!link!allowedvlans)]} then {
			    set t($idx!link!allowedvlans) {{1 4095}}
			}
		    }
		}
		set error 0
	    }
	}
	parentif {
	    set t($idx!link!parentif) $val
	}
	vlan {
	    if {[info exists t($idx!link!type)]} then {
		if {! [string equal $t($idx!link!type) "ether"]} then {
		    cisco-warning "Access vlan for a not-access interface ($idx)"
		    set error 1
		}
	    } else {
		set t($idx!link!type) "ether"
	    }
	    set t($idx!link!vlans) [list $val]
	}
	allowed-vlans {
	    if {[info exists t($idx!link!type)]} then {
		if {! [string equal $t($idx!link!type) "trunk"]} then {
		    cisco-warning "Allowed vlans for a not-trunk interface ($idx)"
		    set error 1
		}
	    } else {
		set t($idx!link!type) "trunk"
	    }
	    set t($idx!link!allowedvlans) $val
	}
	default {
	    cisco-warning "Incorrect attribute type for $idx (internal error)"
	    set error 1
	}
    }
    return $error
}

###############################################################################
# Traitement après analyse
###############################################################################

#
# Effectue quelques contrôles et positionnements de valeurs par défaut
# sur le résultat de l'analyse
#
# Entrée :
#   - model : modèle de l'équipement
#   - eq : nom de l'équipement
#   - tab : tableau rempli au cours de l'analyse
# Sortie :
#   - valeur de retour : 0 si pas d'erreur, 1 si erreur
#   - tab : tableau modifié
#
# Historique
#   2004/06/09 : pda/jean : conception
#

proc cisco-sanitize {model eq tab} {
    upvar $tab t

    #
    # Parcourir toutes les interfaces pour mettre des valeurs
    # par défaut si besoin est
    #

    set error 0
    foreach iface $t(eq!$eq!if) {
	set e 0
	if {! [info exists t(eq!$eq!if!$iface!link!type)]} then {
	    set e [cisco-set-ifattr t eq!$eq!if!$iface type "ether"]
	}
	set error [expr $error || $e]
    }

    return $error
}

#
# Traite le tableau résultant de l'analyse pour permettre d'accéder
# plus facilement aux réseaux (de niveau 3) et aux liens (de niveau 2)
# gérés par cet équipement
#
# Entrée :
#   - model : modèle de l'équipement
#   - fdout : fichier de sortie pour la génération
#   - eq : nom de l'équipement
#   - tab : tableau rempli au cours de l'analyse
# Sortie :
#   - valeur de retour : 0 si pas d'erreur, 1 si erreur
#   - tab : tableau modifié
#
# Historique
#   2004/03/26 : pda/jean  : conception
#   2004/06/08 : pda/jean  : changement de format du fichier de sortie
#   2006/06/01 : pda/jean  : ajout snmp
#   2006/08/21 : pda/pegon : liens X+X+X+...+X deviennent X
#   2007/06/15 : pda/jean  : description des vlans locaux
#   2007/07/12 : pda       : debut conception sous-interface (ios router)
#

proc cisco-post-process {model fdout eq tab} {
    global debug
    upvar $tab t

    if {$debug & 0x02} then {
	debug-array t
    }

    if {[cisco-sanitize $model $eq t]} then {
	return 1
    }

    set ios $t(eq!$eq!ios)

    if {[info exists t(eq!$eq!snmp)]} then {
	# XXX : on ne prend que la première communauté trouvée
	set c [lindex $t(eq!$eq!snmp) 0]
    } else {
	set c "-"
    }
    puts $fdout "eq $eq type cisco model $model snmp $c"

    #
    # Sortir tous les vlans locaux
    #

    if {[info exists t(eq!$eq!lvlan)]} then {
	foreach id $t(eq!$eq!lvlan) {
	    set desc $t(eq!$eq!lvlan!$id!desc)
	    puts -nonewline $fdout "lvlan $eq $id declared yes"
	    if {[string equal $desc ""]} then {
		puts $fdout " desc -"
	    } else {
		puts $fdout " desc $desc"
	    }
	}
    }

    #
    # Chercher tous les liens. Pour cela, parcourir la liste
    # des interfaces.
    # Si une interface est un constituant d'un lien agrégé,
    # supprimer l'interface de la liste et actualiser le numéro
    # de lien du portchannel correspondant.
    #
    unset -nocomplain agtab

    # constituer les noms des liens agrégés et repérer
    # les interfaces sans description
    set error 0
    foreach iface $t(eq!$eq!if) {
	if {[regexp {^(Vlan|Tunnel|BVI|Null|Loopback)[0-9]+} $iface]} then {
	    # rien. On ignore l'absence de description pour
	    # ces interfaces.
	} elseif {[info exists t(eq!$eq!if!$iface!link!name)]} then {
	    set linkname $t(eq!$eq!if!$iface!link!name)
	    if {[info exists t(eq!$eq!if!$iface!link!parentif)]} then {
		set parentif $t(eq!$eq!if!$iface!link!parentif)
		lappend agtab($parentif) $linkname
		set error [cisco-remove-if t(eq!$eq!if) $iface]
	    }
	} else {
	    cisco-warning "$eq/$iface : missing description"
	    set error 1
	}
    }
    if {$error} then {
	return 1
    }

    # composer la description des interfaces  agrégées
    foreach iface [array names agtab] {
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
	set t(eq!$eq!if!$iface!link!name) $linkname
    }
    unset -nocomplain agtab

    #
    # Sortir la liste des interfaces physiques
    #

    foreach iface $t(eq!$eq!if) {
	if {! [regexp {^(Vlan|Tunnel|Null|Loopback|BVI)([0-9]+)$} $iface bidon type vlan]} then {
	    set linkname $t(eq!$eq!if!$iface!link!name)
	    set linktype $t(eq!$eq!if!$iface!link!type)
	    set statname $t(eq!$eq!if!$iface!link!stat)
	    if {[string equal $statname ""]} then {
		set statname "-"
	    }
	    set descname $t(eq!$eq!if!$iface!link!desc)
	    if {[string equal $descname ""]} then {
		set descname "-"
	    }

	    set nodeL1 [newnode]
	    puts $fdout "node $nodeL1 type L1 eq $eq name $iface link $linkname encap $linktype stat $statname desc $descname"

	    set t(eq!$eq!if!$iface!node) $nodeL1
	}
    }

    #
    # Le reste du traitement est fondamentalement différent
    #

    if {[string equal $ios "switch"]} then {
	#######################################################################
	# IOS Switch
	#######################################################################

	set nodeB [newnode]
	puts $fdout "node $nodeB type brpat eq $eq"

	# retrouver les liens de niveau 2
	# (sans le détail des constituants d'un lien agrégé)
	foreach iface $t(eq!$eq!if) {
	    if {[regexp {^Vlan([0-9]+)} $iface bidon vlan]} then {
		if {[info exists t(eq!$eq!if!$iface!networks)]} then {
		    set nodeL2 [newnode]
		    puts $fdout "node $nodeL2 type L2 eq $eq vlan $vlan stat -"
		    puts $fdout "link $nodeL2 $nodeB"

		    foreach nodeL3 [cisco-output-ip4 $fdout t $eq $iface] {
			puts $fdout "link $nodeL3 $nodeL2"
		    }
		    foreach nodeL3 [cisco-output-ip6 $fdout t $eq $iface] {
			puts $fdout "link $nodeL3 $nodeL2"
		    }
		}
	    } else {
		set nodeL1 $t(eq!$eq!if!$iface!node)
		set nodeL2 [newnode]

		if {! [string equal $linktype "aggregate"]} then {
		    switch $t(eq!$eq!if!$iface!link!type) {
			ether {
			    # il ne peut y avoir qu'un seul "vlan" sur un lien natif
			    set arg $t(eq!$eq!if!$iface!link!vlans)

			    puts $fdout "node $nodeL2 type L2 eq $eq vlan $arg stat -"
			}
			trunk {
			    # Liste des vlans pour ce lien
			    set av $t(eq!$eq!if!$iface!link!allowedvlans)
			    puts -nonewline $fdout "node $nodeL2 type L2pat eq $eq"
			    foreach a $av {
				puts -nonewline $fdout " allow $a"
			    }
			    puts $fdout ""
			}
			default {
			    cisco-warning "Unknown link type for '$eq/$iface"
			}
		    }
		    puts $fdout "link $nodeL1 $nodeL2"
		    puts $fdout "link $nodeL2 $nodeB"
		}
	    }
	}
    } else {
	#######################################################################
	# IOS Router
	#######################################################################

	set ip4 {}
	set ip6 {}

	#
	# Sortir la liste des bridges et des adresses IP associées
	#

	if {[info exists t(eq!$eq!bridge)]} then {
	    set lbridge [lsort -integer  -unique $t(eq!$eq!bridge)]
	} else {
	    set lbridge {}
	}

	foreach bgid $lbridge {
	    #
	    # Noeud bridge
	    #
	    set nodeB [newnode]
	    set t(eq!$eq!bridge!$bgid!node) $nodeB
	    puts $fdout "node $nodeB type bridge eq $eq"

	    #
	    # Adresses IP associées ?
	    #
	    set iface BVI$bgid
	    if {[info exists t(eq!$eq!if!$iface!networks)]} then {
		foreach nodeL3 [cisco-output-ip4 $fdout t $eq BVI$bgid] {
		    lappend ip4 $nodeL3
		    puts $fdout "link $nodeL3 $nodeB"
		}
		foreach nodeL3 [cisco-output-ip6 $fdout t $eq BVI$bgid] {
		    lappend ip6 $nodeL3
		    puts $fdout "link $nodeL3 $nodeB"
		}
		cisco-remove-if t(eq!$eq!if) $iface
	    }
	}

	#
	# Parcourir la liste des interfaces, sortir les adresses IP
	# et faire de même (avec les vlans) pour les sous-interfaces.
	#

	foreach iface $t(eq!$eq!if) {

	    #
	    # Est-ce qu'il existe des sous-interfaces ?
	    #

	    if {[info exists t(eq!$eq!if!$iface!node)]
		    && [info exists t(eq!$eq!if!$iface!subif)]} then {
		set nodeL1 $t(eq!$eq!if!$iface!node)

		#
		# Parcourir la liste des sous-interfaces
		#

		foreach subif $t(eq!$eq!if!$iface!subif) {

		    #
		    # Sortir le L2 approprié, connecté à l'interface
		    # physique
		    #

		    if {[info exists t(eq!$eq!if!$subif!link!stat)]} then {
			set statname $t(eq!$eq!if!$subif!link!stat)
			if {[string equal $statname ""]} then {
			    set statname "-"
			}
		    } else {
			set statname "-"
		    }
		    set vlanid $t(eq!$eq!if!$subif!link!vlans)
		    set nodeL2 [newnode]
		    puts $fdout "node $nodeL2 type L2 eq $eq vlan $vlanid stat $statname"

		    puts $fdout "link $nodeL2 $nodeL1"

		    #
		    # Sortir le L3 si besoin est, éventuellement
		    # interconnecté à un bridge.
		    #

		    set isbridge 0
		    if {[info exists t(eq!$eq!if!$subif!bridge)]} then {
			set bgid $t(eq!$eq!if!$subif!bridge)
			set nodeB $t(eq!$eq!bridge!$bgid!node) 
			puts $fdout "link $nodeL2 $nodeB"
			set isbridge 1
		    }

		    set xip4 [cisco-output-ip4 $fdout t $eq $subif]
		    set xip6 [cisco-output-ip6 $fdout t $eq $subif]
		    set xip [concat $xip4 $xip6]
		    set isip [expr [llength $xip] > 0]

		    switch "$isbridge$isip" {
			00 {
			    cisco-warning "Interface '$eq/$subif' not used"
			}
			01 {
			    foreach nodeL3 $xip4 {
				puts $fdout "link $nodeL2 $nodeL3"
				lappend ip4 $nodeL3
			    }
			    foreach nodeL3 $xip6 {
				puts $fdout "link $nodeL2 $nodeL3"
				lappend ip6 $nodeL3
			    }
			}
			10 {
			    # rien, le lien L2-B est déjà sorti plus haut
			}
			11 {
			    foreach nodeL3 $xip4 {
				puts $fdout "link $nodeB $nodeL3"
				lappend ip4 $nodeL3
			    }
			    foreach nodeL3 $xip6 {
				puts $fdout "link $nodeB $nodeL3"
				lappend ip6 $nodeL3
			    }
			}
		    }
		}
	    } elseif {[info exists t(eq!$eq!if!$iface!node)]} then {

		set nodeL1 $t(eq!$eq!if!$iface!node)

		if {[info exists t(eq!$eq!if!$iface!link!stat)]} then {
		    set statname $t(eq!$eq!if!$iface!link!stat)
		    if {[string equal $statname ""]} then {
			set statname "-"
		    }
		} else {
		    set statname "-"
		}

		#
		# Vlan 0 (mode access), puis sortir toutes les
		# interfaces, connectées éventuellement par un
		# bridge si besoin est.
		#

		set nodeL2 [newnode]
		puts $fdout "node $nodeL2 type L2 eq $eq vlan 0 stat $statname"
		puts $fdout "link $nodeL2 $nodeL1"

		foreach nodeL3 [cisco-output-ip4 $fdout t $eq $iface] {
		    lappend ip4 $nodeL3
		    puts $fdout "link $nodeL2 $nodeL3"
		}
		foreach nodeL3 [cisco-output-ip6 $fdout t $eq $iface] {
		    lappend ip6 $nodeL3
		    puts $fdout "link $nodeL2 $nodeL3"
		}
	    }
	}

	if {[llength $ip4] > 1} then {
	    set nodeR4 [newnode]
	    puts $fdout "node $nodeR4 type router eq $eq instance _v4"
	    foreach n $ip4 {
		puts $fdout "link $n $nodeR4"
	    }
	}

	if {[llength $ip6] > 1} then {
	    set nodeR6 [newnode]
	    puts $fdout "node $nodeR6 type router eq $eq instance _v6"
	    foreach n $ip6 {
		puts $fdout "link $n $nodeR6"
	    }
	}
    }

    return 0
}

proc cisco-output-ip4 {fdout tab eq iface} {
    global debug
    upvar $tab t

    set lnodes {}
    set idx eq!$eq!if!$iface
    if {[info exists t($idx!networks)]} then {
	foreach net $t($idx!networks) {
	    set addr $t($idx!net!$net)
	    if {[regexp {\.} $addr]} then {
		set len  $t($idx!net!$net!preflen)
		set nodeL3 [newnode]
		puts $fdout "node $nodeL3 type L3 eq $eq addr $addr/$len"
		lappend lnodes $nodeL3
	    }
	}
    }
    return $lnodes
}

proc cisco-output-ip6 {fdout tab eq iface} {
    global debug
    upvar $tab t

    set lnodes {}
    set idx eq!$eq!if!$iface
    if {[info exists t($idx!networks)]} then {
	foreach net $t($idx!networks) {
	    set addr $t($idx!net!$net)
	    if {[regexp {:} $addr]} then {
		set len  $t($idx!net!$net!preflen)
		set nodeL3 [newnode]
		puts $fdout "node $nodeL3 type L3 eq $eq addr $addr/$len"
		lappend lnodes $nodeL3
	    }
	}
    }
    return $lnodes
}

###############################################################################
# Initialisation du module
###############################################################################

cisco-init
