#
#
# Modèle "texte"
#
# Historique
#   2008/02/26 : pda          : conception d'un modèle exemple
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
		set r [helem H2 "<br>$texte"]
	    } else {
		set logo [helem TD \
			    [helem IMG \
				"" \
				SRC /css/images/logo.png ALT "logo" \
				] \
			    ALIGN center VALIGN top \
			    ID image-a-imprimer-seulement \
			]
		set titre [helem TD [helem H2 $texte] ALIGN center VALIGN middle]
		set r [helem TABLE \
			    [helem TR "$logo$titre"] \
			    CELLPADDING 0 CELLSPACING 0 BORDER 0 WIDTH 100% \
			]
	    }

	}
	default	{
	    incr niveau
	    set r [helem H$niveau $texte]
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
	    regsub -all "\n" $texte "<br>\n" texte
	}
	default {
	    regsub -all "\n\n+" $texte "<p>" texte
	}
    }

    set partie($id) $texte
    return {}
}
