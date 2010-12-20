#
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

# nb maximum de colonnes dans une ligne de l'accueil
set maxcol 1
# largeur (fixe) d'une colonne (en fonction du nb max)
set largeur 1
set currentcol 0

###############################################################################
# Procédures de conversion HTML spécifiques au modèle
###############################################################################

# XXX : pourquoi cette procédure est-elle ici et pas en commun ?
# (la CLASS ne justifie pas tout)

proc htg_nouveautes {} {
    global partie

    if [catch {set titre [htg getnext]} v] then {error $v}
    set r [helem DIV [helem B $titre] CLASS "alerte"]
    return $r
}

proc htg_maxaccueil {} {
    global maxcol largeur

    if [catch {set maxcol [htg getnext]} v] then {error $v}
    check-int $maxcol
    set largeur [expr int((100-($maxcol-1))/$maxcol)]
    return ""
}

proc htg_ligneaccueil {} {
    global partie
    global largeur maxcol currentcol

    if [catch {set nbcol [htg getnext]} v] then {error $v}
    check-int $nbcol
    if [catch {set texte [htg getnext]} v] then {error $v}

    #
    # Détermination des largeurs des colonnes
    # 1- on cacule :
    #	largeur = (100 - (maxcol - 1)) / maxcol
    #
    # 2- suivant nbcol par rapport à maxcol
    #	- si nbcol > maxcol
    #        erreur
    #	- si nbcol == maxcol
    #	     les nbcol colonnes sont de largeurs :
    #		largeur% 1% largeur% 1% ... largeur%
    #	- si nbcol < maxcol
    #	     on calcule une largeur L = (100 - nbcol * largeur - (nbcol-1))/2
    #         

    set L [expr int((100 - ($nbcol * $largeur) - ($maxcol-1))/2)]
    set bourrage ""
    set currentcol 0

    set colgroup ""
    if {$nbcol > $maxcol} then {
	error "Nb de colonnes incorrect ($nbcol > $maxcol)"
    }

    if {$nbcol < $maxcol} then {
	append colgroup [helem COLGROUP "" WIDTH "$L%"]
	# On est obligé de mettre une largeur sous cette forme à cause de Safari.
	set bourrage [helem TD " " STYLE "width: $L%"]
    }

    for {set i 0} {$i < $nbcol} {incr i} {
	if {$i > 0} then {
	    append colgroup [helem COLGROUP "" WIDTH "1%"]
	}
	append colgroup [helem COLGROUP "" WIDTH "$largeur%"]
    }

    if {$nbcol < $maxcol} then {
	append colgroup [helem COLGROUP "" WIDTH "$L%"]
    }

    set tr [helem TR "$bourrage$texte$bourrage"]

    set r [helem TABLE "$colgroup$tr" \
		CLASS accueil \
		WIDTH 100% CELLPADDING 0 CELLSPACING 0]

    return $r
}

proc htg_colonneaccueil {} {
    global currentcol

    if [catch {set texte [htg getnext]} v] then {error $v}

    # le séparateur vertical
    set sep ""
    if {$currentcol > 0} {
    	set sep [helem TD [helem DIV ""] CLASS "separation-verticale"]
    } 
    incr currentcol

    set td [helem TD $texte]

    return "$sep$td"
}

proc htg_element {} {
    if [catch {set titre    [htg getnext]} v] then {error $v}
    if [catch {set image    [htg getnext]} v] then {error $v}
    if [catch {set texte    [htg getnext]} v] then {error $v}

    # l'image
    set img ""
    if {! [string equal $image ""]} then {
        append img [helem P ""] 
        append img [helem IMG "" SRC $image CLASS icone ALT ""]
    }

    # les éléments
    set els [helem UL $texte]

    # le titre + l'image + les éléments
    set r [helem UL [helem LI "$titre$img$els"]]

    return $r
}

proc htg_item {} {
    if [catch {set texte [htg getnext]} v] then {error $v}

    set r [helem LI $texte]
    return "$r"
}


proc htg_separation {} {

    set r [helem DIV "" CLASS separation-milieu] 

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
