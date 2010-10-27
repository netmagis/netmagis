#
#
# Modèle "transp" (transparents)
#
# Historique
#   1998/06/29 : pda : conception
#   1999/07/25 : pda : conversion au nouveau htg
#

#
# Inclure les directives de formattage de base
#

inclure-tcl include/html/base.tcl

###############################################################################
# Procédures de conversion HTML spécifiques au modèle
###############################################################################

global transparents
set transparents(max) 0

proc htg_transparent {} {
    global transparents

    if [catch {set titre "<TITLE>[htg getnext]</TITLE>"} v] then {error $v}

    if [catch {set texte [htg getnext]} v] then {error $v}
    set texte [nettoyer-html $texte]
    regsub -all "\n\n+" $texte "<P>" texte

    set n $transparents(max)
    incr n
    set transparents($n) $texte
    set transparents(titre-$n) $titre
    if {[info exists transparents(alias)]} then {
	set transparents(alias-$n) $transparents(alias)
	unset transparents(alias)
    }
    set transparents(max) $n

    return {}
}

proc htg_alias {} {
    global transparents

    if [catch {set transparents(alias) [htg getnext]} v] then {error $v}
    return {}
}

proc htg_titre {} {
    if [catch {set texte [htg getnext]} v] then {error $v}

    return "<H1 ALIGN=\"CENTER\">$texte</H1>"
}

###############################################################################
# lecture du fichier modèle
###############################################################################

proc htg_go {} {
    global partie transparents

    set n $transparents(max)
    for {set i 1} {$i <= $n} {incr i} {
	set filename [format $partie(template) $i]
	set fd [open $filename w]

	#######################################################################
	# le bandeau
	#######################################################################

	set prec [format $partie(template) [expr $i-1]]
	set suiv [format $partie(template) [expr $i+1]]

	set bandeau "<H6 ALIGN=\"right\">"
	if {$i > 1} then {
	    append bandeau "<A HREF=\"$prec\">\[Retour\]</A>"
	}
	if {$i < $n} then {
	    append bandeau "<A HREF=\"$suiv\">\[Suite\]</A>"
	}
	append bandeau "</H6>"

	#######################################################################
	# on y va
	#######################################################################

	puts $fd $partie(fond1)
	puts $fd $transparents(titre-$i)
	puts $fd $partie(fond2)
	puts $fd $bandeau
	puts $fd $transparents($i)
	puts $fd $partie(fond3)

	close $fd

	#######################################################################
	# alias
	#######################################################################

	if {[info exists transparents(alias-$i)]} then {
	    file delete -force -- $transparents(alias-$i)
	    file copy -- $filename $transparents(alias-$i)
	}
    }

    return {}
}
