#
# $Id: html.tcl,v 1.5 2008-02-18 16:25:37 pda Exp $
#
# Modèle "texte"
#
# Historique
#   1998/06/15 : pda : conception
#   1999/06/20 : pda : séparation du langage HTML
#   1999/07/02 : pda : simplification
#   1999/07/25 : pda : intégration des tableaux de droopy
#

#
# Inclure les directives de formattage de base
#

inclure-tcl include/html/base.tcl

###############################################################################
# Procédures de conversion HTML spécifiques au modèle
###############################################################################


proc htg_titre {} {
    if [catch {set niveau [htg getnext]} v] then {error $v}
    check-int $niveau
    if [catch {set texte  [htg getnext]} v] then {error $v}
    switch $niveau {
	1	{
	    if {[dans-contexte "rarest"]} then {
		set r [helem H2 "<BR>$texte"]
	    } else {
		set r1 [helem TD \
			    [helem IMG \
				"" \
				SRC /images/logo_osiris_print.jpeg ALT "" \
				] \
			    ALIGN center VALIGN top CLASS print_image \
			    ]
		set r2 [helem TD [helem H2 $texte] ALIGN center VALIGN middle]
		set r [helem TABLE \
			    [helem TR "$r1$r2"] \
			    CELLPADDING 0 CELLSPACING 0 BORDER 0 WIDTH 100% \
			    ]
	    }

	}
	default	{
	    incr niveau
	    set r "<H$niveau>$texte</H$niveau>"
	}
    }
    return $r
}

proc htg_partie {} {
    global partie

    if [catch {set id [htg getnext]} v] then {error $v}
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
