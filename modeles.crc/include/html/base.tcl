#
# Modèle HTG de base pour la génération de pages HTML
# Doit être inclus en premier par le modèle
# Peut être complété par des procédures issues du modèle spécifique
#
# Historique
#   1999/06/20 : pda : séparation pour permettre d'autres langages
#   1999/07/02 : pda : simplification
#   1999/07/26 : pda : ajout de lt et gt
#   1999/09/12 : pda : gestion minimale d'erreur
#   2001/10/19 : pda : ajout des "meta"
#

proc check-int {v} {
    if {! [regexp {^[0-9]+$} $v]} then {
	error "$v is not a number"
    }
}

###############################################################################
# Mise en forme du texte
###############################################################################

proc htg_gras {} {
    if [catch {set arg [htg getnext]} v] then {error $v}
    return "<STRONG>$arg</STRONG>"
}

proc htg_teletype {} {
    if [catch {set arg [htg getnext]} v] then {error $v}
    return "<TT>$arg</TT>"
}

proc htg_italique {} {
    if [catch {set arg [htg getnext]} v] then {error $v}
    return "<I>$arg</I>"
}

proc htg_souligne {} {
    if [catch {set arg [htg getnext]} v] then {error $v}
    return "<U>$arg</U>"
}

proc htg_retrait {} {
    if [catch {set arg [htg getnext]} v] then {error $v}
    return "<BLOCKQUOTE>$arg</BLOCKQUOTE>"
}

proc htg_image {} {
    if [catch {set source [htg getnext]} v] then {error $v}
    if [catch {set texte  [htg getnext]} v] then {error $v}
    return "<IMG SRC=\"$source\" ALT=\"$texte\">"
}

proc htg_liste {} {
    if [catch {set arg [htg getnext]} v] then {error $v}
    return "<UL>$arg</UL>"
}

proc htg_enumeration {} {
    if [catch {set arg [htg getnext]} v] then {error $v}
    return "<OL>$arg</OL>"
}

proc htg_item {} {
    if [catch {set arg [htg getnext]} v] then {error $v}
    return "<LI>$arg</LI>"
}

proc htg_titre {} {
    if [catch {set niveau [htg getnext]} v] then {error $v}
    if [catch {set texte  [htg getnext]} v] then {error $v}
    check-int $niveau
    return "<H$niveau>$texte</H$niveau>"
}

proc htg_verbatim {} {
    if [catch {set texte  [htg getnext]} v] then {error $v}
    return "<PRE>$texte</PRE>"
}

###############################################################################
# Caractères spéciaux
###############################################################################

proc htg_lt {} {
    return {&lt;}
}

proc htg_gt {} {
    return {&gt;}
}

proc htg_br {} {
    return "<BR>"
}

###############################################################################
# URLs et liens
###############################################################################

proc htg_lien {} {
    if [catch {set texte [htg getnext]} v] then {error $v}
    if [catch {set url   [htg getnext]} v] then {error $v}
    return "<A HREF=\"$url\">$texte</A>"
}

proc htg_ancre {} {
    if [catch {set nom   [htg getnext]} v] then {error $v}
    if [catch {set texte [htg getnext]} v] then {error $v}
    return "<A NAME=\"$nom\">$texte</A>"
}

###############################################################################
# Tableaux
###############################################################################

# <TABLE
#	ALIGN=CENTER/LEFT/RIGHT			=> le tableau dans la page
#	BGCOLOR=couleur
#	BORDER=n
#	BORDERCOLOR=?
#	WIDTH=n%
#	
# <TR
#	ALIGN=CENTER/LEFT/RIGHT			=> le texte dans les cellules
#	BGCOLOR=
#	VALIGN=BASELINE/BOTTOM/CENTER/TOP	=> le texte dans les cellules
#
# <TD
#	ALIGN=CENTER/LEFT/RIGHT			=> le texte dans la cellule
#	BGCOLOR=
#	COLSPAN=n
#	ROWSPAN=n
#	VALIGN=BASELINE/BOTTOM/CENTER/TOP
#	WIDTH=n%

proc htg_tableau {} {
    if [catch {set attributs [htg getnext]} v] then {error $v}
    if [catch {set defaut    [htg getnext]} v] then {error $v}
    if [catch {set contenu   [htg getnext]} v] then {error $v}

    #
    # Rendre facilement accessible les attributs de la colonne numéro i
    #

    set numcol 0
    foreach a $defaut {
	set attrcol($numcol) $a
	incr numcol
    }

    #
    # Parcourir les lignes et les cases, et les mettre en forme
    #

    set resultat ""
    foreach ligne $contenu {
	append resultat "<TR>"
	set numcol 0
	foreach case $ligne {
	    set nbcol    [lindex $case 0]
	    set attrcase [lindex $case 1]
	    set texte    [lindex $case 2]

	    if {[string compare $attrcase ""] == 0} then {
		set attrcase [fusion-attributs $attrcol($numcol) $attrcase]
	    }

	    set colspan ""
	    if {$nbcol > 1} then { set colspan "COLSPAN=$nbcol " }
	    append resultat "<TD $colspan$attrcase>$texte</TD>"

	    incr numcol $nbcol
	}
	append resultat "</TR>"
    }

    return "<TABLE $attributs>$resultat</TABLE>"
}

proc fusion-attributs {a1 a2} {
    foreach a $a1 {
	set cv [split $a =]
	set c [lindex $cv 0]
	set v [lindex $cv 1]
	set tab($c) $v
    }

    foreach a $a2 {
	set cv [split $a =]
	set c [lindex $cv 0]
	set v [lindex $cv 1]
	set tab($c) $v
    }

    set r ""
    foreach a [array names tab] {
	append r "$a=$tab($a) "
    }
    return $r
}

#
# Attributs des colonnes du tableau
# Ceux-ci sont définis par \casedefauttableau {}, puis sont
# renvoyés à \tableau qui les propage ensuite vers les différentes cases.
# Chaque colonne possède plusieurs attributs (séparés par des espaces)
# Les différentes colonnes sont séparées par des ";"
#

proc htg_casedefauttableau {} {
    if [catch {set attributs [htg getnext]} v] then {error $v}
    return [list [list $attributs]]
}

proc htg_bordure {} {
    if [catch {set largeur [htg getnext]} v] then {error $v}
    check-int $largeur
    if [catch {set couleur [htg getnext]} v] then {error $v}

    set bordercolor [test-couleur $couleur]
    if {[string compare $bordercolor ""] != 0 } {
	set bordercolor "BORDERCOLOR=$bordercolor "
    }
    return "BORDER=$largeur $bordercolor"
}

# BASELINE/BOTTOM/CENTER/TOP
proc htg_centragevertical {} {
    if [catch {set centrage [htg getnext]} v] then {error $v}
    return "VALIGN=$centrage "
}

# CENTER/LEFT/RIGHT
proc htg_centragehorizontal {} {
    if [catch {set centrage [htg getnext]} v] then {error $v}
    return "ALIGN=$centrage "
}

proc htg_taille {} {
    if [catch {set taille [htg getnext]} v] then {error $v}
    return "WIDTH=$taille% "
}

proc htg_couleurfond {} {
    if [catch {set couleur [htg getnext]} v] then {error $v}
    set couleur [test-couleur $couleur]
    return "BGCOLOR=$couleur "
}

array set tabcouleurs {
    jaune	#FFFFCC
    vertpale	#BDFFBD
    vertfonce	#006600
    gris	#CCCCCC
    rouge	#FF0000
    bleu	#0000FF
}

proc test-couleur {couleur} {
    global tabcouleurs

    set couleur [string tolower $couleur]
    if {[info exists tabcouleurs($couleur)]} then {
	set couleur $tabcouleurs($couleur)
    }
    return $couleur
}


#
# Le contenu du tableau (les lignes et les cases) proprement dit
# Une ligne est récupérée sous la forme d'une liste :	{case case ...}
# où chaque case est une liste :	{nbcols attributs texte}
#

proc htg_lignetableau {} {
     if [catch {set texte [htg getnext]} v] then {error $v}
     return [list $texte]
}

proc htg_casetableau {} {
    if [catch {set attributs [htg getnext]} v] then {error $v}
    if [catch {set texte     [htg getnext]} v] then {error $v}
    return [list [list 1 $attributs $texte]]
}

proc htg_multicasetableau {} {
    if [catch {set nbcol     [htg getnext]} v] then {error $v}
    check-int $nbcol
    if [catch {set attributs [htg getnext]} v] then {error $v}
    if [catch {set texte     [htg getnext]} v] then {error $v}

    return [list [list $nbcol $attributs $texte]]
}

##############################################################################
# Gestion des tags "meta"
##############################################################################

# valeur par défaut de "meta"
set partie(meta) ""

proc htg_metarefresh {} {
    global partie

    if [catch {set temps [htg getnext]} v] then {error $v}
    append partie(meta) "<META HTTP-EQUIV=\"refresh\" CONTENT=\"$temps\">\n"
    append partie(meta) "<META HTTP-EQUIV=\"pragma\" CONTENT=\"no-cache\">\n"
    return ""
}

##############################################################################
# Mémorisation des parties
##############################################################################

proc htg_set {} {
    global partie

    if [catch {set variable [htg getnext]} v] then {error $v}
    if [catch {set partie($variable) [htg getnext]} v] then {error $v}
    return {}
}

proc htg_partie {} {
    global partie

    if [catch {set id [htg getnext]} v] then {error $v}
    if [catch {set texte [htg getnext]} v] then {error $v}
    set texte [nettoyer-html $texte]
    regsub -all "\n\n+" $texte "<P>" texte
    set partie(id) $texte
    return {}
}

proc htg_recuperer {} {
    global partie

    if [catch {set id [htg getnext]} v] then {error $v}
    if {! [info exists partie($id)]} then {error "missing part '$id'"}
    return $partie($id)
}

##############################################################################
# Mise en forme HTML
##############################################################################

proc nettoyer-html {texte} {
    # retirer les sauts de ligne en début et en fin de partie
    regsub -all "\[ \t\n\]*$" $texte "" texte
    regsub -all "^\[ \t\n\]*" $texte "" texte

    # convertir les ~ en espaces insécables et les ~~ en ~
    regsub -all {~} $texte {\&nbsp;} texte
    regsub -all {\&nbsp;\&nbsp;} $texte {~} texte

    # convertir les guillemets français
    regsub -all {<<} $texte {«} texte
    regsub -all {>>} $texte {»} texte

    return $texte
}
