#
# $Id: html.tcl,v 1.2 2007-03-13 21:08:00 pda Exp $
#
# Modèle "page de présentation d'une personne"
#
# Historique
#   1998/06/15 : pda : conception
#   1999/07/04 : pda : réécriture
#

#
# Inclure les directives de formattage de base
#

inclure-tcl include/html/base.tcl

###############################################################################
# Procédures de conversion HTML spécifiques au modèle
###############################################################################

proc htg_personne {} {
    global partie

    if [catch {set nom [htg getnext]} v] then {error $v}
    if [catch {set gif [htg getnext]} v] then {error $v}
    if [catch {set tel [htg getnext]} v] then {error $v}
    if [catch {set fax [htg getnext]} v] then {error $v}
    if [catch {set email [htg getnext]} v] then {error $v}

    set partie(nom) $nom
    set partie(gif) $gif
    set partie(tel) $tel
    set partie(fax) $fax
    set partie(email) $email

    return {}
}

proc htg_titre {} {
    if [catch {set niveau [htg getnext]} v] then {error $v}
    check-int $niveau
    if [catch {set texte  [htg getnext]} v] then {error $v}

    switch $niveau {
	1	{
	    set texte "<CENTER><FONT COLOR=\"#286B7A\"><H2><BR>$texte</H2></FONT></CENTER>"
	}
	2	{
	    set texte "<FONT COLOR=\"#FF3D3D\"><H3>$texte</H3></FONT>"
	}
	default	{
	    incr niveau
	    set texte "<H$niveau>$texte</H$niveau>"
	}
    }

    return $texte
}

proc htg_partie {} {
    global partie

    if [catch {set id    [htg getnext]} v] then {error $v}
    if [catch {set texte [htg getnext]} v] then {error $v}

    set texte [nettoyer-html $texte]

    switch -exact $id {
	banniere	-
	titrepage	{
	    regsub -all "\n" $texte "<BR>\n" texte
	}
	default {
	    regsub -all "\n\n+" $texte "<P>" texte
	}
    }

    set partie($id) $texte

    return {}
}

###############################################################################
# Procédures du bandeau, communes à tous les modèles
###############################################################################

inclure-tcl include/html/bandeau.tcl
