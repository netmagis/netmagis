#
#
# Package d'analyse de fichiers de pseudo-configuration IOS
# pour les serveurs
#
# Historique
#   2011/04/05 : jean      : creation
#

###############################################################################
# Analyse du fichier de configuration
###############################################################################


#
# Entree :
#   - libdir : repertoire contenant les greffons d'analyse
#   - model : modele de l'equipement (ex: OpenBSD)
#   - fdin : descripteur de fichier en entree
#   - fdout : fichier de sortie pour la generation
#   - eq = <eqname>
# Remplit :
#   - tab(eq)	{<eqname> ... <eqname>}
#   - tab(eq!ios) "unsure|router|switch"
#
# Historique
#   2004/03/23 : pda/jean : conception
#   2004/06/08 : pda/jean : ajout de model
#   2007/07/12 : pda      : ajout de ios
#   2008/07/07 : pda/jean : ajout parametre libdir
#   2012/02/16 : jean/boggia : adaptation pour les serveurs
#

proc server-parse {libdir model fdin fdout tab eq} {
    upvar $tab t
    array set kwtab {
	-COMMENT			^!
	interface			{CALL server-parse-interface}
	parent-iface			{CALL server-parse-parent-iface}
	ip				NEXT
	ip-address			{CALL cisco-parse-ip-address}
	ipv6				NEXT
	ipv6-address			{CALL cisco-parse-ipv6-address}
	description			{CALL cisco-parse-desc}
	channel-group			{CALL cisco-parse-channel-group}
	shutdown			{CALL cisco-parse-shutdown}
	snmp-server			NEXT
	snmp-server-community		{CALL cisco-parse-snmp-community}
	snmp-server-location		{CALL cisco-parse-snmp-location}
	encapsulation			NEXT
	encapsulation-dot1Q		{CALL cisco-parse-encapsulation-dot1q}
	bridge-group			{CALL cisco-parse-bridge-group}
	router				{CALL cisco-parse-router}
	ipc				{CALL cisco-parse-ipc}
    }

    set error [charger $libdir "parse-cisco.tcl"]
    if {! $error} then {
        set error [ios-parse $libdir $model $fdin $fdout t $eq kwtab]
	if {! $error} then {
	    set error [cisco-post-process "cisco" $fdout $eq t]
	}
    }

    return $error
}


#
# Entrée :
#   - line = "vlan0"
#	ou "em1"
#	ou "eth2"
#   - idx = eq!<eqname>
# Remplit :
#   - tab(eq!<nom eq>!if) {<ifname> ... <ifname>}
#   - tab(eq!<nom eq>!current!if) <ifname>
#   - tab(eq!<nom eq>!current!physif) <physifname>
# Vide :
#   - tab(eq!<nom eq>!current!ssid)
#
# Historique
#   2004/03/26 : pda/jean : conception
#   2007/07/12 : pda      : gestion des sous-interfaces
#

proc server-parse-interface {active line tab idx} {
    upvar $tab t

    set error 0

    set ifname [lindex $line 0]

    lappend t($idx!if) $ifname

    set t($idx!current!physif) $ifname
    set t($idx!current!if) $ifname

    return $error
}

# Entree :
#   - line = "em0"
# Remplit en cas de sous-interface :
#   - tab(eq!<nom eq>!if!<physifname>!subif) { <ifname> ...} (liste des sous-i/f)
#   - tab(eq!<nom eq>!current!physif) <physifname>

proc server-parse-parent-iface {active line tab idx} {
    upvar $tab t

    set error 0
	
    set parent [lindex $line 0]

    # ecrase la valeur de physif
    set t($idx!current!physif) $parent

    set subif $t($idx!current!if)

    # supprime la sous-interface de la liste
    set pos [lsearch -exact $t($idx!if) $subif]
    set t($idx!if) [lreplace $t($idx!if) $pos $pos]

    # ajoute dans la liste des sous-interfaces pour l'interface parente
    lappend t($idx!if!$parent!subif) $subif

    if {[lsearch $t($idx!if) $parent] == -1} then {
    	lappend t($idx!if) $parent
    }

    return $error
}
