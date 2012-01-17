#
#
# Package d'analyse de fichiers de configuration IOS HP
#
# Historique
#   2008/07/07 : pda/jean : début de la conception
#   2009/02/11 : pda      : analyse des listes de la forme C24-D2
#

#
# Nombre de ports sur les modules des HP
#   J4820A XL 10/100-TX module
#   J4821A XL 100/1000-T module
#   J4821B XL 100/1000-T module
#   J4878A XL mini-GBIC module
#   J4878B XL mini-GBIC module
#   J4907A XL Gig-T/GBIC module
#   J8702A 24p Gig-T zl Module
#

array set hpmodules {
    J4820A	24
    J4821A	4
    J4821B	4
    J4878A	4
    J4878B	4
    J4907A	16
    J8702A	24
    J90XXA      48
    J86yyA      1
    J86xxA      1
}

###############################################################################
# Fonctions utilitaires
###############################################################################

#
# Entrée :
#   - idx = eq!<eqname>
#   - iface = <iface>
# Remplit
#   - tab(eq!<nom eq>!if) {<ifname> ... <ifname>}
#
# Historique
#   2008/07/21 : pda/jean : conception
#

proc hp-ajouter-iface {tab idx iface} {
    upvar $tab t

    if {[lsearch -exact $t($idx!if) $iface] == -1} then {
	lappend t($idx!if) $iface
	if {! [info exists t($idx!if!$iface!link!name)]} then {
	    hp-set-ifattr t $idx!if!$iface "name" "X"
	    hp-set-ifattr t $idx!if!$iface "stat" "-"
	    hp-set-ifattr t $idx!if!$iface "desc" ""
	}
    }
}

###############################################################################
# Analyse du fichier de configuration
###############################################################################

#
# Entrée :
#   - libdir : répertoire contenant les greffons d'analyse
#   - model : modèle de l'équipement (ex: M20)
#   - fdin : descripteur de fichier en entrée
#   - fdout : fichier de sortie pour la génération
#   - eq = <eqname>
# Remplit :
#   - tab(eq)	{<eqname> ... <eqname>}
#   - tab(eq!ios) "unsure|router|switch"
#
# Historique
#   2008/07/07 : pda/jean : conception
#

proc hp-parse {libdir model fdin fdout tab eq} {
    upvar $tab t
    array set kwtab {
	-COMMENT			^;
	module				{CALL hp-parse-module}
	interface			{CALL hp-parse-interface}
	vlan				{CALL hp-parse-vlan}
	exit				{CALL hp-parse-exit}
	disable				{CALL hp-parse-disable}
	name				{CALL hp-parse-name}
	trunk				{CALL hp-parse-trunk}
	snmp-server			NEXT
	snmp-server-location		{CALL hp-parse-snmp-location}
	snmp-server-community		{CALL hp-parse-snmp-community}
	untagged			{CALL hp-parse-untagged}
	tagged				{CALL hp-parse-tagged}
    }

    #
    # On charge la bibliothèque de fonctions "cisco" pour bénéficier
    # de la meeeeeerveilleuse fonction "post-process"
    #

    set error [charger $libdir "parse-cisco.tcl"]
    if {$error} then {
	return $error
    }

    #
    # Analyse du fichier
    #

    set t(eq!$eq!context) ""
    set t(eq!$eq!if) {}
    set t(eq!$eq!if!disabled) {}
    set t(eq!$eq!modules) {}

    set error [ios-parse $libdir $model $fdin $fdout t $eq kwtab]

    set t(eq!$eq!ios) "switch"

    if {! $error} then {
	set error [hp-prepost-process $eq t]
    }

    if {! $error} then {
	set error [cisco-post-process "hp" $fdout $eq t]
    }
    return $error
}

#
# Entrée :
#   - line = "<position> type <ref>"
#   - idx = eq!<eqname>
# Remplit
#   - tab(eq!<nom eq>!modules) {{A <ports>} {B <nports>} ...}
#
# Historique
#   2009/02/11 : pda      : conception
#

proc hp-parse-module {active line tab idx} {
    upvar $tab t
    global hpmodules

    set line [string trim $line]
    if {[regexp {^([0-9]+) type (.*)$} $line bidon pos ref]} then {
	if {[info exists hpmodules($ref)]} then {
	    #
	    # les vieilles magouilles sur les codes ASCII sont
	    # encore les meilleurs moyens de convertir des codes
	    # numériques vers des lettres
	    #
	    set lettre [format "%c" [expr 64 + $pos]]
	    lappend t($idx!modules) [list $lettre $hpmodules($ref)]
	    set t($idx!modules) [lsort -index 0 $t($idx!modules)]
	} else {
	    warning "$idx: incorrect 'module' specification (module $line)"
	}
    } else {
	warning "$idx: incorrect 'module' specification (module $line)"
    }

    return 0
}

#
# Entrée :
#   - line = "<id>"
#   - idx = eq!<eqname>
# Remplit
#   - tab(eq!<nom eq>!if) {<ifname> ... <ifname>}
#   - tab(eq!<nom eq>!current!if) <ifname>
#   - tab(eq!<nom eq>!if!<ifname>!link!name) ""
#   - tab(eq!<nom eq>!if!<ifname>!link!desc) ""
#   - tab(eq!<nom eq>!if!<ifname>!link!stat) ""
#   - tab(eq!<nom eq>!context) iface
#
# Historique
#   2008/07/07 : pda/jean : conception
#   2008/10/10 : pda      : correction bug si plusieurs occurrences de l'i/f
#

proc hp-parse-interface {active line tab idx} {
    upvar $tab t

    set line [string trim $line]
    if {[regexp {^[-A-Za-z0-9]+$} $line]} then {
	set t($idx!context) "iface"
	set t($idx!current!if) $line
	#
	# Il est possible que l'interface apparaisse deux fois
	# dans le fichier de configuration :
	#	interface 1
	#	  name "..."
	#	  no lacp
	#	exit
	#	...
	#	interface 1
	#	  mdix-mode mdix
	#	exit
	# => ne pas tout mettre à zéro.
	#
	if {! [info exists t($idx!if!$line!link!name)]} then {
	    lappend t($idx!if) $line
	    set t($idx!if!$line!link!name) ""
	    set t($idx!if!$line!link!desc) ""
	    set t($idx!if!$line!link!stat) ""

	    hp-ajouter-iface t $idx $line
	}
    }

    return 0
}

#
# Entrée :
#   - line = <vlanid>
#   - idx = eq!<eqname>
# Remplit
#   - tab(eq!<nom eq>!lvlan) {<id> ... <id>}
#   - tab(eq!<nom eq>!lvlan!lastid) <id>
#   - tab(eq!<nom eq>!lvlan!<id>!desc) ""  (sera remplacé par parse-vlan-name)
#   - tab(eq!<nom eq>!context) vlan
#
# Historique
#   2008/07/07 : pda/jean : conception
#

proc hp-parse-vlan {active line tab idx} {
    upvar $tab t

    set line [string trim $line]
    if {[regexp {^[0-9]+$} $line]} then {
	set t($idx!context) "vlan"
	set idx "$idx!lvlan"
	lappend t($idx) $line
	set t($idx!lastid) $line
	set t($idx!$line!desc) ""
    }

    return 0
}

#
# Entrée :
#   - line = <>
#   - idx = eq!<eqname>
#   - tab(eq!<nom eq>!context) iface
# Remplit
#   - tab(eq!<nom eq>!context) ""
#
# Historique
#   2008/07/07 : pda/jean : conception
#

proc hp-parse-exit {active line tab idx} {
    upvar $tab t

    set t($idx!context) ""
    return 0
}

#
# Entrée :
#   - line = <>
#   - idx = eq!<eqname>
#   - tab(eq!<nom eq>!context) iface
#   - tab(eq!<nom eq>!current!if) <ifname>
# Remplit
#   - tab(eq!<nom eq>!context) ""
#   - tab(eq!<nom eq>!if!disabled) {... <ifname>}
#
# Note : on ne peut pas simplement supprimer l'interface, car elle
#   réapparaîtra plus tard lors de l'analyse des vlans
#
# Historique
#   2008/07/24 : pda      : conception
#

proc hp-parse-disable {active line tab idx} {
    upvar $tab t

    if {[string equal $t($idx!context) "iface"]} then {
	lappend t($idx!if!disabled) $t($idx!current!if)
    }
    return 0
}

#
# Entrée :
#   - line = <>
#   - idx = eq!<eqname>
#   - tab(eq!<nom eq>!context) "iface" ou "vlan"
#   - tab(eq!<nom eq>!lvlan!lastid) <id>   (si context = "vlan")
#   - tab(eq!<nom eq>!current!if) <ifname> (si context = "iface")
# Remplit
#   - tab(eq!<nom eq>!if!<ifname>!link!desc) <desc>
#   - tab(eq!<nom eq>!if!<ifname>!link!name) <name>
#   - tab(eq!<nom eq>!if!<ifname>!link!stat) <stat>
#	OU
#   - tab(eq!<nom eq>!lvlan!<id>!desc) <desc>
#
# Historique
#   2008/07/07 : pda/jean : conception
#

proc hp-parse-name {active line tab idx} {
    upvar $tab t

    set error 0
    switch $t($idx!context) {
	iface {
	    set ifname $t($idx!current!if)

	    if {[parse-desc $line linkname statname descname msg]} then {
		if {[string equal $linkname ""]} then {
		    warning "$idx: no link name found ($line)"
		    set error 1
		} else {
		    set error [hp-set-ifattr t $idx!if!$ifname name $linkname]
		}
		if {! $error} then {
		    set error [hp-set-ifattr t $idx!if!$ifname stat $statname]
		}
		if {! $error} then {
		    set error [hp-set-ifattr t $idx!if!$ifname desc $descname]
		}
	    } else {
		warning "$idx: $msg ($line)"
		set error 1
	    }
	}
	vlan {
	    set vlanid $t($idx!lvlan!lastid)

	    regsub {^\s*"?(.*)"?\s*$} $line {\1} line

	    # traduction en hexa : cf analyser, fct parse-desc
	    binary scan $line H* line
	    set t($idx!lvlan!$vlanid!desc) $line
	}
	default {
	    warning "Inconsistent context '$t($idx!context)' for name '$line'"
	}
    }

    return $error
}

#
# Entrée :
#   - line = <iface>-<iface>,... <trunkif> <mode>
#   - idx = eq!<eqname>
# Remplit
#   - tab(eq!<nom eq>!if!<iface>!parentif) <trunkif>	(pour toutes les iface)
#
# Historique
#   2008/07/07 : pda/jean : conception
#

proc hp-parse-trunk {active line tab idx} {
    upvar $tab t

    if {[regexp {^\s*([-A-Za-z0-9,]+)\s+(\S+)} $line bidon subifs parentif]} then {
	hp-ajouter-iface t $idx $parentif

	set lsubif [parse-list $subifs yes $t($idx!modules)]
	foreach subif $lsubif {
	    set error [hp-set-ifattr t $idx!if!$subif parentif $parentif]
	    if {$error} then {
		break
	    }
	    hp-ajouter-iface t $idx $subif
	}
    } else {
	warning "Invalid trunk specification ($line)"
	set error 1
    }

    return $error
}

#
# Entrée :
#   - line = <localisation> <blah blah>
#   - idx = eq!<eqname>
# Remplit :
#   - tab(eq!<nom eq>!location) {<localisation> ...}
#
# Historique
#   2012/01/17 : jean : recuperation de cisco-parse-snmp-location
#

proc hp-parse-snmp-location {active line tab idx} {
    upvar $tab t

    set error 0
    set ipmac 0
    set portmac 0
    if {[parse-location $line location ipmac portmac blablah msg]} then {
        if {! [string equal $location ""]} then {
            set t($idx!location) [list $location $blablah]
        }
    } else {
        warning "$idx: $msg ($line)"
        set error 1
    }

    set t($idx!ipmac) $ipmac
    set t($idx!portmac) $portmac

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

proc hp-parse-snmp-community {active line tab idx} {
    upvar $tab t

    if {[regexp {^\s*"(\S+)"\s*(.*)$} $line bidon comm reste]} then {
	lappend t($idx!snmp) $comm
	set error 0
    } else {
	warning "Inconsistent SNMP community string ($line)"
	set error 1
    }
    return $error
}

#
# Entrée :
#   - line = <iflist>
#   - idx = eq!<eqname>
#   - tab(eq!<nom eq>!context) "vlan"
#   - tab(eq!<nom eq>!lvlan!lastid) <id>   (si context = "vlan")
# Remplit
#   - tab(eq!<nom eq>!if!<ifname>!link!type) <ether/trunk>
#   - tab(eq!<nom eq>!if!<ifname>!link!vlans) {vlanid...}
#
# Historique
#   2008/07/21 : pda/jean : conception
#

proc hp-parse-untagged {active line tab idx} {
    upvar $tab t

    set error 0

    if {$active} then {
	set vlanid $t($idx!lvlan!lastid)
	set liface [parse-list $line yes $t($idx!modules)]
	foreach iface $liface {
	    set kw "vlan"
	    if {[info exists t($idx!if!$iface!link!type)]} then {
		if {[string equal $t($idx!if!$iface!link!type) "trunk"]} then {
		    # le vlan est natif sur cette interface
		    set kw "nativevlan"
		}
	    }

	    set error [hp-set-ifattr t $idx!if!$iface "type" "ether"]
	    if {$error} then {
		break
	    }
	    set error [hp-set-ifattr t $idx!if!$iface $kw $vlanid]
	    if {$error} then {
		break
	    }
	    hp-ajouter-iface t $idx $iface
	}
    }

    return $error
}

proc hp-parse-tagged {active line tab idx} {
    upvar $tab t

    set error 0

    if {$active} then {
	set vlanid $t($idx!lvlan!lastid)
	set liface [parse-list $line yes $t($idx!modules)]
	foreach iface $liface {
	    set error [hp-set-ifattr t $idx!if!$iface "type" "trunk"]
	    if {$error} then {
		break
	    }
	    set error [hp-set-ifattr t $idx!if!$iface "vlan" $vlanid]
	    if {$error} then {
		break
	    }
	    hp-ajouter-iface t $idx $iface
	}
    }

    return $error
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
#   2008/07/21 : pda/jean : conception à partir de la version cisco
#

proc hp-set-ifattr {tab idx attr val} {
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
		switch -- "$t($idx!link!type)-$val" {
		    trunk-trunk {
			# rien
		    }
		    ether-trunk {
			set t($idx!link!type) "trunk"
			if {[info exists t($idx!link!vlans)]} then {
			    set ov [lindex $t($idx!link!vlans) 0]
			    set t($idx!link!allowedvlans) [list [list $ov $ov]]
			    set t($idx!link!native) $ov
			    unset t($idx!link!vlans)
			} else {
			    set t($idx!link!allowedvlans) {}
			}
		    }
		    trunk-ether {
			# le type trunk ne change pas, on ajoutera
			# juste un vlan-natif
		    }
		    ether-ether {
			warning "incoherent 'untagged' vlan for $idx"
		    }
		    default {
			warning "incoherent type for $idx"
		    }
		}
	    } else {
		set t($idx!link!type) $val
		set error 0
	    }
	}
	parentif {
	    set t($idx!link!parentif) $val
	}
	vlan {
	    if {[info exists t($idx!link!type)]} then {
		switch $t($idx!link!type) {
		    trunk {
			lappend t($idx!link!allowedvlans) [list $val $val]
		    }
		    ether {
			set t($idx!link!vlans) [list $val]
		    }
		    default {
			warning "incoherent type for $idx"
		    }
		}
	    } else {
		warning "Unknown transport-type for $idx"
	    }
	    set error 0
	}
	nativevlan {
	    if {[info exists t($idx!link!type)]} then {
		switch $t($idx!link!type) {
		    trunk {
			lappend t($idx!link!allowedvlans) [list $val $val]
			set t($idx!link!native) $val
		    }
		    default {
			warning "incoherent type for $idx"
		    }
		}
	    } else {
		warning "Unknown transport-type for $idx"
	    }
	    set error 0
	}
	default {
	    warning "Incorrect attribute type for $idx (internal error)"
	    set error 1
	}
    }
    return $error
}

###############################################################################
# Post-traitement (ou plus exactement, phase préalable au post-traitement)
###############################################################################

#
# Traite le tableau avant d'appeler la génération
#
# Entrée :
#   - eq : nom de l'équipement
#   - tab : nom du tableau
#
# Sortie :
# - suppression des interfaces désactivées
#
# Historique
#   2008/07/24 : pda      : conception
#

proc hp-prepost-process {eq tab} {
    upvar $tab t

    set error 0
    set idx "eq!$eq"

    #
    # Supprimer les interfaces marquées comme "disable"
    #

    foreach iface $t($idx!if!disabled) {
	set error [cisco-remove-if t($idx!if) $iface]
    }

    #
    # Sur les HP, on ne peut pas mettre de description sur
    # les interfaces Trk. Donc, on ne peut y mettre de point
    # de métrologie.
    # Pour y remédier, mettre le point de métrologie que l'on
    # voit sur toutes les interfaces qui participent au Trk,
    # ou râler si ce point de métrologie n'est pas le même partout.
    #

    foreach iface $t(eq!$eq!if) {
	if {[info exists t(eq!$eq!if!$iface!link!parentif)]
		&& [info exists t(eq!$eq!if!$iface!link!stat)]} then {
	    set parentif $t(eq!$eq!if!$iface!link!parentif)
	    lappend tag($parentif) $t(eq!$eq!if!$iface!link!stat)
	}
    }

    foreach parentif [array names tag] {
	set sold ""
	set ok 0
	foreach snew $tag($parentif) {
	    set s1 [string equal $sold ""]
	    set s2 [string equal $snew ""]
	    switch -- "$s1/$s2" {
		1/1 {
		    # les deux sont vides : on ne fait rien
		}
		1/0 {
		    # le nouveau point de métro est le premier valide :
		    # on initialise le point de métro de l'interface
		    set sold $snew
		    set ok 1
		}
		0/1 {
		    # le nouveau point de métro est vide (et l'ancien
		    # ne l'est pas) : on ne modifie donc rien.
		}
		0/0 {
		    # le point de métro déjà vu est valide, de même
		    # que le nouveau rencontré : il faut tester s'ils
		    # sont identiques.
		    if {! [string equal $sold $snew]} then {
			warning "Inconsistent stat names for subinterfaces of $eq/$parentif ($sold != $snew)"
			set ok 0
			break
		    }
		}
	    }
	}
	if {$ok} then {
	    set t(eq!$eq!if!$parentif!link!stat) $sold
	}
    }

    return $error
}
