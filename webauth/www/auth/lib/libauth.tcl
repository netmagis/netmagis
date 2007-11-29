#
# Librairie TCL pour l'application de gestion de l'authentification.
#
# Historique
#   2003/05/30 : pda/jean : conception
#   2003/12/11 : pda      : simplification
#

##############################################################################
# Accès à la base
##############################################################################

#
# Initialiser l'application Web auth
#
# Entrée :
#   - paramètres :
#	- nologin : nom du fichier testé pour le mode "maintenance"
#	- auth : paramètres d'authentification
#	- pagerr : fichier HTML contenant une page d'erreur
#	- form : les paramètres du formulaire
#	- ftabvar : tableau contenant en retour les champs du formulaire
#	- loginvar : login de l'utilisateur, en retour
# Sortie :
#   - valeur de retour : aucune
#   - paramètres :
#	- ftabvar : cf ci-dessus
#	- loginvar : cf ci-dessus
#
# Historique
#   2001/06/18 : pda      : conception
#   2002/12/26 : pda      : actualisation et mise en service
#   2003/05/13 : pda/jean : intégration dans dns et utilisation de auth
#   2003/05/30 : pda/jean : réutilisation pour l'application auth
#   2003/06/04 : pda/jean : simplification
#

proc init-auth {nologin auth pagerr form ftabvar loginvar} {
    upvar $ftabvar ftab
    upvar $loginvar login

    #
    # Pour le cas où on est en mode maintenance
    #

    ::webapp::nologin $nologin %ROOT% $pagerr

    #
    # Accès à la base d'authentification
    #

    set msg [::auth::init $auth]
    if {! [string equal $msg ""]} then {
	::webapp::error-exit $pagerr $msg
    }

    #
    # Le login de l'utilisateur (la page est protégée par mot de passe)
    #

    set login [::webapp::user]
    if {[string compare $login ""] == 0} then {
	::webapp::error-exit $pagerr \
		"Pas de login : l'authentification a échoué."
    }

    #
    # Récupération des paramètres du formulaire
    #

    if {[string length $form] > 0} then {
	if {[llength [::webapp::get-data ftab $form]] == 0} then {
	    ::webapp::error-exit $pagerr \
		"Formulaire non conforme aux spécifications"
	}
    }

    return
}
