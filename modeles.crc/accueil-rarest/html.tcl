#
# $Id: html.tcl,v 1.3 2007-12-16 20:33:45 pda Exp $
#
# Modèle "page d'accueil"
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

proc htg_image {} {
    if [catch {set source [htg getnext]} v] then {error $v}
    if [catch {set texte  [htg getnext]} v] then {error $v}
    return "<span class=\"accueil_image\"><img src=\"$source\" ALT=\"$texte\"></span>"
}
proc htg_nouveautes {} {
    global partie
    if [catch {set titre [htg getnext]} v] then {error $v}

    return "<script language=\"javascript\">\n <!-- \n var mois=new Array(13);\n mois\[1\]=\"janvier\";\n mois\[2\]=\"février\";\n mois\[3\]=\"mars\";\n mois\[4\]=\"avril\";\n mois\[5\]=\"mai\";\n mois\[6\]=\"juin\";\n mois\[7\]=\"juillet\";\n mois\[8\]=\"août\";\n mois\[9\]=\"septembre\";\n mois\[10\]=\"octobre\";\n mois\[11\]=\"novembre\";\n mois\[12\]=\"décembre\";\n var time=new Date();\n var month=mois\[time.getMonth() + 1\];\n var year= 1900 + time.getYear();\n var minutes = time.getMinutes();\n if (minutes < 10) minutes = \"0\"+minutes ; \n document.write(\"<div class=cadre_orange><b>Bonjour, nous sommes le \"+time.getDate() +\" \" +month +\" \" +year + \" \");\n document.write(\", il est \"+time.getHours() +\":\" +minutes +\".<BR>$titre</b></div>\");\n //--> \n </script>"
}

proc htg_tableau {} {
    global partie
    if [catch {set nbcol [htg getnext]} v] then {error $v}
    check-int $nbcol
    if [catch {set texte [htg getnext]} v] then {error $v}

    set partie(currentcol) 0
    return "<TABLE COLS=$nbcol WIDTH=\"100%\" height=\"100%\" cellpadding=\"0\" cellspacing=\"0\"><TR>$texte</TR></TABLE>"
}

proc htg_colonne {} {

    global partie
    if [catch {set texte [htg getnext]} v] then {error $v}
    
    if { $partie(currentcol) > 0} {
    	incr partie(currentcol)
    	return "<TD class=\"separator\" ALIGN=\"center\" VALIGN=\"top\">$texte</TD>"
    } else {
    	incr partie(currentcol)
    	return "<TD ALIGN=\"center\" VALIGN=\"top\">$texte</TD>"
    }
}

proc htg_element {} {
    if [catch {set nblignes [htg getnext]} v] then {error $v}
    check-int $nblignes
    if [catch {set titre    [htg getnext]} v] then {error $v}
    if [catch {set texte    [htg getnext]} v] then {error $v}

    # sauts de lignes
    set r {}
    #for {set i 0} {$i < $nblignes} {incr i} {
    #	append r "~<BR>"
    #}

    # le titre
    append r "<span class=\"accueil_titre\">"
    append r $titre
    append r "</span>"

    # le texte de l'élément
    append r "<P class=\"accueil\">"
    append r $texte
    append r "</P>"

    return $r
}
proc htg_item {} {
    if [catch {set texte [htg getnext]} v] then {error $v}

    return "$texte\n<BR>"
}

proc htg_fakecolonne {} {

    if [catch {set taillecol [htg getnext]} v] then {error $v}
    return "<TD WIDTH=\"$taillecol%\" ALIGN=\"center\" VALIGN=\"top\"></TD>"

}


proc htg_greytab {} {

    return "<table class=\"tab_middle\" bgcolor=\"#ffffff\" border=\"0\" cellpadding=\"5\" cellspacing=\"0\" width=\"100%\">\n<tr>\n<td align=\"center\" valign=\"middle\"></td>\n</tr></table>"

}

proc htg_titre {} {
    if [catch {set niveau [htg getnext]} v] then {error $v}
    check-int $niveau
    if [catch {set texte  [htg getnext]} v] then {error $v}

    switch $niveau {
	1	{
	    set texte "<H2>$texte</H2>"
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

inclure-tcl include/html/bandeau-rarest.tcl
