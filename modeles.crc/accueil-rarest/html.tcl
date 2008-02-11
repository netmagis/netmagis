#
# $Id: html.tcl,v 1.4 2008-02-11 14:45:30 pda Exp $
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

set script_info {
    var mois = new Array(13);
    var time = new Date();
    var year = time.getYear();
    var heures = time.getHours(); 
    var minutes = time.getMinutes();
    mois[1]="janvier";
    mois[2]="février";
    mois[3]="mars";
    mois[4]="avril";
    mois[5]="mai";
    mois[6]="juin";
    mois[7]="juillet";
    mois[8]="août";
    mois[9]="septembre";
    mois[10]="octobre";
    mois[11]="novembre";
    mois[12]="décembre";
    var month = mois[time.getMonth() + 1];
    if (year < 2000) year = 1900 + year;
    if (heures < 10) heures = "0" + heures ;
    if (minutes < 10) minutes = "0" + minutes ; 
    document.write ("<DIV CLASS=\"cadre_orange\"><B>Bonjour, nous sommes le "
		+ time.getDate() + " " + month + " " + year + " ");
    document.write (", il est " + heures  + ":" + minutes + ".<BR>");
    document.write ("%s</B></DIV>");
}

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
    global script_info

    if [catch {set titre [htg getnext]} v] then {error $v}

    set script [format $script_info $titre]

    return "<script language=\"javascript\">\n<!--$script//-->\n</script>"
}

proc htg_tableau {} {
    global partie
    if [catch {set nbcol [htg getnext]} v] then {error $v}
    check-int $nbcol
    if [catch {set texte [htg getnext]} v] then {error $v}

    set partie(currentcol) 0
    set taillcol 100
    set taillcol [ expr $taillcol / $nbcol ]
#    return "<TABLE COLS=$nbcol WIDTH=\"100%\" cellpadding=\"0\" cellspacing=\"0\"><TR>$texte</TR></TABLE>"
    return "<TABLE WIDTH=\"100%\" cellpadding=\"0\" cellspacing=\"0\"><COLGROUP WIDTH=\"$taillcol%\" SPAN=\"$nbcol\"></COLGROUP><TR>$texte</TR></TABLE>"
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

    return "<span class=\"accueil_item\">$texte</span>\n<BR>"
}

proc htg_itemimage {} {
    if [catch {set texte [htg getnext]} v] then {error $v}

    return "$texte\n<BR>"
}

proc htg_fakecolonne {} {

    if [catch {set taillecol [htg getnext]} v] then {error $v}
#    return "<td width=\"$taillecol%\" align=\"center\" valign=\"top\"> </td>"
    return "<td CLASS=\"fakecolonne\" align=\"center\" valign=\"top\"> </td>"

}


proc htg_greytab {} {

    return "<table class=\"tab_middle\" border=\"0\" cellpadding=\"5\" cellspacing=\"0\" width=\"100%\">\n<tr>\n<td align=\"center\" valign=\"middle\"></td>\n</tr></table>"

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
