#
# $Id: html.tcl,v 1.2 2008-02-11 14:45:30 pda Exp $
#
# Modèle "news"
#
# Historique
#   2007/03/14 : pda/moindrot : conception
#   2007/03/21 : pda/moindrot : génération d'un fichier intermédiaire
#   2007/04/05 : pda/moindrot : Vérification de l'unicité du couple date/auteur
#                               pour la génération de la balise guid du RSS
#

#
# Inclure les directives de formattage de base
#

inclure-tcl include/html/base.tcl

#
# Fichier intermédiaire servant à stocker les news pour la génération
#	- du fichier index.html global
#	- du fichier rss.xml
#

set fichiernews "/tmp/news.txt"

#
# Tableau global servant à détecter des doublons de news à l'intérieur
# d'un fichier htgt
#

array set tnews {}

###############################################################################
# Procédures de conversion HTML spécifiques au modèle
###############################################################################

proc htg_titre {} {
    if [catch {set niveau [htg getnext]} v] then {error $v}
    check-int $niveau
    if [catch {set texte  [htg getnext]} v] then {error $v}
    switch $niveau {
	1	{
            set texte  "<table cellpadding=0 cellspacing=0 border=0 width=\"100%\"><tr><td align=\"center\" valign=\"top\" class=\"print_image\"><img src=\"/images/logo_osiris_print.jpeg\" alt=\"\"></td><td align=\"center\" valign=\"middle\"><H2>$texte</H2></td></tr></table>"
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
    global fichiernews
    global tnews

    if [catch {set date [htg getnext]} v] then {error $v}
    if [catch {set titre [htg getnext]} v] then {error $v}
    if [catch {set theme [htg getnext]} v] then {error $v}
    if [catch {set contenu [htg getnext]} v] then {error $v}
    if [catch {set lien [htg getnext]} v] then {error $v}
    if [catch {set auteur [htg getnext]} v] then {error $v}

    regsub -all "\n\n" $contenu "<BR /><BR />" contenu

    #
    # Vérifier le format de la date et de l'heure
    #

    if {! [regexp {^[0-9]{2}/[0-9]{2}/[0-9]{4}\s+[0-9]{2}:[0-9]{2}$} $date]} then {
	error "date et heure '$date' invalides (jj/mm/aaaa hh:mm)"
    }

    #
    # Vérifier que toutes les News on une date/heure/Auteur unique
    #

    if {[info exists tnews($date$auteur)]} {
       error "Une news ayant une date '$date' et un auteur '$auteur' identique a été trouvée"
    }
    set tnews($date$auteur) ""

    #
    # Recopier la nouvelle dans le fichier news.txt
    #

    set fd [open $fichiernews "a"]
    puts $fd [list $date $titre $theme $contenu $lien $auteur]
    close $fd

    #
    # Générer le code HTML
    #
    regsub -all " " $date "/" date_ancre

    set html ""
    append html "<div class=\"news\">\n"
    append html "<a name=\"$date_ancre/$auteur\">"
    append html   "<h3>\n"
    append html     "<span class=\"news-date\">\[$date\]</span>\n"
    append html     "<span class=\"news-titre\">$titre</span>\n"
    append html     "<span class=\"news-theme\">($theme)</span>\n"
    append html   "</h3>\n"
    append html "</a>\n"
    append html   "<p>$contenu <span class=\"news-qui\">\[$auteur\]</span></p>\n"
    if {! [string equal [string trim $lien] ""]} then {
	append html "<p>Voir aussi&nbsp;: <a href=\"$lien\">$lien</a></p>\n"
    }
    append html "</div>\n"

    return $html
}

proc htg_greytab {} {

    return "<table class=\"tab_middle\" border=\"0\" cellpadding=\"5\" cellspacing=\"0\" width=\"100%\">\n<tr>\n<td align=\"center\" valign=\"middle\"></td>\n</tr></table>"

}



###############################################################################
# Procédures du bandeau, communes à tous les modèles
###############################################################################

inclure-tcl include/html/bandeau.tcl
