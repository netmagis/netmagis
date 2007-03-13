#
# $Id: html.tcl,v 1.2 2007-03-13 21:08:05 pda Exp $
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

proc htg_tableau {} {
    if [catch {set nbcol [htg getnext]} v] then {error $v}
    check-int $nbcol
    if [catch {set texte [htg getnext]} v] then {error $v}

    return "<TABLE COLS=$nbcol WIDTH=\"100%\"><TR>$texte</TR></TABLE>"
}

proc htg_colonne {} {
    if [catch {set texte [htg getnext]} v] then {error $v}

    return "<TD VALIGN=\"top\">$texte</TD>"
}

proc htg_element {} {
    if [catch {set nblignes [htg getnext]} v] then {error $v}
    check-int $nblignes
    if [catch {set titre    [htg getnext]} v] then {error $v}
    if [catch {set texte    [htg getnext]} v] then {error $v}

    # sauts de lignes
    set r {}
    for {set i 0} {$i < $nblignes} {incr i} {
	append r "~<BR>"
    }

    # le titre
    append r "<STRONG><FONT FACE=\"Arial,Helvetica\"><FONT COLOR=\"#009900\">"
    regsub -all {[A-Z]+} $titre {<FONT SIZE="+1">&</FONT>} titre
    append r $titre
    append r "</FONT></FONT></STRONG>"

    # le texte de l'élément
    append r $texte
    append r "\n"

    return $r
}

proc htg_item {} {
    if [catch {set texte [htg getnext]} v] then {error $v}

    return "\n<BR>. $texte"
}

proc htg_titre {} {
    if [catch {set niveau [htg getnext]} v] then {error $v}
    check-int $niveau
    if [catch {set texte  [htg getnext]} v] then {error $v}

    switch $niveau {
	1	{
	    set texte "<CENTER><FONT FACE=\"Arial,Helvetica\"><FONT COLOR=\"#006600\"><H2><BR>$texte</H2></FONT></FONT></CENTER>"
	}
	2	{
	    set texte "<FONT COLOR=\"#006600\"><H3>$texte</H3></FONT>"
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
	    if {[string compare $id titrepage] == 0} then {
		regsub -all "(\[^a-zA-Z\])(\[a-zA-Z\])(\[a-zA-Z\]\[a-zA-Z\])" $texte \
			{\1<FONT COLOR="#006600">\2</FONT>\3} texte
		regsub -all "^(\[a-zA-Z\])" $texte \
			{<FONT COLOR="#006600">\1</FONT>} texte
		set texte "<BR><H1><FONT COLOR=\"#000099\"><FONT SIZE=\"+2\">$texte</FONT></FONT></H1>"
	    }

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

inclure-tcl include/html/bandeau.tcl
