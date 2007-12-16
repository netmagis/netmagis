#
# $Id: html.tcl,v 1.1 2007-12-16 20:52:08 pda Exp $
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
            set texte  "<table cellpadding=0 cellspacing=0 border=0 width=100%><tr><td align=\"center\" valign=\"top\" class=\"print_image\"><img src=\"/images/logo_osiris_print.jpeg\"></td><td align=\"center\" valign=\"middle\"><H2>$texte</H2></td></tr></table>"
	}
	2	{
	    set texte "<H3>$texte</H3>"
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

proc htg_news {} {
    if [catch {set date [htg getnext]} v] then {error $v}
    if [catch {set titre [htg getnext]} v] then {error $v}
    if [catch {set theme [htg getnext]} v] then {error $v}
    if [catch {set contenu [htg getnext]} v] then {error $v}
    if [catch {set lien [htg getnext]} v] then {error $v}
    if [catch {set auteur [htg getnext]} v] then {error $v}

    set html ""
    append html "<div class=\"news\">\n"
    append html   "<h3>\n"
    append html     "<span class=\"news-date\">\[$date\]</span>\n"
    append html     "<span class=\"news-titre\">$titre</span>\n"
    append html     "<span class=\"news-theme\">($theme)</span>\n"
    append html   "</h3>\n"
    append html   "<p>$contenu <span class=\"news-qui\">\[$auteur\]</span></p>\n"
    if {! [string equal [string trim $lien] ""]} then {
	append html "<p>Voir aussi&nbsp;: <a href=\"$lien\">$lien</a></p>\n"
    }
    append html "</div>\n"

    return $html
}

###############################################################################
# Procédures du bandeau, communes à tous les modèles
###############################################################################

inclure-tcl include/html/bandeau.tcl
