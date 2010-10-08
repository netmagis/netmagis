#
# $Id$
#
# Librairie de fonctions TCL pour la génération de tableaux
#
# Exemple d'utilisation
#
#	set style { ... }
#	set data {}
#	for ...
#		lappend data [list pattern val1 val2 ... valn]
#	puts [::arrgen::output "html" $style $data]
#
# Ou :
#
#	set style { ... }
#	if {[::arrgen::parse tabstyle $style msg] == -1} then {
#		puts stderr $msg
#	}
#	set data {}
#	for ...
#		lappend data [list pattern val1 val2 ... valn]
#	puts [::arrgen::output "html" tabstyle $data]
#
# Langage des styles
#   - global
#	- chars
#	    <int> (normal | bold | italic)+
#	- color
#	    <hex> | transparent
#       - align
#	    left | right | center | justify
#	- botbar
#	    yes | no
#	- format
#	    raw | cooked | lines | <procedure>
#	- columns
#	    <int>+
#	- csv
#	    - separator
#		<character>
#	- latex
#	    - linewidth
#		<float>
#	    - bordersep
#		<float>
#   - pattern <nom>
#	- chars
#	    <int> (normal | bold | italic)+
#	- color
#	    <hex> | transparent
#       - align
#	    left | right | center | justify
#	- botbar
#	    yes | no
#	- format
#	    raw | cooked | lines | <procedure>
#	- topbar
#	    yes | no
#	- title
#	    yes | no
#	- vbar
#	    yes | no
#	- column
#	    - chars
#		<int> (normal | bold | italic)+
#	    - color
#		<hex> | transparent
#	    - align
#		left | right | center | justify
#	    - botbar
#		yes | no
#	    - format
#	        raw | cooked | lines | <procedure>
#	    - multicolumn
#		<int>
#
# Historique
#   2002/05/08 : pda : début de la conception
#   2002/05/10 : pda : codage de l'analyse et des générations csv et html
#   2002/05/11 : pda : codage de la génération latex
#   2002/05/12 : pda : mise au point
#   2003/08/08 : pda : somme des largeurs des colonnes ramenée à 100 %
#   2006/12/06 : pda : utilisation de CSS
#

package require webapp
package provide arrgen 1.1

namespace eval arrgen {
    #
    # Fonctions utilisables à l'extérieur du package
    #

    namespace export parse output debug \
					latex-string

    #
    # Liste avec valeurs possible : {errors syntax}
    #

    variable debuginfos {}

    #
    # Valeurs par défaut et mécanisme d'héritage
    #

    variable defaults
    array set defaults {
	inherit-defaults-global	{
				    csv-separator
				    latex-linewidth latex-bordersep
				    charsize charfont color align botbar format
				}

	csv-separator		,
	latex-linewidth		175
	latex-bordersep		2.3

	charsize		12
	charfont		normal
	color			transparent
	align			left
	botbar			0
	format			::arrgen::output-cooked

	inherit-defaults-pattern { ncols title topbar }
	inherit-global-pattern	{ charsize charfont color align botbar format }

	ncols			0
	title			0
	topbar			0

	vbar			0

	inherit-defaults-column { span }
	inherit-pattern-column	{ charsize charfont color align botbar format }

	span			1

    }

    #
    # Caractères à ignorer en latex
    #

    variable latex_ignore

    #
    # Chaîne de format pour utiliser CSS : classes à utiliser en
    # fonction de la taille de la fonte.
    # Si la chaîne est vide, le format classique ("font size=") est utilisé.
    #

    variable css_size "tab-text%d"
}


##############################################################################
# Activation du debug
##############################################################################

proc ::arrgen::debug {infos} {
    set ::arrgen::debuginfos $infos
}

##############################################################################
# Procédure principale du package
##############################################################################

#
# Procédure principale
#
# Entrée :
#   - paramètres :
#       - format : html/latex/csv
#       - style : le style proprement dit, ou le tableau déjà analysé
#	- data : les données
#   - variables globales :
#	- debuginfo : les informations de debug souhaitées
# Sortie :
#   - valeur de retour : valeur convertie en tableau, ou message d'erreur
#
# Note : voir la spécification du style dans l'en-tête du package
#
# Historique :
#   2002/05/10 : pda : conception
#

proc ::arrgen::output {format style data} {
    global errorInfo

    if {[llength $style] == 1} then {
	upvar $style tab
    } else {
	if {[::arrgen::parse tab $style msg] == -1} then {
	    puts stderr "Error: $msg"
	    return $msg
	}
    }

    set rp [catch {::arrgen::output-format $format tab $data} m]
    set savedinfo $errorInfo

    if {[lsearch $::arrgen::debuginfos errors] != -1 && $rp != 0} then {
	set m $savedinfo
    }
    return $m
}

proc ::arrgen::output-format {format tab data} {
    upvar $tab t

    #
    # Caractères à ignorer en format latex
    #
    set ::arrgen::latex_ignore ""
    foreach {min max} {0 8    11 31    127 160} {
	for {set i $min} {$i <= $max} {incr i} {
	    append ::arrgen::latex_ignore [format %c $i]
	}
    }

    #
    # Obtention du format de sortie
    #
    set kwd [::arrgen::get-kwd $format "format" \
			{ {html html} {latex latex} {pdf latex} {csv csv} } ]

    #
    # Génération et renvoi du résultat
    #
    return [::arrgen::output-$kwd t $data]
}

##############################################################################
# Analyse syntaxique du style
##############################################################################

#
# Analyse syntaxique du style
#
# Entrée :
#   - paramètres :
#       - tab : tableau à remplir, contenant le style en retour
#       - style : le style proprement dit
#	- msg : message d'erreur en retour
# Sortie :
#   - valeur de retour : 0 si tout s'est bien passé, ou -1 en cas d'erreur
#   - paramètre tableau : le tableau rempli
#   - paramètre msg : le message d'erreur en cas d'erreur
#
# Note : voir la spécification du style dans l'en-tête du package
#
# Historique :
#   2002/05/10 : pda : conception
#

proc ::arrgen::parse {tab style msg} {
    upvar $tab t
    upvar $msg m
    global ::arrgen::debuginfos
    global errorInfo

    catch {unset t}
    set r 0
    set rp [catch {::arrgen::parse-style t $style} m]
    set savedinfo $errorInfo

    if {[lsearch $::arrgen::debuginfos syntax] != -1} then {
	foreach f [lsort [array names t]] {
	    puts stderr [format "| %-40s | %-30s |" $f $t($f)]
	}
    }

    if {[lsearch $::arrgen::debuginfos errors] != -1 && $rp != 0} then {
	set m $savedinfo
    }

    if {$rp != 0} then {
	set r -1
    } else {
	set r 0
    }
    return $r
}

#
# Procédures d'analyse des éléments du style
#
# Entrée :
#   - paramètres :
#       - tab : tableau en cours de remplissage
#       - style : la partie du style à analyser
#	- msg : message d'erreur en retour
# Sortie :
#   - valeur de retour : aucune
#   - erreur : s'il y a eu erreur
#   - paramètre tab : le tableau en cours de remplissage
#
# Historique :
#   2002/05/10 : pda : conception
#

proc ::arrgen::parse-style {tab style} {
    upvar $tab t

    while {[llength $style] > 0} {
	set kwd [lindex $style 0]
	set arg [lindex $style 1]
	set n 1

	set kwd [::arrgen::get-kwd $kwd "top" \
			{
			    {global global}	{global global}
			    {pattern pattern}	{motif pattern}
			} ]

	switch -- $kwd {
	    global {
		::arrgen::parse-global t $arg
	    }
	    pattern {
		::arrgen::parse-pattern t [lindex $style 2] $arg
		set n 2
	    }
	}
	set style [lreplace $style 0 $n]
    }
}

########################################
# Global
########################################

proc ::arrgen::parse-global {tab style} {
    upvar $tab t

    #
    # Valeurs par défaut
    #
    ::arrgen::inherit ::arrgen::defaults "" t "" \
			$::arrgen::defaults(inherit-defaults-global)

    #
    # Analyse de la liste
    # 
    set ctxt "global"

    while {[llength $style] > 0} {
	set kwd [lindex $style 0]
	set arg [lindex $style 1]

	set kwd [::arrgen::get-kwd $kwd $ctxt \
			{
			    {chars chars}	{caracteres chars}
			    {color color}	{couleur color}
			    {align align}	{alignement align}
			    {botbar botbar}	{trait-horizontal botbar}
			    {format format}	{donnees-formatees format}
			    {columns columns}	{colonnes columns}
			    {csv   csv}
			    {latex latex}
			} ]

	::arrgen::parse-$kwd t $arg "" $ctxt
	set style [lreplace $style 0 1]
    }
}

#
# Remplit :
#   (rien)
#

proc ::arrgen::parse-ignore {tab style idx ctxt} {
}

#
# Remplit :
#   tab(charsize) :				<taille des caractères>
#   tab(charfont) :				normal|bold|bold-italic|italic
# ou :
#   tab(pattern-PPP-charsize) :			<taille des caractères>
#   tab(pattern-PPP-charfont) :			normal|bold|bold-italic|italic
# ou :
#   tab(pattern-PPP-col-CCC-charsize) :		<taille des caractères>
#   tab(pattern-PPP-col-CCC-charfont) :		normal|bold|bold-italic|italic
#

proc ::arrgen::parse-chars {tab style idx ctxt} {
    upvar $tab t

    set x(normal)	0
    set x(bold)		0
    set x(italic)	0

    foreach s $style {
	set kwd [::arrgen::get-kwd $s $ctxt \
			{
			    {normal normal}	{normal normal}
			    {bold bold}		{gras bold}
			    {italic italic}	{italique italic}
			    {[0-9]+ int}
			} ]

	if {[string equal $kwd int]} then {
	    set t(${idx}charsize) $s
	} else {
	    set x($kwd) 1
	}
    }

    switch -glob -- "$x(normal)$x(bold)$x(italic)" {
	000 { }
	001 { set t(${idx}charfont) "italic" }
	010 { set t(${idx}charfont) "bold" }
	011 { set t(${idx}charfont) "bold-italic" }
	100 { set t(${idx}charfont) "normal" }
	1*  {
	    ::arrgen::invalid-keyword "combination normal/bold/italic" \
				"chars" {normal bold italic}
	}
    }
}

#
# Remplit
#   tab(color) :			<color>
# ou :
#   tab(pattern-PPP-color) :		<color>
# ou :
#   tab(pattern-PPP-col-CCC-color) :	<color>
#

proc ::arrgen::parse-color {tab style idx ctxt} {
    upvar $tab t

    set kwd [::arrgen::get-kwd $style $ctxt \
		    {
			{transparent transparent}
			{[0-9A-Fa-f]+ hex}
		    } ]

    switch -- $kwd {
	transparent {
	    set t(${idx}color) $style
	}
	hex {
	    set t(${idx}color) [string toupper $style]
	}
    }
}

#
# Remplit :
#   tab(align)				<left/center/right/justify>
# ou :
#   tab(pattern-PPP-align)		<left/center/right/justify>
# ou :
#   tab(pattern-PPP-col-CCC-align)	<left/center/right/justify>
#

proc ::arrgen::parse-align {tab style idx ctxt} {
    upvar $tab t

    set t(${idx}align) [::arrgen::get-kwd $style "$ctxt, align" \
			    {
				{left left}	{gauche left}
				{center center}	{centre center}
				{right right}	{droit right}
				{justify justify}
			    } ]
}

#
# Remplit :
#   tab(botbar)				<0/1>
# ou :
#   tab(pattern-PPP-botbar)		<0/1>
# ou :
#   tab(pattern-PPP-col-CCC-botbar)	<0/1>
#

proc ::arrgen::parse-botbar {tab style idx ctxt} {
    upvar $tab t

    set t(${idx}botbar) [::arrgen::get-yesno $style "$ctxt, botbar"]
}


#
# Remplit :
#   tab(ncols) :		<nb de columns>
#   tab(col-CCC-width) :	<largeur de la colonne CCC en %>
#

proc ::arrgen::parse-columns {tab style idx ctxt} {
    upvar $tab t

    set ncols 0
    set total 0
    foreach c $style {
	incr ncols
	set t(col-$ncols-width) [::arrgen::get-int $c "global, column $ncols size"]
	incr total $c
    }

    set t(ncols) $ncols

    #
    # Ancienne version : test strict d'égalité à 100 %
    #

#    if {$total != 100} then {
#	error "Size of all $ncols columns is '$total', should be 100"
#    }

    #
    # Nouvelle version : on ramène à 100 %
    #

    if {$total != 100} then {
	set ncols 0
	set ntotal 0
	foreach c $style {
	    incr ncols
	    set w $t(col-$ncols-width)
	    set nw [expr "round (100.0 * double($w) / $total)"]
	    set t(col-$ncols-width) $nw
	    incr ntotal $nw
	}
	if {$ntotal != 100} then {
	    incr t(col-$ncols-width) [expr 100-$ntotal]
	}
    }
}

########################################
# CSV specific parameters
########################################

proc ::arrgen::parse-csv {tab style idx ctxt} {
    upvar $tab t

    while {[llength $style] > 0} {
	set kwd [lindex $style 0]
	set arg [lindex $style 1]

	set kwd [::arrgen::get-kwd $kwd $ctxt \
			{
			    {separator csv-separator}
			} ]

	::arrgen::parse-$kwd t $arg "" $ctxt
	set style [lreplace $style 0 1]
    }
}

#
# Remplit :
#   tab(csv-separator)		<char>
#

proc ::arrgen::parse-csv-separator {tab style idx ctxt} {
    upvar $tab t

    if {[string length $style] != 1} then {
	error "CSV separator must be exactly one character"
    }

    set t(${idx}csv-separator) $style
}

########################################
# LaTeX specific parameters
########################################

proc ::arrgen::parse-latex {tab style idx ctxt} {
    upvar $tab t

    while {[llength $style] > 0} {
	set kwd [lindex $style 0]
	set arg [lindex $style 1]

	set kwd [::arrgen::get-kwd $kwd $ctxt \
			{
			    {linewidth latex-linewidth}
			    {bordersep latex-bordersep}
			} ]

	::arrgen::parse-$kwd t $arg "" $ctxt
	set style [lreplace $style 0 1]
    }
}

#
# Remplit :
#   tab(latex-linewidth)	<float>
#

proc ::arrgen::parse-latex-linewidth {tab style idx ctxt} {
    upvar $tab t

    set t(${idx}latex-linewidth) [expr double($style)]
}

#
# Remplit :
#   tab(latex-bordersep)	<float>
#

proc ::arrgen::parse-latex-bordersep {tab style idx ctxt} {
    upvar $tab t

    set t(${idx}latex-bordersep) [expr double($style)]
}

########################################
# Pattern
########################################

#
# Remplit :
#   tab(patterns)		ajoute le nom du motif
#   tab(pattern-PPP-ncols)	<nb de colonnes du motif PPP>
#   tab(pattern-PPP-col-CCC-vbar)	<0/1>
#

proc ::arrgen::parse-pattern {tab style name} {
    upvar $tab t

    if {! [regexp {^[-A-Za-z0-9]+$} $name]} then {
	error "Invalid syntax for pattern '$name'"
    }

    lappend t(patterns) $name
    set idx "pattern-$name-"

    #
    # Valeurs par défaut du motif
    #

    if {! [info exists t(charsize)]} then {
	error "Section 'global' not found"
    }

    ::arrgen::inherit ::arrgen::defaults "" t $idx \
			$::arrgen::defaults(inherit-defaults-pattern)
    ::arrgen::inherit t "" t $idx \
			$::arrgen::defaults(inherit-global-pattern)

    set t(${idx}col-0-vbar)	$::arrgen::defaults(vbar)

    #
    # Analyse du motif
    #

    set ctxt "pattern '$name'"

    while {[llength $style] > 0} {
	set kwd [lindex $style 0]
	set arg [lindex $style 1]

	set kwd [::arrgen::get-kwd $kwd $ctxt \
			{
			    {chars chars}	{caracteres chars}
			    {color color}	{couleur color}
			    {align align}	{alignement align}
			    {botbar botbar}	{trait-horizontal botbar}
			    {format format}	{donnees-formatees format}
			    {topbar topbar}	{trait-dessus topbar}
			    {title title}
			    {vbar vbar}		{trait-vertical vbar}
			    {column column}	{colonne column}

			    {repetition ignore}
			    {afficher ignore}
			} ]

	::arrgen::parse-$kwd t $arg $idx $ctxt

	set style [lreplace $style 0 1]
    }

    set lastcol $t(${idx}ncols)
    for {set c 0} {$c <= $lastcol} {incr c} {
	if {! [info exists t(${idx}col-$c-vbar)]} then {
	    set t(${idx}col-$c-vbar) $::arrgen::defaults(vbar)
	}
    }

    set ncol 0
    for {set c 1} {$c <= $lastcol} {incr c} {
	incr ncol $t(${idx}col-$c-span)
    }

    if {$ncol != $t(ncols)} then {
	error "Invalid number of columns ($ncol) in pattern '$name'"
    }
}

#
# Remplit :
#   tab(pattern-PPP-topbar)		<0/1>
#

proc ::arrgen::parse-topbar {tab style idx ctxt} {
    upvar $tab t

    set t(${idx}topbar) [::arrgen::get-yesno $style "$ctxt, topbar"]
}


#
# Remplit :
#   tab(pattern-PPP-title)		<0/1>
#

proc ::arrgen::parse-title {tab style idx ctxt} {
    upvar $tab t

    set t(${idx}title) [::arrgen::get-yesno [lindex $style 0] $ctxt]
}

#
# Remplit :
#   tab(pattern-PPP-col-CCC-vbar)	<0/1>
#

proc ::arrgen::parse-vbar {tab style idx ctxt} {
    upvar $tab t

    set colnum $t(${idx}ncols)
    set t(${idx}col-$colnum-vbar) [::arrgen::get-yesno $style "$ctxt, vbar"]
}

########################################
# Column
########################################

#
# idx = pattern-PPP
#
# Remplit :
#   tab(pattern-PPP-ncols)		<nb de colonnes du motif PPP>
#

proc ::arrgen::parse-column {tab style idx ctxt} {
    upvar $tab t

    incr t(${idx}ncols)
    set colnum $t(${idx}ncols)
    set colidx ${idx}col-$colnum-

    append ctxt ", column $colnum"

    #
    # Valeurs par défaut de la colonne
    #

    ::arrgen::inherit ::arrgen::defaults "" t $colidx \
			$::arrgen::defaults(inherit-defaults-column)
    ::arrgen::inherit t $idx t $colidx \
			$::arrgen::defaults(inherit-pattern-column)

    #
    # Analyse des arguments
    #

    while {[llength $style] > 0} {
	set kwd [lindex $style 0]
	set arg [lindex $style 1]

	set kwd [::arrgen::get-kwd $kwd $ctxt \
			{
			    {chars chars}	{caracteres chars}
			    {color color}	{couleur color}
			    {align align}	{alignement align}
			    {botbar botbar}	{trait-horizontal botbar}
			    {multicolumn multicolumn}	{multi-colonnes multicolumn}
			    {multicolumns multicolumn}
			    {format format}	{donnees-formatees format}
			} ]

	::arrgen::parse-$kwd t $arg $colidx $ctxt
	set style [lreplace $style 0 1]
    }
}

#
# Remplit :
#   tab(pattern-PPP-col-CCC-span)	<int>
#

proc ::arrgen::parse-multicolumn {tab style idx ctxt} {
    upvar $tab t

    set t(${idx}span) [::arrgen::get-int $style "$ctxt, multicolumn"]
}

#
# Remplit :
#   tab(pattern-PPP-col-CCC-format)	<nom de procédure>
#			(avec deux procédures précodées : raw et cooked)
#

proc ::arrgen::parse-format {tab style idx ctxt} {
    upvar $tab t

    set kwd [::arrgen::get-kwd $style "$ctxt, align" \
			    {
				{cooked cooked}
				{raw    raw}
				{lines  lines}
				{oui    raw}  	{non cooked}
				{[-a-zA-Z0-9]+ proc}
			    } ]
    switch $kwd {
	proc    { set v [list proc $style] }
	default { set v "::arrgen::output-$kwd" }
    }
    set t(${idx}format) $v
}

########################################
# Utilitaires
########################################

proc ::arrgen::get-yesno {val ctxt} {
    return [::arrgen::get-kwd $val $ctxt \
		    {
			{oui 1} {yes 1} {1 1} {non 0} {no 0} {0 0}
		    } ]
}

proc ::arrgen::get-kwd {val ctxt lval} {
    set ak {}
    foreach v $lval {
	set re [lindex $v 0]
	lappend ak $re
	if {[regexp "^$re$" $val]} then {
	    return [lindex $v 1]
	}
    }
    ::arrgen::invalid-keyword $val $ctxt $ak
}

proc ::arrgen::get-int {val ctxt} {
    if {! [regexp {^[0-9]+} $val]} then {
	error "Invalid integer '$val' in context '$ctxt'"
    }
    return $val
}

proc ::arrgen::invalid-keyword {kwd ctxt defval} {
    set shouldbe ""
    if {[llength $defval] > 0} then {
	set defval [join $defval "|"]
	set shouldbe " : should be $defval"
    }
    error "Invalid keyword '$kwd' in context '$ctxt'$shouldbe"
}

proc ::arrgen::inherit {tabtop topctxt tabcur curctxt fields} {
    upvar $tabtop ttop
    upvar $tabcur tcur

    foreach f $fields {
	if {[info exists ttop($topctxt$f)]} then {
	    set tcur($curctxt$f) $ttop($topctxt$f)
	} else {
	    error "Internal : bad inherit field '$topctxt$f' -> '$curctxt$f'"
	}
    }
}

##############################################################################
# Fonctions auxiliaires de génération
##############################################################################

#
# Effectue quelques vérifications élémentaires sur la ligne du tableau
#
# Entrée :
#   - paramètres :
#       - tab : le tableau contenant le style
#	- lineno : numéro de la ligne courante
#	- line : la ligne courante (y compris le motif)
# Sortie :
#   - valeur de retour : -
#
# Historique :
#   2002/05/10 : pda : conception
#

proc ::arrgen::check-pattern-nbcols {tab lineno line} {
    upvar $tab t

    set pattern [lindex $line 0]

    if {[lsearch -exact $t(patterns) $pattern] == -1} then {
	error "Line $lineno: pattern '$pattern' not found"
    }

    set ncols [expr [llength $line] - 1]
    if {$ncols != $t(pattern-$pattern-ncols)} then {
	error "Line $lineno: invalid nb of columns ($ncols) for pattern '$pattern'"
    }
}

#
# Indique s'il faut une bordure au tableau
#
# Entrée :
#   - paramètres :
#       - tab : tableau contenant le style
# Sortie :
#   - valeur de retour : 0 ou 1
#
# Note : HTML ne disposant pas de moyen pour définir la bordure de chaque
#   case, on définit, par convention, que s'il y a au moins un trait
#   extérieur vertical (trait avant la case la plus à gauche, ou après la
#   case la plus à droite), on met une bordure.
#
# Historique :
#   2002/05/11 : pda : conception
#   2002/05/14 : pda : conception
#

proc ::arrgen::any-vbar {tab} {
    upvar $tab t

    set r 0
    foreach p $t(patterns) {
	set idx "pattern-$p-"
	set ncols $t(${idx}ncols)
	if {$t(${idx}col-0-vbar) || $t(${idx}col-$ncols-vbar)} then {
	    set r 1
	    break
	}
    }
    return $r
}

##############################################################################
# Génération csv
##############################################################################

#
# Génération du tableau en format CSV
#
# Entrée :
#   - paramètres :
#       - tab : tableau contenant le style
#	- data : les données
# Sortie :
#   - valeur de retour : valeur convertie en tableau
#
# Historique :
#   2002/05/10 : pda : conception
#

proc ::arrgen::output-csv {tab data} {
    upvar $tab t

    set lineno 0
    set csv ""
    foreach line $data {
	incr lineno
	::arrgen::check-pattern-nbcols t $lineno $line
	set idx "pattern-[lindex $line 0]-"
	append csv [::arrgen::output-csv-line t $idx [lreplace $line 0 0]]
    }
    return $csv
}

#
# Génération d'une ligne CSV du tableau
#
# Entrée :
#   - paramètres :
#       - tab : tableau contenant le style
#	- idx : index du motif dans le tableau tab
#	- line : la ligne composée d'une liste des colonnes
# Sortie :
#   - valeur de retour : ligne convertie en ligne de tableau
#
# Historique :
#   2002/05/10 : pda : conception
#

proc ::arrgen::output-csv-line {tab idx line} {
    upvar $tab t

    set csvlist {}
    set icol 0
    foreach val $line {
	incr icol

	set needquote 0
	if {[regsub -all {"} $val {""} csvval] > 0} then {
	    set needquote 1
	}
	if {[regexp $t(csv-separator) $csvval]} then {
	    set needquote 1
	}
	if {[regexp {[\n\r]} $csvval]} then {
	    set needquote 1
	}
	if {$needquote} then {
	    set csvval "\"$csvval\""
	}

	lappend csvlist $csvval

	for {set i 2} {$i < $t(${idx}col-$icol-span)} {incr i} {
	    lappend csvlist {}
	}
    }
    append csv "[join $csvlist $t(csv-separator)]\n"
}

##############################################################################
# Génération html
##############################################################################

#
# Génération du tableau en format HTML
#
# Entrée :
#   - paramètres :
#       - tab : tableau contenant le style
#	- data : les données
# Sortie :
#   - valeur de retour : valeur convertie en tableau
#
# Historique :
#   2002/05/10 : pda : conception
#

proc ::arrgen::output-html {tab data} {
    upvar $tab t

    if {[::arrgen::any-vbar t]} then {
	set border " BORDER=2 CELLPADDING=5 CELLSPACING=1"
    } else {
	set border ""
    }
    set html "<table width=\"100%\"$border>\n"

    set lineno 0
    foreach line $data {
	incr lineno
	::arrgen::check-pattern-nbcols t $lineno $line
	set idx "pattern-[lindex $line 0]-"
	append html [::arrgen::output-html-line t $idx [lreplace $line 0 0]]
    }

    append html "</table>\n"

    return $html
}

#
# Génération d'une ligne HTML du tableau
#
# Entrée :
#   - paramètres :
#       - tab : tableau contenant le style
#	- idx : index du motif dans le tableau tab
#	- line : la ligne composée d'une liste des colonnes
# Sortie :
#   - valeur de retour : ligne convertie en ligne de tableau
#
# Historique :
#   2002/05/10 : pda : conception
#   2002/05/18 : pda : ajout du paramètre align -> jusitfy
#

proc ::arrgen::output-html-line {tab idx line} {
    upvar $tab t

    set html ""
    set icol 0
    set realcol 0
    foreach val $line {
	incr icol
	incr realcol

	set colidx "${idx}col-$icol-"

	# Alignement et justification
	switch $t(${colidx}align) {
	    left	{ set align " align=left" }
	    center	{ set align " align=center" }
	    right	{ set align " align=right" }
	    justify	{ set align "" }
	}

	# Multi-colonnes
	set span $t(${colidx}span)
	set width $t(col-$realcol-width)
	for {set i 1} {$i < $span} {incr i} {
	    incr realcol
	    incr width $t(col-$realcol-width)
	}
	if {$span > 1} then {
	    set colspan " colspan=\"$span\""
	} else {
	    set colspan ""
	}

	# Largeur
	set width " width=\"$width%\""

	# Couleur
	if {[string equal $t(${colidx}color) "transparent"]} then {
	    set color ""
	} else {
	    set color " bgcolor=\"#$t(${colidx}color)\""
	}

	# taille
	set class ""
	if {! [string equal $::arrgen::css_size ""]} then {
	    set css [format $::arrgen::css_size  $t(${colidx}charsize)]
	    set class [format " class=\"$css\""]
	}


	# Début de la colonne
	append html "<td$width$colspan$align$color$class>"

	set font [::arrgen::html-font $t(${colidx}charsize) $t(${colidx}charfont)]
	append html "[lindex $font 0]\n"

	if {[string length [string trim $val]] == 0} then {
	    set val "&nbsp;"
	} else {
	    set fmt $t(${colidx}format)
	    set val [$fmt html $t(${colidx}align) $val]
	}

	append html "$val\n"

	# Fin de la colonne
	append html "[lindex $font 1]\n"
	append html "</td>\n"
    }
    return "<tr>\n$html</tr>\n"
}

#
# Correspondance entre les spécifications de police et le code html
#
# Entrée :
#   - paramètres :
#       - size : taille de police telle qu'elle figure dans le style
#       - font : police telle qu'elle figure dans le style
# Sortie :
#   - valeur de retour : liste à deux éléments {a b} où "a" est le
#	code à insérer avant le texte, et "b" le code à insérer après.
#
# Historique :
#   2002/05/10 : pda : conception
#   2006/12/06 : pda : support css
#

proc ::arrgen::html-font {size font} {
    #
    # Taille de la fonte
    #

    if {[string equal $::arrgen::css_size ""]} then {
	if {$size <= 8} then {
	    set s "1"
	} elseif {$size <= 10} then {
	    set s "2"
	} elseif {$size <= 12} then {
	    set s "3"
	} elseif {$size <= 14} then {
	    set s "4"
	} elseif {$size <= 16} then {
	    set s "5"
	} elseif {$size <= 18} then {
	    set s "6"
	} elseif {$size <= 20} then {
	    set s "7"
	} elseif {$size <= 22} then {
	    set s "8"
	} else {
	    set s "9"
	}
	set size1 "<font size=\"$s\">"
	set size2 "</font>"
    } else {
	set size1 ""
	set size2 ""
    }

    #
    # Style
    #

    switch $font {
	normal      { set style1 "" ;       set style2 "" }
	bold        { set style1 "<b>" ;    set style2 "</b>" }
	italic      { set style1 "<i>" ;    set style2 "</i>" }
	bold-italic { set style1 "<b><i>" ; set style2 "</i></b>" }
    }

    return [list "$size1$style1" "$style2$size2"]
}

##############################################################################
# Génération latex
##############################################################################

#
# Génération du tableau en format LATEX
#
# Entrée :
#   - paramètres :
#       - tab : tableau contenant le style
#	- data : les données
# Sortie :
#   - valeur de retour : valeur convertie en tableau
#
# Historique :
#   2002/05/10 : pda : conception
#

proc ::arrgen::output-latex {tab data} {
    upvar $tab t

    ::arrgen::latex-colwidth t
    ::arrgen::latex-botbar t

    set latex ""

    #
    # Faut-il des bordures horizontales en haut et en bas de
    # chaque page du tableau ?
    #

    set title ""
    if {[::arrgen::any-vbar t]} then {
	append latex "\\tabletail \{\\hline\}\n"
	append latex "\\tablehead \{\\hline\}\n"
    } else {
	append latex "\\tabletail \{\}\n"
	append latex "\\tablehead \{\}\n"
    }
    append latex "\\tablefirsthead \{\}\n"
    append latex "\\tablelasttail \{\}\n"

    #
    # Préparation de l'en-tête, qu'on ne sortira qu'à la première
    # ligne affichable.
    #
    set cols [string repeat "c" $t(ncols)]
    set header "\\begin \{supertabular\} \{$cols\}\n"
    set headerprinted 0

    set lineno 0
    set nlines [llength $data]
    foreach line $data {
	incr lineno
	::arrgen::check-pattern-nbcols t $lineno $line
	set idx "pattern-[lindex $line 0]-"

	set l [::arrgen::output-latex-line t $idx [lreplace $line 0 0]]

	#
	# Est-ce que cette ligne est une ligne spéciale (i.e. à répéter) ?
	#

	if {$t(${idx}title)} then {
	    append title $l
	    append latex "\\tablefirsthead \{$title\}"
	    append latex "\\tablehead \{$title\}"
	} else {
	    if {! $headerprinted} then {
		append latex $header
		set headerprinted 1
	    }
	    append latex $l
	}
    }

    if {$headerprinted} then {
	append latex "\\end \{supertabular\}\n"
    }

    return $latex
}

#
# Calcul des tailles de toutes les colonnes possibles du tableau.
#
# Entrée :
#   - paramètres :
#       - tab : tableau contenant le style
# Sortie :
#   - valeur de retour : -
#   - paramètre tab :
#	t(pattern-PPP-col-CCC-latexwidth) : taille à mettre avec \linewidth
#
# Note :
#    Le texte dans une cellule de tableau latex est bordé par
#    un petit espace E de part et d'autre. Cet espace E = 2,3 mm.
#   
#                   60 %                           40 %
#    | <------------------------------> | <--------------------> |
#    |                                  |                        |
#    |   E           T1             E       E      T2        E   |
#    | <--> <--------------------> <--> | <--> <----------> <--> |
#    |                                                           |
#    |   E          T12 (multicolonne sur 1 et 2)            E   |
#    | <--> <---------------------------------------------> <--> |
#   
#    Toutes les dimensions doivent être proportionnelles à
#    \linewidth. Seul E (2,3 mm) ne peut être dérivé de \linewidth
#    exactement. C'est pour cela qu'on prend une approximation :
#    si \linewidth = 175 mm, E = I \linewidth, avec I = 2.3/175
#   
#    Donc, la largeur du texte T dans une colonne C est calculée
#    empiriquement à partir de :
#   	- L = largeur de toutes les colonnes constituant C
#   		(notamment en cas de multicolonnage)
#   		Exemple L1 = 60%, L2 = 40%, L12 = 100%
#   	- B = largeur de la bordure = 2 I
#    d'où T = (L/100 - B) * \linewidth
#
# Historique :
#   2002/05/12 : pda : conception
#   2002/05/18 : pda : ajout du paramètre align -> jusitfy
#

proc ::arrgen::latex-colwidth {tab} {
    upvar $tab t

    set B [expr 2 * ($t(latex-bordersep) / $t(latex-linewidth))]

    foreach p $t(patterns) {
	set ncols $t(pattern-$p-ncols)
	set realcol 1
	set mcol 1
	for {set mcol 1} {$mcol <= $ncols} {incr mcol} {
	    set span $t(pattern-$p-col-$mcol-span)
	    set L 0
	    for {set i 0} {$i < $span} {incr i} {
		incr L $t(col-$realcol-width)
		incr realcol
	    }
	    set t(pattern-$p-col-$mcol-latexwidth) [expr ($L / 100.0) - $B]
	}
    }
}

#
# Calcul de tous les traits en dessous des colonnes
#
# Entrée :
#   - paramètres :
#       - tab : tableau contenant le style
# Sortie :
#   - valeur de retour : -
#   - paramètre tab :
#	t(pattern-PPP-latexbotbar) : {{min max} {max max} ...}
#		avec min et max les paramètres pour \cline
#		et min = -1 si \hline
#
# Historique :
#   2002/05/12 : pda : conception
#   2002/05/25 : pda : correction d'un bug si max = realcol - 1
#

proc ::arrgen::latex-botbar {tab} {
    upvar $tab t

    foreach p $t(patterns) {
	set botidx pattern-$p-latexbotbar
	set t($botidx) {}

	set begin -1
	set realcol 1
	set ncols $t(pattern-$p-ncols)

	for {set mcol 1} {$mcol <= $ncols} {incr mcol} {
	    set lastrealcol [expr $realcol - 1]

	    if {$t(pattern-$p-col-$mcol-botbar)} then {
		# une barre en dessous de la colonne
		if {$begin <= 0} then {
		    # début d'un cline
		    set begin $realcol
		}
	    } else {
		# pas de barre en dessous de la colonne
		if {$begin > 0} then {
		    lappend t($botidx) [list $begin $lastrealcol]
		    set begin -1
		}
	    }
	    incr realcol $t(pattern-$p-col-$mcol-span)
	}

	if {$begin == 1} then {
	    lappend t($botidx) {-1 -1}
	} elseif {$begin > 1} then {
	    lappend t($botidx) [list $begin [expr $realcol - 1]]
	}
    }
}

#
# Génération d'une ligne LATEX du tableau
#
# Entrée :
#   - paramètres :
#       - tab : tableau contenant le style
#	- idx : index du motif dans le tableau tab
#	- line : la ligne composée d'une liste des colonnes
# Sortie :
#   - valeur de retour : ligne convertie en ligne de tableau
#
# Historique :
#   2002/05/10 : pda : conception
#

proc ::arrgen::output-latex-line {tab idx line} {
    upvar $tab t

    set latex ""

    #
    # Le trait au dessus n'est en principe que pour la première
    # ligne, ou alors pour la première ligne qui suivrait d'autres
    # lignes sans trait dessous.
    #
    if {$t(${idx}topbar)} then {
	append latex "\\hline\n"
    }

    #
    # Parcours des cellules de la ligne
    #

    set icol 0
    foreach val $line {
	set prevcol $icol
	incr icol
	set colidx "${idx}col-$icol-"

	#
	# Séparateur de colonnes
	#
	if {$icol > 1} then {
	    append latex " & "
	}

	#
	# Alignement de la cellule
	#
	set align $t(${colidx}align)
	switch $align {
	    left    { set aligncmd "\\raggedright " }
	    center  { set aligncmd "\\centering " }
	    right   { set aligncmd "\\raggedleft " }
	    justify { set aligncmd "" }
	}

	#
	# Traits verticaux de chaque coté de la cellule
	#
	set colbefore ""
	if {$t(${idx}col-$prevcol-vbar)} then {
	    set colbefore "|"
	}
	set colafter ""
	if {$t(${idx}col-$icol-vbar)} then {
	    set colafter "|"
	}

	#
	# Début de la colonne
	#
	set width $t(${colidx}latexwidth)
	set span  $t(${colidx}span)
	append latex "\\multicolumn \{$span\}"
	append latex " \{${colbefore}p\{$width\\linewidth\}${colafter}\}"
	append latex " \{"

	#
	# Police
	#
	set font [::arrgen::latex-font $t(${colidx}charsize) $t(${colidx}charfont)]
	append latex [lindex $font 0]
	append latex $aligncmd

	#
	# Le texte
	#
	set fmt $t(${colidx}format)
	append latex [$fmt latex $align $val]

	#
	# Fin de la colonne
	#
	append latex [lindex $font 1]
	append latex "\}\n"
    }

    #
    # Fin de la ligne
    #

    append latex "\\tabularnewline"

    #
    # Recherche des traits horizontaux à mettre :
    # - soit une série de cline
    # - soit un seul hline
    #

    foreach botbar $t(${idx}latexbotbar) {
	set first [lindex $botbar 0]
	set last  [lindex $botbar 1]

	if {$first == -1} then {
	    append latex " \\hline"
	} else {
	    append latex " \\cline \{$first-$last\}"
	}
    }

    return "$latex\n"
}

#
# Correspondance entre les spécifications de police et le code latex
#
# Entrée :
#   - paramètres :
#       - size : taille de police telle qu'elle figure dans le style
#       - font : police telle qu'elle figure dans le style
# Sortie :
#   - valeur de retour : liste à deux éléments {a b} où "a" est le
#	code à insérer avant le texte, et "b" le code à insérer après.
#
# Historique :
#   2002/05/10 : pda : conception
#

proc ::arrgen::latex-font {size font} {
    #
    # Taille de la fonte
    #

    if {$size <= 8} then {
	set s "\\scriptsize"
    } elseif {$size <= 10} then {
	set s "\\footnotesize"
    } elseif {$size <= 12} then {
	set s "\\normalsize"
    } elseif {$size <= 14} then {
	set s "\\large"
    } elseif {$size <= 16} then {
	set s "\\Large"
    } elseif {$size <= 20} then {
	set s "\\LARGE"
    } else {
	set s "\\huge"
    }

    #
    # Style. On n'a pas vraiment besoin de style2, mais on
    # laisse par souci d'homogénéïté avec la version html.
    #

    set it "\\itshape"
    set bf "\\bfseries"
    switch $font {
	normal      { set style1 "" ;        set style2 "" }
	bold        { set style1 "$bf " ;    set style2 "" }
	italic      { set style1 "$it " ;    set style2 "" }
	bold-italic { set style1 "$bf$it " ; set style2 "" }
    }

    return [list "$s $style1" "$style2"]
}

#
# Débarasse un texte de tous les caractères spéciaux de latex
#
# Entrée :
#   - paramètres :
#       - s : chaîne à traiter
#   - variable globale ::arrgen::latex_ignore
#	suite de caractères à ignorer
# Sortie :
#   - valeur de retour : la chaîne traitée
#
# Historique :
#   2002/05/11 : pda : conception
#

proc ::arrgen::latex-string {s} {

    set patterns {
	\\\\		SENTINELLE1

	[_&%#\{\}]	\\\\&
	\\~		{\\~\ }
	\\^		{\\^\ }
	\\$		\\\\$
	[°º]		$^\\circ$
	«		<<
	»		>>
	¤		\\EUR\{\}
	\\?`		{? `}
	!`		{! `}

	SENTINELLE1	$\\backslash$
    }
    regsub -all -- SENTINELLE1 $patterns [format %c 1] patterns

    foreach {re sub} $patterns {
	regsub -all -- $re $s $sub s
    }

    regsub -all -- "\[$::arrgen::latex_ignore\]" $s "" s

    return $s
}


##############################################################################
# Procédures de formattage spécialisées
##############################################################################

#
# Procédure de formattage pour le format "raw" : aucune transformation.
# Utilisée pour mettre dans un tableau des URL ou du code spécifique.
#
# Entrée :
#   - paramètres :
#       - format  : l'un des formats de sortie (csv, html, latex)
#       - align  : l'un des alignements (left, center, right, justify)
#	- val : la case de tableau à formatter
# Sortie :
#   - valeur de retour : la case de tableau convertie au format
#
# Historique :
#   2002/05/10 : pda : conception
#   2002/05/18 : pda : ajout du paramètre align
#

proc ::arrgen::output-raw {format align val} {
    return $val
}

#
# Procédure de formattage pour le format "cooked" : tous les
# caractères spéciaux sont substitués le cas échéant.
# Utilisée pour mettre dans un tableau du texte qui doit être
# formatté en un seul paragraphe.
#
# Entrée :
#   - paramètres :
#       - format  : l'un des formats de sortie (csv, html, latex)
#       - align  : l'un des alignements (left, center, right, justify)
#	- val : la case de tableau à formatter
# Sortie :
#   - valeur de retour : la case de tableau convertie au format
#
# Historique :
#   2002/05/10 : pda : conception
#   2002/05/18 : pda : ajout du paramètre align
#

proc ::arrgen::output-cooked {format align val} {
    switch $format {
	csv { }
	html {
	    set val [::webapp::html-string $val]
	}
	latex {
	    set val [::arrgen::latex-string $val]
	}
    }
    return $val
}

#
# Procédure de formattage pour le format "lines" : tous les
# caractères spéciaux sont substitués le cas échéant, et les
# sauts de ligne et de paragraphe sont préservés.
#
# Entrée :
#   - paramètres :
#       - format  : l'un des formats de sortie (csv, html, latex)
#       - align  : l'un des alignements (left, center, right, justify)
#	- val : la case de tableau à formatter
# Sortie :
#   - valeur de retour : la case de tableau convertie au format
#
# Historique :
#   2002/05/10 : pda : conception
#   2002/05/18 : pda : ajout du paramètre align
#

proc ::arrgen::output-lines {format align val} {
    switch $format {
	csv { }
	html {
	    set val [::webapp::html-string $val]
	    regsub -all -- "\n\n+" $val "<p>" val
	    if {! [string equal $align "justify"]} then {
		regsub -all -- "\n" $val "<br>" val
	    }
	}
	latex {
	    set val [::arrgen::latex-string $val]
	    regsub -all -- "^(\[ 	\]*\n)+" $val {} val
	    regsub -all -- "\n(\[ 	\]*\n)+" $val {\\par } val
	    regsub -all -- "\n" $val "\\\\\\\\ \{\}\n" val
	}
    }
    return $val
}
