#
# $Id: html.tcl,v 1.5 2008-02-18 17:00:01 pda Exp $
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

    incr niveau
    set r [helem H$niveau $texte]
    return $r
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
