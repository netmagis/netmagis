#
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

    if [catch {set id [htg getnext]} v] then {error $v}
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
