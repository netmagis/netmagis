#
#
# Modèle "page de présentation d'une personne"
#
# Historique
#   1998/06/15 : pda          : conception
#   1999/07/04 : pda          : réécriture
#   2008/02/26 : pda/moindrot : \personne est maintenant dans le texte
#

#
# Inclure les directives de formattage de base
#

inclure-tcl include/html/base.tcl

###############################################################################
# Procédures de conversion HTML spécifiques au modèle
###############################################################################

set formatpersonne {
    Centre Réseau Communication <br>
    Université Louis Pasteur <br>
    %1$s <br>
    7 rue René Descartes <br>
    67084 Strasbourg Cedex <br>
    Tél : %2$s <br>
    Fax : %3$s <br>
    Courriel : <a href="mailto:%4$s@%5$s">%4$s@%5$s</a>
}

proc htg_personne {} {
    global formatpersonne

    if [catch {set nom [htg getnext]} v] then {error $v}
    if [catch {set gif [htg getnext]} v] then {error $v}
    if [catch {set tel [htg getnext]} v] then {error $v}
    if [catch {set fax [htg getnext]} v] then {error $v}
    if [catch {set mail [htg getnext]} v] then {error $v}
    if [catch {set domaine [htg getnext]} v] then {error $v}

    set image [helem IMG "" SRC $gif ALT "photo"]
    set texte [helem BLOCKQUOTE \
		[helem P \
		    [format $formatpersonne $nom $tel $fax $mail $domaine] \
		    ] \
		]

    return "$image\n$texte\n"
}

proc htg_titre {} {
    if [catch {set niveau [htg getnext]} v] then {error $v}
    check-int $niveau
    if [catch {set texte  [htg getnext]} v] then {error $v}

    incr niveau
    set r [helem H$niveau $texte]
    return $r
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
