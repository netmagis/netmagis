#
# $Id: base.tcl,v 1.11 2008-03-04 08:51:29 pda Exp $
#
# Modèle HTG de base pour la génération de pages HTML
# Doit être inclus en premier par le modèle
# Peut être complété par des procédures issues du modèle spécifique
#
# Historique
#   1999/06/20 : pda          : séparation pour permettre d'autres langages
#   1999/07/02 : pda          : simplification
#   1999/07/26 : pda          : ajout de lt et gt
#   1999/09/12 : pda          : gestion minimale d'erreur
#   2001/10/19 : pda          : ajout des "meta"
#   2008/02/11 : pda/moindrot : ajout de rss et logo, et helem
#   2008/02/18 : pda/moindrot : intégration des bandeaux
#

##############################################################################
# valeurs par défaut
##############################################################################

set partie(rss)  ""
set partie(header)  ""
set partie(body-onload)  ""
set partie(body-onunload)  ""

# valeur par défaut de "meta"
set partie(meta) ""
set partie(soustitre) 10
set partie(currentcol) 0

##############################################################################
# procédures utilitaires
##############################################################################


proc check-int {v} {
    if {! [regexp {^[0-9]+$} $v]} then {
	error "$v is not a number"
    }
}

# HTML element
proc helem {tag content args} {
    set tag [string tolower $tag]
    set r "<$tag"
    foreach {attr value} $args {
	set attr [string tolower $attr]
	append r " $attr=\"$value\""
    }
    append r ">$content"
    # ne mettre une fermeture que pour les tags qui ne figurent pas
    # dans la liste ci-dessous
    if {[lsearch {img meta link} $tag] == -1} then {
	append r "</$tag>"
    }
    return $r
}

###############################################################################
# Mise en forme du texte
###############################################################################

proc htg_gras {} {
    if [catch {set arg [htg getnext]} v] then {error $v}
    set r [helem B $arg]
    return $r
}

proc htg_teletype {} {
    if [catch {set arg [htg getnext]} v] then {error $v}
    set r [helem TT $arg]
    return $r
}

proc htg_italique {} {
    if [catch {set arg [htg getnext]} v] then {error $v}
    set r [helem I $arg]
    return $r
}

proc htg_souligne {} {
    if [catch {set arg [htg getnext]} v] then {error $v}
    set r [helem U $arg]
    return $r
}

proc htg_retrait {} {
    if [catch {set arg [htg getnext]} v] then {error $v}
    set r [helem BLOCKQUOTE $arg]
    return $r
}

proc htg_image {} {
    if [catch {set source [htg getnext]} v] then {error $v}
    if [catch {set texte  [htg getnext]} v] then {error $v}
    set r [helem IMG "" SRC $source ALT $texte]
    return $r
}

proc htg_liste {} {
    if [catch {set arg [htg getnext]} v] then {error $v}
    # Bidouille pour éviter de mettre des <P> à l'extérieur des <LI>
    # On annule tous les sauts de paragraphe (qui sont hors des \item)
    # et on remplace tous les "marqueurs" (cf htg_item) par des sauts de
    # paragraphe
    regsub -all "\n\n+" $arg "" arg
    regsub -all "\r" $arg "\n\n" arg
    set r [helem UL $arg]
    return $r
}

proc htg_enumeration {} {
    if [catch {set arg [htg getnext]} v] then {error $v}
    # Même bidouille que dans htg_liste
    regsub -all "\n\n+" $arg "" arg
    regsub -all "\r" $arg "\n\n" arg
    set r [helem OL $arg]
    return $r
}

proc htg_item {} {
    if [catch {set arg [htg getnext]} v] then {error $v}
    # Bidouille pour éviter de mettre des <P> à l'extérieur des <LI>
    # On remplace tous les sauts de paragraphes par un caractère "marqueur"
    regsub -all "\n\n+" $arg "\r" arg
    set r [helem LI $arg]
    return $r
}

proc htg_titre {} {
    if [catch {set niveau [htg getnext]} v] then {error $v}
    check-int $niveau
    if [catch {set texte  [htg getnext]} v] then {error $v}

    set r [helem H$niveau $texte]
    return $r
}

proc htg_verbatim {} {
    if [catch {set texte  [htg getnext]} v] then {error $v}
    set r [helem PRE $texte]
    return $r
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
    return "<br>"
}

###############################################################################
# URLs et liens
###############################################################################

proc htg_lien {} {
    if [catch {set texte [htg getnext]} v] then {error $v}
    if [catch {set url   [htg getnext]} v] then {error $v}
    set r [helem A $texte HREF $url]
    return $r
}

proc htg_liensecurise {} {
    if [catch {set texte [htg getnext]} v] then {error $v}
    if [catch {set url   [htg getnext]} v] then {error $v}
    set r [helem A $texte CLASS auth HREF $url]
    return $r
}

proc htg_ancre {} {
    if [catch {set nom   [htg getnext]} v] then {error $v}
    if [catch {set texte [htg getnext]} v] then {error $v}
    set r [helem A $texte NAME $nom]
    return $r
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

proc htg_padding {} {
    if [catch {set padding [htg getnext]} v] then {error $v}
    return "CELLPADDING=$padding% "
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

    set c [string tolower $couleur]
    if {[info exists tabcouleurs($c)]} then {
	set couleur $tabcouleurs($c)
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
# Gestion des bandeaux
##############################################################################

proc htg_bandeau {} {
    global partie

    if [catch {set titre   [htg getnext]} v] then {error $v}
    if [catch {set contenu [htg getnext]} v] then {error $v}

    set titre [nettoyer-html $titre]
    regsub -all "\n" $titre "<br>" titre

    set partie(titrebandeau) $titre
    set partie(contenubandeau) $contenu

    return {}
}

proc htg_elementbandeau {} {
    global partie

    if [catch {set titre [htg getnext]} v] then {error $v}
    if [catch {set refs  [htg getnext]} v] then {error $v}

    set sousmenu "smenu" 
    if {[string length $titre] > 0} then {
	set id $partie(soustitre)
        incr partie(soustitre)

	set titre [helem DT $titre ONCLICK "javascript:developper($id);"]
	append sousmenu $id
    }

    set dd [helem DD [helem UL $refs] ID $sousmenu]

    return "$titre$dd"
}

proc htg_reference {} {
    if [catch {set texte [htg getnext]} v] then {error $v}
    set r [helem LI $texte]
    return $r
}

##############################################################################
# Gestion des contextes
##############################################################################

# à spécifier dans le fichier .htgt
proc htg_contexte {} {
    global ctxt

    if [catch {set valeur [htg getnext]} v] then {error $v}
    set ctxt $valeur
    return ""
}

# à spécifier dans le fond de page
proc htg_contextepardefaut {} {
    global ctxt

    if [catch {set valeur [htg getnext]} v] then {error $v}
    if {! [info exists ctxt]} then {
	set ctxt $valeur
    }
    return ""
}

# procédure utilitaire
proc dans-contexte {valeur} {
    global ctxt

    set r 0
    if {[info exists ctxt]} then {
	if {[lsearch $ctxt $valeur] != -1} then {
	    set r 1
	}
    }
    return $r
}

# à spécifier dans le fond de page
proc htg_sicontexte {} {
    if [catch {set valeur [htg getnext]} v] then {error $v}
    if [catch {set code   [htg getnext]} v] then {error $v}
    set r ""
    if {[dans-contexte $valeur]} then {
	set r $code
    }
    return $r
}

##############################################################################
# Gestion des tags "meta"
##############################################################################

proc htg_metarefresh {} {
    global partie

    if [catch {set temps [htg getnext]} v] then {error $v}
    append partie(meta) [helem META "" HTTP-EQUIV refresh CONTENT $temps]
    append partie(meta) [helem META "" HTTP-EQUIV pragma  CONTENT "no-cache"]
    append partie(meta) "\n"
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

# ceci doit être défini au début de la page pour indiquer les paramètres
# du flux RSS.
proc htg_rss {} {
    global partie

    if [catch {set titre [htg getnext]} v] then {error $v}
    if [catch {set lien  [htg getnext]} v] then {error $v}
    set titre [nettoyer-html $titre]
    regsub -all "\n\n+" $titre "<p>" titre
    set partie(rss) [helem LINK "" \
			    REL "alternate" TYPE "application/rss+xml" \
			    TITLE $titre HREF $lien \
			]
    return {}
}

proc htg_partie {} {
    global partie

    if [catch {set id [htg getnext]} v] then {error $v}
    if [catch {set texte [htg getnext]} v] then {error $v}
    set texte [nettoyer-html $texte]
    regsub -all "\n\n+" $texte "<p>" texte
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
