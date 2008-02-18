#
# $Id: html.tcl,v 1.6 2008-02-18 16:25:34 pda Exp $
#
# Modèle "page d'accueil"
#
# Historique
#   1998/06/15 : pda          : conception
#   1999/07/04 : pda          : réécriture
#   2008/02/11 : pda/moindrot : simplification
#

#
# Inclure les directives de formattage de base
#

inclure-tcl include/html/base.tcl


###############################################################################
# Procédures de conversion HTML spécifiques au modèle
###############################################################################

# XXX : pourquoi cette procédure est-elle ici et pas en commun ?
# (la CLASS ne justifie pas tout)

proc htg_image {} {
    if [catch {set source [htg getnext]} v] then {error $v}
    if [catch {set texte  [htg getnext]} v] then {error $v}
    set r [helem SPAN \
		[helem IMG "" SRC $source ALT $texte] \
		CLASS accueil_image]
    return $r
}

# \nouveautes {message}

proc htg_nouveautes {} {
    global partie

    if [catch {set titre [htg getnext]} v] then {error $v}
    set r [helem DIV [helem B $titre] CLASS "cadre_orange"]
    return $r
}

proc htg_tableau {} {
    global partie

    if [catch {set nbcol [htg getnext]} v] then {error $v}
    check-int $nbcol
    if [catch {set texte [htg getnext]} v] then {error $v}

    set partie(currentcol) 0
    set taillcol [expr 100 / $nbcol]

    set colgroup [helem COLGROUP "" WIDTH "$taillcol%" SPAN $nbcol]
    set tr       [helem TR $texte]

    set r [helem TABLE "$colgroup$tr" WIDTH 100% CELLPADDING 0 CELLSPACING 0]

    return $r
}

proc htg_colonne {} {
    global partie
    if [catch {set texte [htg getnext]} v] then {error $v}
    
    if {$partie(currentcol) == 0} {
	set r [helem TD $texte ALIGN center VALIGN top]
    } else {
	set r [helem TD $texte ALIGN center VALIGN top CLASS separator]
    }
    incr partie(currentcol)

    return $r
}

proc htg_element {} {
    if [catch {set nblignes [htg getnext]} v] then {error $v}
    check-int $nblignes
    if [catch {set titre    [htg getnext]} v] then {error $v}
    if [catch {set texte    [htg getnext]} v] then {error $v}

    # sauts de lignes
    set r ""

    # le titre
    append r [helem SPAN $titre CLASS accueil_titre]

    # le texte de l'élément
    append r [helem P $texte CLASS accueil]

    return $r
}
proc htg_item {} {
    if [catch {set texte [htg getnext]} v] then {error $v}

    set r [helem SPAN $texte CLASS accueil_item]
    return "$r\n<BR>"
}

proc htg_itemimage {} {
    if [catch {set texte [htg getnext]} v] then {error $v}

    return "$texte\n<BR>"
}

proc htg_fakecolonne {} {
    if [catch {set taillecol [htg getnext]} v] then {error $v}

    set r [helem TD " " CLASS fakecolonne ALIGN center VALIGN top]
    return $r
}


proc htg_greytab {} {
    set r [helem TABLE \
		[helem TR [helem TD " " ALIGN center VALIGN middle]] \
		CLASS tab_middle \
		BORDER 0 CELLPADDING 5 CELLSPACING 0 WIDTH 100% \
	    ]
    return $r
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
