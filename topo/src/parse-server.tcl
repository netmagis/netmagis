#
#
# Package d'analyse de fichiers de pseudo-configuration IOS
# pour les serveurs
#
# Historique
#   2011/04/05 : jean      : creation
#

###############################################################################
# Analyse du fichier de configuration
###############################################################################

#
# Entrée :
#   - libdir : répertoire contenant les greffons d'analyse
#   - model : modèle de l'équipement (ex: M20)
#   - fdin : descripteur de fichier en entrée
#   - fdout : fichier de sortie pour la génération
#   - eq = <eqname>
# Remplit :
#   - tab(eq)	{<eqname> ... <eqname>}
#   - tab(eq!ios) "unsure|router|switch"
#
# Historique
#   2011/04/05 : jean : conception
#

proc server-parse {libdir model fdin fdout tab eq} {
    upvar $tab t

    set error [charger $libdir "parse-cisco.tcl"]
    if {! $error} then {
        set error [cisco-parse $libdir $model $fdin $fdout t $eq]
    }

    return $error
}
