#
# $Id: latex.tcl,v 1.2 2007-03-13 21:08:01 pda Exp $
#
# Modèle "texte"
#
# Historique
#   1999/06/21 : pda : conception d'un modèle latex pour validation multimodèle
#   1999/07/02 : pda : simplification
#

#
# Inclure les directives de formattage de base
#

inclure-tcl include/latex/base.tcl

###############################################################################
# Procédures de conversion LaTeX spécifiques au modèle
###############################################################################

proc htg_partie {} {
    global partie

    if [catch {set id [htg getnext]} v] then {error $v}
    if [catch {set texte [htg getnext]} v] then {error $v}
    set texte [nettoyer-latex $texte]

    switch -exact $id {
	banniere	-
	titrepage	{ set texte {} }
    }

    set partie($id) $texte  
    return {}
}

###############################################################################
# Procédures du bandeau, communes à tous les modèles
###############################################################################

inclure-tcl include/latex/bandeau.tcl
