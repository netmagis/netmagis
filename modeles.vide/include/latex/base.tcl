#
# $Id: base.tcl,v 1.2 2007-03-13 21:08:15 pda Exp $
#
# Modèle HTG de base pour la génération de pages LaTeX
# Doit être inclus en premier par le modèle
# Peut être complété par des procédures issues du modèle spécifique
#
# Historique
#   1999/06/20 : pda : ajout du langage latex
#   1999/07/02 : pda : simplification
#   1999/07/26 : pda : ajout de lt et gt
#

###############################################################################
# Mise en forme du texte
###############################################################################

proc htg_gras {} {
    if [catch {set arg [htg getnext]} v] then {error $v}
    return "\\textbf {$arg}"
}

proc htg_teletype {} {
    if [catch {set arg [htg getnext]} v] then {error $v}
    return "\\texttt {$arg}"
}

proc htg_italique {} {
    if [catch {set arg [htg getnext]} v] then {error $v}
    return "\\textem {>$arg}"
}

proc htg_souligne {} {
    if [catch {set arg [htg getnext]} v] then {error $v}
    return "\\textem {$arg}"
}

proc htg_retrait {} {
    if [catch {set arg [htg getnext]} v] then {error $v}
    return "\\begin {quote}\n$arg\n\\end {quote}"
}

proc htg_image {} {
    if [catch {set source [htg getnext]} v] then {error $v}
    if [catch {set texte  [htg getnext]} v] then {error $v}
    return "<IMG SRC=\"$source\" ALT=\"$texte\">"
}

proc htg_liste {} {
    if [catch {set arg [htg getnext]} v] then {error $v}
    return "\\begin {itemize}\n$arg\n\\end {itemize}"
}

proc htg_enumeration {} {
    if [catch {set arg [htg getnext]} v] then {error $v}
    return "\\begin {enumerate}\n$arg\n\\end {enumerate}"
}

proc htg_item {} {
    if [catch {set arg [htg getnext]} v] then {error $v}
    return "\\item $arg\n"
}

proc htg_titre {} {
    if [catch {set niveau [htg getnext]} v] then {error $v}
    if [catch {set texte  [htg getnext]} v] then {error $v}
    switch $niveau {
	1 { set texte "\\begin {center}\n\\huge\\textbf {$texte}\n\\end {center}" }
	2 { set texte "\\section {$texte}" }
	3 { set texte "\\subsection {$texte}" }
	4 { set texte "\\subsubsection {$texte}" }
	5 { set texte "\\paragraph {$texte}" }
    }
    return $texte
}

proc htg_verbatim {} {
    if [catch {set texte  [htg getnext]} v] then {error $v}
    return "\\begin {verbatim}\n$texte\n\\end{verbatim}"
}

###############################################################################
# Caractères spéciaux
###############################################################################

proc htg_lt {} {
    return {$<$}
}

proc htg_gt {} {
    return {$>$}
}

###############################################################################
# URLs et liens
###############################################################################

proc htg_lien {} {
    if [catch {set texte [htg getnext]} v] then {error $v}
    if [catch {set url   [htg getnext]} v] then {error $v}
    return "\\textbf {$texte}\\footnote {$url}"
}

proc htg_ancre {} {
    if [catch {set nom   [htg getnext]} v] then {error $v}
    if [catch {set texte [htg getnext]} v] then {error $v}
    return "\\label {$nom} $texte"
}

##############################################################################
# Tableaux
##############################################################################

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
    # Analyser les attributs du tableau
    #

    set border 0
    set center 0
    foreach a $attributs {
	set cv [split $a =]
	set c [string tolower [lindex $cv 0]]
	set v [string tolower [lindex $cv 1]]

	switch $c {
	    border	{
		set border $v
	    }
	    align	{
		if {[string compare $v center] == 0} then {
		    set center 1
		}
	    }
	}
    }

    #
    # Déterminer les attributs des colonnes du tableau
    #

    set cols ""
    foreach col $defaut {
	set align l
	foreach a $col {
	    set cv [split $a =]
	    set c [string tolower [lindex $cv 0]]
	    set v [string tolower [lindex $cv 1]]

	    switch $c {
		align	{
		    switch $v {
			center	{ set align c }
			left	{ set align l }
			right	{ set align r }
		    }
		}
		width	{
		    # XXX ! Mettre la largeur correcte
		    set align p@${v}mm
		}
	    }
	}
	if {$border > 0} then { append cols "|" }
	append cols $align
    }
    if {$border > 0} then { append cols "|" }

    #
    # Parcourir les lignes et les cases, et les mettre en forme
    #

    set resultat ""
    foreach ligne $contenu {
	#
	# la première ligne est spéciale
	#
	if {$border > 0 && [string compare $resultat ""] == 0} then {
	    append resultat "\\hline "
	}

	set numcol 0
	foreach case $ligne {
	    set nbcol    [lindex $case 0]
	    set attrcase [lindex $case 1]
	    set texte    [lindex $case 2]

	    if {$numcol > 0} then {
		append resultat "& "
	    }

	    if {$nbcol > 1} then {
		# XXX ! intégrer les attributs de cette case
		set r "\\multicolumn {$nbcol} {|l|} {$texte}"
	    } else {
		set r $texte
	    }

	    append resultat $r

	    incr numcol
	}
	append resultat "\\\\ \n"
	if {$border > 0} then {
	    append resultat "\\hline "
	}
    }

    set resultat "\\begin {tabular} {$cols}\n$resultat\n\\end {tabular}"

    if {$center} then {
	set resultat "\\begin {center}\n$resultat\n\\end {center}"
    }

    return $resultat
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
    return [list $attributs]
}

proc htg_bordure {} {
    if [catch {set largeur [htg getnext]} v] then {error $v}
    if [catch {set couleur [htg getnext]} v] then {error $v}
    return [list BORDER=$largeur]
}

# BASELINE/BOTTOM/CENTER/TOP
proc htg_centragevertical {} {
    if [catch {set centrage [htg getnext]} v] then {error $v}
    return ""
}

# CENTER/LEFT/RIGHT
proc htg_centragehorizontal {} {
    if [catch {set centrage [htg getnext]} v] then {error $v}
    return [list ALIGN=$centrage]
}

proc htg_taille {} {
    if [catch {set taille [htg getnext]} v] then {error $v}
    return [list WIDTH=$taille]
}

proc htg_couleurfond {} {
    if [catch {set couleur [htg getnext]} v] then {error $v}
    return ""
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
    if [catch {set attributs [htg getnext]} v] then {error $v}
    if [catch {set texte     [htg getnext]} v] then {error $v}

    return [list [list $nbcol $attributs $texte]]
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
    set texte [nettoyer-latex $texte]
    set partie(id) $texte
    return {}
}

proc htg_recuperer {} {
    global partie

    if [catch {set id [htg getnext]} v] then {error $v}
    return $partie($id)
}

##############################################################################
# Mise en forme LaTeX
##############################################################################

proc nettoyer-latex {texte} {
    # convertir les ~ en espaces insécables et les ~~ en ~
    regsub -all {~} $texte {\&nbsp;} texte
    regsub -all {\&nbsp;\&nbsp;} $texte {\~{}} texte
    regsub -all {\&nbsp;} $texte {~} texte

    return $texte
}
