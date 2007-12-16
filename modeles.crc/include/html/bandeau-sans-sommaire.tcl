# $Id: bandeau-sans-sommaire.tcl,v 1.1 2007-12-16 20:52:08 pda Exp $

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
    global numsommaire

    set sousmenu "" 
    set sommairegeneral ""
    if [catch {set titre   [htg getnext]} v] then {error $v}
    if [catch {set contenu [htg getnext]} v] then {error $v}

    set titre [nettoyer-html $titre]
    regsub -all "\n" $titre "<BR>" titre

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
