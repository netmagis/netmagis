# $Id: bandeau.tcl,v 1.3 2007-12-16 20:33:45 pda Exp $

set numsommaire 5
set sommaire(0) "<dt class=\"sous-menu-spacer\"></dt> \
		<dt class=\"sous-menu-orange\">Sommaire</dt> \
            <dt><A HREF=\"/\">ACCUEIL</A></dt>\
	    <dt onclick=\"javascript:montre('%s');\">Espace Utilisateurs </dt> \
   	     <dd id=\"%s\"> \
	      <ul><li><a href=\"https://webmail.u-strasbg.fr\">Webmail</a></li></ul> \
	      <ul><li><a href=\"/osiris/services/bal\">Messagerie</a></li></ul> \
	      <ul><li><a href=\"/osiris/services/wifi\">Wifi</a></li></ul> \
	      <ul><li><a href=\"/osiris/services/vpn\">Accès VPN</a></li></ul> \
	      <ul><li><a href=\"/osiris/services/\">Autres services...</a></li></ul> \
	      <ul><li><a href=\"https://www-crc.u-strasbg.fr/applis/authiris/bin/accueil\" class=\"orange_menu\">Mon compte Osiris</a></li></ul> \
	     </dd>"
set sommaire(1) "<dt onclick=\"javascript:montre('%s');\">Espace Technique</dt> \
             <dd id=\"%s\"> \
              <ul><li><a href=\"/osiris/intro-tech.html\">Introduction</a></li></ul> \
              <ul><li><a href=\"/formations\">Formations</a></li></ul> \
              <ul><li><a href=\"/securite/\">La sécurité</a></li></ul> \
              <ul><li><a href=\"/osiris/services\">Les services offerts</a></li></ul> \
              <ul><li><a href=\"/corresp/\" class=\"orange_menu\">Intranet des correspondants</a></li></ul> \
             </dd>"

set sommaire(2) "<dt onclick=\"javascript:montre('%s');\">Le téléphone à l'ULP</dt> \
             <dd id=\"%s\"> \
              <ul><li><a href=\"http://siig2.u-strasbg.fr/cgi-bin/WebObjects/Annuaire.woa\">Annuaire</a></li></ul> \
              <ul><li><a href=\"/telulp/flash_info/index.html\">Marché d'extension</a></li></ul> \
              <ul><li><a href=\"/telulp/mode_emploi/\">Mode d'emploi</a></li></ul> \
              <ul><li><a href=\"https://www-crc.u-strasbg.fr/applis/pabx/bin/index\" class=\"orange_menu\">Consultation des PABX</a></li></ul> \
             </dd>"

set sommaire(3) "<dt onclick=\"javascript:montre('%s');\">Le Réseau Osiris</dt> \
             <dd id=\"%s\"> \
              <ul><li><a href=\"/osiris\">Introduction</a></li></ul> \
              <ul><li><a href=\"/portail\">Etablissement</a></li></ul> \
              <ul><li><a href=\"/securite/charte-osiris.html\">Charte Osiris</a></li></ul> \
              <ul><li><a href=\"/osiris/technique.html\">Documentation technique</a></li></ul> \
             </dd>"

set sommaire(4) "<dt onclick=\"javascript:montre('%s');\">Le CRC</dt> \
             <dd id=\"%s\"> \
              <ul><li><a href=\"/crc/aide-osiris.html\">Aide Osiris</a></li></ul> \
              <ul><li><a href=\"/crc/equipe/\">L'équipe</a></li></ul> \
              <ul><li><a href=\"/crc/contact.html\">Comment nous joindre</a></li></ul> \
              <ul><li><a href=\"/intra\" class=\"orange_menu\">Intranet CRC</a></li></ul> \
             </dd>"


proc xxx_elementtableau {bgcoul titre texte} {
    global partie
    #
    # mettre le titre s'il y a besoin
    #
   
    set sousmenu "smenu" 
    if {[string length $titre] > 0} then {
        incr partie(soustitre)
	set sousmenu $sousmenu$partie(soustitre)
	set titre "<dt onclick=\"javascript:montre('$sousmenu');\">$titre</dt>"
    }

    #
    # Mettre le contenu s'il y a besoin
    #
    #if {[string length $texte] > 0} then {
#	set texte "<FONT SIZE=\"-1\">$texte</FONT>"
#    }

    #
    # Tout mettre en forme
    #
#    set bg ""
#    if {[string length $bgcoul] > 0} then {
#	set bg " BGCOLOR=\"$bgcoul\""
#    }
    return "$titre<dd id=\"$sousmenu\"><ul>$texte</ul></dd>"
}


proc htg_bandeau {} {
    global partie
    global sommaire
    global numsommaire

    set sousmenu "" 
    set sommairegeneral ""
    if [catch {set titre   [htg getnext]} v] then {error $v}
    if [catch {set contenu [htg getnext]} v] then {error $v}

    set titre [nettoyer-html $titre]
    regsub -all "\n" $titre "<BR>" titre

    for {set i 0} {$i < $numsommaire} {incr i 1} {
        incr partie(soustitre)
        set sousmenu "smenu$partie(soustitre)"
	set tempsommaire [ format $sommaire($i) $sousmenu $sousmenu" ]
    	set sommairegeneral $sommairegeneral$tempsommaire
    }
    set contenu "$contenu\n$sommairegeneral"
    
#    set retour "<dt><A HREF=\"/\">ACCUEIL</A></dt>"
#    set contenu "$retour\n$contenu"

    set partie(titrebandeau) $titre
    set partie(contenubandeau) $contenu

    return {}
}

proc htg_elementbandeau {} {
    if [catch {set titre [htg getnext]} v] then {error $v}
    if [catch {set refs  [htg getnext]} v] then {error $v}

    return [xxx_elementtableau {} $titre $refs]
}

proc htg_reference {} {
    if [catch {set texte [htg getnext]} v] then {error $v}
    return "<li>$texte</li>"
}
