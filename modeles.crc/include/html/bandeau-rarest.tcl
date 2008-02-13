# $Id: bandeau-rarest.tcl,v 1.3 2008-02-13 08:57:12 pda Exp $

set numsommaire 4
set sommaire(0) "<dt onclick=\"javascript:developper('%s');\">Le réseau RAREST </dt> \
   	     <dd id=\"%s\"> \
	      <ul><li><a href=\"/rarest/intro.html\">Introduction</a></li></ul> \
	      <ul><li><a href=\"/rarest/part.html\">Partenaires</a></li></ul> \
	      <ul><li><a href=\"/rarest/etabl.html\">Etablissements</a></li></ul> \
	      <ul><li><a href=\"/rarest/infra.html\">Infrastructure</a></li></ul> \
	     </dd>"
set sommaire(1) "<dt onclick=\"javascript:developper('%s');\">Le CRC</dt> \
             <dd id=\"%s\"> \
              <ul><li><a href=\"/crc/\">Introduction</a></li></ul> \
              <ul><li><a href=\"/crc/equipe/\">L'équipe</a></li></ul> \
              <ul><li><a href=\"/crc/contact.html\">Comment nous joindre</a></li></ul> \
             </dd>"
set sommaire(2) "<dt onclick=\"javascript:developper('%s');\">Accès restreint</dt> \
             <dd id=\"%s\"> \
              <ul><li><a href=\"/rarest/corresp/\">Intranet correspondants</a></li></ul> \
              <ul><li><a href=\"/rarest/bex\">Intranet du groupe d'experts</a></li></ul> \
             </dd>"
set sommaire(3) "<dt onclick=\"javascript:developper('%s');\">Au secours !</dt> \
             <dd id=\"%s\"> \
              <ul><li><a href=\"/rarest/aide-rarest.html\">Aide Rarest</a></li></ul> \
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
	set titre "<dt onclick=\"javascript:developper('$sousmenu');\">$titre</dt>"
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
	set tempsommaire [format $sommaire($i) $sousmenu $sousmenu]
    	set sommairegeneral $sommairegeneral$tempsommaire
    }
    set contenu "$contenu\n$sommairegeneral"
    
    set retour "<dt><A HREF=\"/rarest/\">ACCUEIL</A></dt>"
    set contenu "$retour\n$contenu"

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
