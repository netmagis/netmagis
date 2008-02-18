#
# $Id: html.tcl,v 1.6 2008-02-18 16:28:35 pda Exp $
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

    if {$niveau == 1} then {
	set logo [helem TD \
			[helem IMG "" \
			    SRC /images/logo_osiris_print.jpeg \
			    ALT "logo" \
			] \
			ALIGN center VALIGN top CLASS print_image \
		    ]
	set titre [helem TD [helem H2 $texte] ALIGN center VALIGN middle]
	set r [helem TABLE \
		    [helem TR "$logo$titre"] \
		    CELLPADDING 0 CELLSPACING 0 BORDER 0 WIDTH 100% \
		]
    } else {
	incr niveau
	set r [helem H$niveau $texte]
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
    # Générer le code HTML :
    #
    #   <div class="news">
    #     <a name="$date_ancre/$auteur">
    #       <h3>
    #         <span class="news-date">[$date]</span>
    #         <span class="news-titre">$titre</span>
    #         <span class="news-theme">($theme)</span>
    #       </h3>
    #     </a>
    #     <p>$contenu <span class="news-qui">[$auteur]</span></p>
    #     <p>Voir aussi&nbsp;: <a href="$lien">$lien</a></p>
    #   </div>
    #

    regsub -all " " $date "/" date_ancre


    set r1 ""
    append r1 [helem SPAN "\[$date\]" CLASS news-date]
    append r1 [helem SPAN $titre      CLASS news-titre]
    append r1 [helem SPAN "($theme)"  CLASS news-theme]

    set r2 [helem A [helem H3 $r1] NAME "$date_ancre/$auteur"]

    set r3 $contenu
    append r3 " "
    append r3 [helem SPAN "\[$auteur\]" CLASS news-qui]

    set r4 [helem P $r3]

    if {[string equal [string trim $lien] ""]} then {
	set r6 ""
    } else {
	set r5 [helem A $lien HREF $lien]
	set r6 [helem P "Voir aussi&nbsp;: $r5"]
    }

    set r [helem DIV "$r2\n$r4\n$r6\n" CLASS news]

    return $r
}

proc htg_greytab {} {
    set r [helem TABLE \
		[helem TR \
		    [helem TD "" ALIGN center VALIGN middle] \
		] \
		CLASS tab_middle \
		BORDER 0 CELLPADDING 5 CELLSPACING 0 WIDTH 100% \
	    ]
    return $r
}
