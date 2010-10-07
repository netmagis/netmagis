#
# Librairie TCL pour l'application de gestion DNS.
#
# $Id: libdns.tcl,v 1.15 2008-09-24 07:33:51 pda Exp $
#
# Historique
#   2002/03/27 : pda/jean : conception
#   2002/05/23 : pda/jean : ajout de info-groupe
#   2004/01/14 : pda/jean : ajout IPv6
#   2004/08/04 : pda/jean : ajout MAC
#   2004/08/06 : pda/jean : extension des droits sur les réseaux
#   2006/01/26 : jean     : correction dans valide-droit-nom (cas ip EXIST)
#   2006/01/30 : jean     : message alias dans valide-droit-nom
#

# set debug(base)	dbname=dns-debug
# set debug(mail)	{pda@crc.u-strasbg.fr}

##############################################################################
# Paramètres de la librairie
##############################################################################

set libconf(tabdroits) {
    global {
	chars {12 normal}
	align {left}
	botbar {yes}
	columns {75 25}
    }
    pattern DROIT {
	vbar {yes}
	column { }
	vbar {yes}
	column { }
	vbar {yes}
    }
}

set libconf(tabreseaux) {
    global {
	chars {12 normal}
	align {left}
	botbar {yes}
	columns {15 35 15 35}
    }
    pattern Reseau {
	vbar {yes}
	column {
	    align {center}
	    chars {14 bold}
	    multicolumn {4}
	}
	vbar {yes}
    }
    pattern Normal4 {
	vbar {yes}
	column { }
	vbar {yes}
	column {
	    chars {bold}
	}
	vbar {yes}
	column { }
	vbar {yes}
	column {
	    chars {bold}
	}
	vbar {yes}
    }
    pattern Droits {
	vbar {yes}
	column { }
	vbar {yes}
	column {
	    multicolumn {3}
	    chars {bold}
	    format {lines}
	}
	vbar {yes}
    }
}

set libconf(tabdomaines) {
    global {
	chars {12 normal}
	align {left}
	botbar {yes}
	columns {50 25 25}
    }
    pattern Domaine {
	vbar {yes}
	column { }
	vbar {no}
	column { }
	vbar {no}
	column { }
	vbar {yes}
    }
}

set libconf(tabdhcpprofil) {
    global {
	chars {12 normal}
	align {left}
	botbar {yes}
	columns {25 75}
    }
    pattern DHCP {
	vbar {yes}
	column { }
	vbar {no}
	column {
	    format {lines}
	}
	vbar {yes}
    }
}

set libconf(tabmachine) {
    global {
	chars {10 normal}
	align {left}
	botbar {yes}
	columns {20 80}
    }
    pattern Normal {
	vbar {yes}
	column { }
	vbar {yes}
	column { }
	vbar {yes}
    }
}

set libconf(tabcorresp) {
    global {
	chars {10 normal}
	align {left}
	botbar {yes}
	columns {20 80}
    }
    pattern Normal {
	vbar {yes}
	column { }
	vbar {yes}
	column {
	    chars {gras}
	}
	vbar {yes}
    }
}

##############################################################################
# Cosmétique
##############################################################################

#
# Formatte une chaîne de telle manière qu'elle apparaisse bien dans
# une case de tableau
#
# Entrée :
#   - paramètres :
#	- string : chaîne
# Sortie :
#   - valeur de retour : la même chaîne, avec "&nbsp;" si vide
#
# Historique
#   2002/05/23 : pda     : conception
#

proc html-tab-string {string} {
    set v [::webapp::html-string $string]
    if {[string equal [string trim $v] ""]} then {
	set v "&nbsp;"
    }
    return $v
}

#
# Affiche toutes les caractéristiques d'un correspondant dans un tableau HTML.
#
# Entrée :
#   - paramètres :
#	- tabcor : tableau contenant les attributs du correspondant
#   - variables globales :
#	- libconf(tabcorresp) : spécification du tableau utilisé
# Sortie :
#   - valeur de retour : tableau html prêt à l'emploi
#
# Historique
#   2002/07/25 : pda      : conception
#   2003/05/13 : pda/jean : utilisation de tabcor
#

proc html-correspondant {tabcorvar} {
    global libconf
    upvar $tabcorvar tabcor

    set donnees {}

    lappend donnees [list Normal Correspondant	"$tabcor(nom) $tabcor(prenom)"]
    lappend donnees [list Normal Login		$tabcor(login)]
    lappend donnees [list Normal Mél		$tabcor(mel)]
    lappend donnees [list Normal "Tél fixe"	$tabcor(tel)]
    lappend donnees [list Normal "Tél mobile"	$tabcor(mobile)]
    lappend donnees [list Normal "Fax"		$tabcor(fax)]
    lappend donnees [list Normal Localisation	$tabcor(adr)]

    return [::arrgen::output "html" $libconf(tabcorresp) $donnees]
}

##############################################################################
# Accès à la base
##############################################################################

#
# Initie l'accès à la base
#
# Entrée :
#   - paramètres :
#	- base : informations de connexion à la base
#	- varmsg : message d'erreur lors de l'écriture, si besoin
#   - variables globales :
#	- debug(base) : si la variable existe, elle doit contenir le
#		nom d'une base qui sera utilisée pour tous les accès
# Sortie :
#   - valeur de retour : accès à la base
#
# Historique
#   2001/01/27 : pda     : conception
#   2001/10/09 : pda     : utilisation de conninfo pour accès via passwd
#

proc ouvrir-base {base varmsg} {
    upvar $varmsg msg
    global debug

    #
    # On ne sait jamais... Intercepter la lecture éventuellement.
    #

    if {[info exists debug(base)]} then {
	set base $debug(base)
    }

    if {[catch {set dbfd [pg_connect -conninfo $base]} msg]} then {
	set dbfd ""
    }

    return $dbfd
}

#
# Clôt l'accès à la base
#
# Entrée :
#   - paramètres :
#	- dbfd : accès à la base
# Sortie :
#   - valeur de retour : aucune
#
# Historique
#   2001/01/27 : pda     : conception
#

proc fermer-base {dbfd} {
    pg_disconnect $dbfd
}

#
# Initialiser l'accès à DNS pour les scripts CGI
#
# Entrée :
#   - paramètres :
#	- nologin : nom du fichier testé pour le mode "maintenance"
#	- auth : paramètres d'authentification
#	- base : nom de la base
#	- pageerr : fichier HTML contenant une page d'erreur
#	- attr : attribut nécessaire pour exécuter le script (XXX : un seul attr)
#	- form : les paramètres du formulaire
#	- ftabvar : tableau contenant en retour les champs du formulaire
#	- dbfdvar : accès à la base en retour
#	- loginvar : login de l'utilisateur, en retour
#	- tabcorvar : tableau contenant les caractéristiques de l'utilisateur
#		(login, password, nom, prenom, mel, tel, fax, mobile, adr,
#			idcor, idgrp, present)
#	- logparam : paramètres de log (subsys, méthode, paramètres de la méth)
# Sortie :
#   - valeur de retour : aucune
#   - paramètres :
#	- ftabvar : cf ci-dessus
#	- dbfdvar : cf ci-dessus
#	- loginvar : cf ci-dessus
#	- tabcorvar : cf ci-dessus
#
# Historique
#   2001/06/18 : pda      : conception
#   2002/12/26 : pda      : actualisation et mise en service
#   2003/05/13 : pda/jean : intégration dans dns et utilisation de auth
#   2007/10/05 : pda/jean : adaptation aux objets "authuser" et "authbase"
#   2007/10/26 : jean     : ajout du log
#

proc init-dns {nologin auth base pageerr attr form ftabvar dbfdvar loginvar tabcorvar logparam} {
    global ah
    global log
    upvar $ftabvar ftab
    upvar $dbfdvar dbfd
    upvar $loginvar login
    upvar $tabcorvar tabcor

    #
    # Pour le cas où on est en mode maintenance
    #

    ::webapp::nologin $nologin %ROOT% $pageerr

    #
    # Accès à la base d'authentification
    #

    set ah [::webapp::authbase create %AUTO%]
    $ah configurelist $auth

    #
    # Accès à la base
    #

    set dbfd [ouvrir-base $base msg]
    if {[string length $dbfd] == 0} then {
	::webapp::error-exit $pageerr $msg
    }

    #
    # Initialisation du log
    #

    set logsubsys [lindex $logparam 0]
    set logmethod [lindex $logparam 1]
    set logmedium [lindex $logparam 2]
    set log [::webapp::log create %AUTO% -subsys $logsubsys -method $logmethod -medium $logmedium]

    #
    # Le login de l'utilisateur (la page est protégée par mot de passe)
    #

    set login [::webapp::user]
    if {[string compare $login ""] == 0} then {
	::webapp::error-exit $pageerr \
		"Pas de login : l'authentification a échoué."
    }

    #
    # Lire toutes les caractéristiques du correspondant
    #

    set msg [lire-correspondant-par-login $dbfd $login tabcor]
    if {! [string equal $msg ""]} then {
	::webapp::error-exit $pageerr $msg
    }

    #
    # Si le correspondant n'est plus marqué comme "présent" dans la base,
    # on ne lui autorise pas l'accès à l'application
    #

    if {! $tabcor(present)} then {
	::webapp::error-exit $pageerr \
	    "Désolé, $tabcor(prenom) $tabcor(nom), mais vous n'êtes pas habilité."
    }

    #
    # Page accessible seulement en mode "admin"
    #

    if {[llength $attr] > 0} then {
	#
	# XXX : pour l'instant, test d'un seul attribut seulement
	#

	if {! [attribut-correspondant $dbfd $tabcor(idcor) $attr]} then {
	    ::webapp::error-exit $pageerr \
		"Désolé,  $login, mais vous n'avez pas les droits suffisants"
	}
    }

    #
    # Récupération des paramètres du formulaire
    #

    if {[string length $form] > 0} then {
	if {[llength [::webapp::get-data ftab $form]] == 0} then {
	    ::webapp::error-exit $pageerr \
		"Formulaire non conforme aux spécifications"
	}
    }
}

#
# Initialiser l'accès à DNS pour les scripts "batch"
#
# Entrée :
#   - paramètres :
#	- nologin : nom du fichier testé pour le mode "maintenance"
#	- auth : paramètres d'authentification
#	- base : nom de la base
#	- dbfdvar : accès à la base en retour
#	- login : login de l'utilisateur
#	- tabcorvar : tableau contenant les caractéristiques de l'utilisateur
#		(login, password, nom, prenom, mel, tel, fax, mobile, adr,
#			idcor, idgrp, present)
#	- logparam : paramètres de log (subsys, méthode, paramètres de la méth)
# Sortie :
#   - valeur de retour : message d'erreur, ou chaîne vide si pas d'erreur
#   - paramètres :
#	- dbfdvar : cf ci-dessus
#	- tabcorvar : cf ci-dessus
#
# Historique
#   2004/09/24 : pda/jean : conception
#   2007/10/05 : pda/jean : adaptation aux objets "authuser" et "authbase"
#   2007/10/26 : jean     : ajout du log
#

proc init-dns-util {nologin auth base dbfdvar login tabcorvar logparam} {
    global ah
    global log
    upvar $dbfdvar dbfd
    upvar $tabcorvar tabcor

    #
    # Pour le cas où on est en mode maintenance
    #

    if {[file exists $nologin]} then {
	set fd [open $nologin r]
	set message [read $fd]
	close $fd
	return "Connexion refusée.\n$message"
    }

    #
    # Accès à la base d'authentification
    #

    set ah [::webapp::authbase create %AUTO%]
    $ah configurelist $auth

    #
    # Accès à la base
    #

    set dbfd [ouvrir-base $base msg]
    if {[string length $dbfd] == 0} then {
	return "Accès à la base DNS impossible\n$msg"
    }

    #
    # Initialisation du log
    #

    set logsubsys [lindex $logparam 0]
    set logmethod [lindex $logparam 1]
    set logmedium [lindex $logparam 2]
    set log [::webapp::log create %AUTO% -subsys $logsubsys -method $logmethod -medium $logmedium]

    #
    # Lire toutes les caractéristiques du correspondant
    #

    set msg [lire-correspondant-par-login $dbfd $login tabcor]
    if {! [string equal $msg ""]} then {
	return "Utilisateur '$login' : $msg"
    }

    #
    # Si le correspondant n'est plus marqué comme "présent" dans la base,
    # on ne lui autorise pas l'accès à l'application
    #

    if {! $tabcor(present)} then {
	return "Utilisateur '$login' non présent"
    }

    return ""
}

# 
# Écrire une ligne dans le système de log
# 
# Entrée :
#   - paramètres :
#	- evenement : nom de l'evenement (exemples : supprhost, suppralias etc.)
#	- login     : identifiant du correspondant effectuant l'action
#	- message   : message de log (par exemple les parametres de l'evenement)
#
# Sortie :
#   rien
#
# Historique :
#   2007/10/?? : jean : conception
#

proc writelog {evenement login msg} {
    global log
    global env

    if {[info exists env(REMOTE_ADDR) ]} then {
	set ip $env(REMOTE_ADDR)    
    } else {
	set ip ""
    }

    $log log "" $evenement $login $ip $msg
    
}

##############################################################################
# Gestion des droits des correspondants
##############################################################################

#
# Procédure de recherche d'attribut associé à un correspondant
#
# Entrée :
#   - paramètres :
#	- dbfd : accès à la base contenant les tickets
#	- idcor : correspondant
#	- attribut : attribut à vérifier (colonne de la table pour l'instant)
# Sortie :
#   - valeur de retour : l'information trouvée
#
# Historique
#   2000/07/26 : pda      : conception
#   2001/01/16 : pda/cty  : conception
#   2002/05/03 : pda/jean : récupération pour dns
#   2002/05/06 : pda/jean : utilisation des groupes
#

proc attribut-correspondant {dbfd idcor attribut} {
    set v 0
    set sql "SELECT groupe.$attribut \
			FROM groupe, corresp \
			WHERE corresp.idcor = $idcor \
			    AND corresp.idgrp = groupe.idgrp"
    pg_select $dbfd $sql tab {
	set v "$tab($attribut)"
    }
    return $v
}

#
# Lecture des attributs associés à un correspondant
#
# Entrée :
#   - paramètres :
#	- dbfd : accès à la base contenant les tickets
#	- login : le login du correspondant
#	- tabcorvar : tableau des attributs du correspondant (en retour)
# Sortie :
#   - valeur de retour : message d'erreur ou chaîne vide
#   - paramètre tabcorvar : les attributs en retour
#
# Historique
#   2003/05/13 : pda/jean : conception
#   2007/10/05 : pda/jean : adaptation aux objets "authuser" et "authbase"
#

proc lire-correspondant-par-login {dbfd login tabcorvar} {
    global ah
    upvar $tabcorvar tabcor

    catch {unset tabcor}

    #
    # Lire les caractéristiques communes à toutes les applications
    #

    set u [::webapp::authuser create %AUTO%]
    if {[catch {set n [$ah getuser $login $u]} m]} then {
	return "Problème dans la base d'authentification ($m)"
    }
    
    switch $n {
	0 {
	    return "'$login' n'est pas dans la base d'authentification."
	}
	1 { 
	    # Rien
	}
	default {
	    return "Trop d'utilisateurs trouvés"
	}
    }

    foreach c {login password nom prenom mel tel mobile fax adr} {
	set tabcor($c) [$u get $c]
    }

    $u destroy

    #
    # Lire les autres caractéristiques, propres à cette application.
    #

    set qlogin [::pgsql::quote $login]
    set tabcor(idcor) -1
    set sql "SELECT * FROM corresp, groupe
			WHERE corresp.login = '$qlogin'
			    AND corresp.idgrp = groupe.idgrp"
    pg_select $dbfd $sql tab {
	set tabcor(idcor)	$tab(idcor)
	set tabcor(idgrp)	$tab(idgrp)
	set tabcor(present)	$tab(present)
	set tabcor(groupe)	$tab(nom)
	set tabcor(admin)	$tab(admin)
    }

    if {$tabcor(idcor) == -1} then {
	return "'$login' n'est pas dans la base des correspondants."
    }

    return ""
}

proc lire-correspondant-par-id {dbfd idcor tabcorvar} {
    global ah
    upvar $tabcorvar tabcor

    catch {unset tabcor}

    #
    # Lire les caractéristiques, propres à cette application.
    #

    set tabcor(idcor) -1
    set sql "SELECT * FROM corresp, groupe
			WHERE corresp.idcor = $idcor
			    AND corresp.idgrp = groupe.idgrp"
    pg_select $dbfd $sql tab {
	set tabcor(login)	$tab(login)
	set tabcor(idcor)	$tab(idcor)
	set tabcor(idgrp)	$tab(idgrp)
	set tabcor(present)	$tab(present)
	set tabcor(groupe)	$tab(nom)
	set tabcor(admin)	$tab(admin)
    }

    if {$tabcor(idcor) == -1} then {
	return "Le correspondant d'id $idcor n'est pas dans la base des correspondants."
    }

    #
    # Lire les caractéristiques communes à toutes les applications
    #

    set u [::webapp::authuser create %AUTO%]
    if {[catch {set n [$ah getuser $tabcor(login) $u]} m]} then {
	return "Problème dans la base d'authentification ($m)"
    }
    
    switch $n {
	0 {
	    return "'$tabcor(login)' n'est pas dans la base d'authentification."
	}
	1 { 
	    # Rien
	}
	default {
	    return "Trop d'utilisateurs trouvés"
	}
    }

    foreach c {login password nom prenom mel tel mobile fax adr} {
	set tabcor($c) [$u get $c]
    }

    $u destroy

    return ""
}

##############################################################################
# Gestion des RR dans la base
##############################################################################

#
# Récupère toutes les informations associées à un nom
#
# Entrée :
#   - paramètres :
#	- dbfd : accès la base
#	- nom : le nom à chercher
#	- iddom : le domaine
#	- tabrr : tableau vide
# Sortie :
#   - valeur de retour : 1 si ok, 0 si non trouvé
#   - paramètre tabrr : voir lire-rr-par-id
#
# Historique
#   2002/04/11 : pda/jean : conception
#   2002/04/19 : pda/jean : ajout de nom et domaine
#   2002/04/19 : pda/jean : utilisation de lire-rr-par-id
#

proc lire-rr-par-nom {dbfd nom iddom tabrr} {
    upvar $tabrr trr

    set qnom [::pgsql::quote $nom]
    set trouve 0
    set sql "SELECT idrr FROM rr WHERE nom = '$qnom' AND iddom = $iddom"
    pg_select $dbfd $sql tab {
	set trouve 1
	set idrr $tab(idrr)
    }

    if {$trouve} then {
	set trouve [lire-rr-par-id $dbfd $idrr trr]
    }

    return $trouve
}

#
# Récupère toutes les informations associées au rr d'adresse IP donnée
#
# Entrée :
#   - paramètres :
#	- dbfd : accès la base
#	- adr : l'adresse à chercher
#	- tabrr : tableau vide
# Sortie :
#   - valeur de retour : 1 si ok, 0 si non trouvé
#   - paramètre tabrr : voir lire-rr-par-id
#
# Note : on suppose que l'adresse fournie est syntaxiquement valide
#
# Historique
#   2002/04/26 : pda/jean : conception
#

proc lire-rr-par-ip {dbfd adr tabrr} {
    upvar $tabrr trr

    set trouve 0
    set sql "SELECT idrr FROM rr_ip WHERE adr = '$adr'"
    pg_select $dbfd $sql tab {
	set trouve 1
	set idrr $tab(idrr)
    }

    if {$trouve} then {
	set trouve [lire-rr-par-id $dbfd $idrr trr]
    }

    return $trouve
}

#
# Récupère toutes les informations associées à un RR
#
# Entrée :
#   - paramètres :
#	- dbfd : accès la base
#	- idrr : l'id du rr à chercher
#	- tabrr : tableau vide
# Sortie :
#   - valeur de retour : 1 si ok, 0 si non trouvé
#   - paramètre tabrr :
#	tabrr(idrr) : l'id de l'objet trouvé (idrr)
#	tabrr(nom) : nom de la machine (un seul composant du fqdn)
#	tabrr(iddom) : l'id du domaine
#	tabrr(domaine) : nom du domaine
#	tabrr(mac) : l'adresse mac de la machine
#	tabrr(iddhcpprofil) : le profil DHCP sous forme d'id, ou 0
#	tabrr(dhcpprofil) : le nom du profil DHCP, ou "Aucun profil DHCP"
#	tabrr(idhinfo) : le type de machine sous forme d'id
#	tabrr(hinfo) : le type de machine sous forme de texte
#	tabrr(droitsmtp) : la machine a le droit d'émission SMTP non authentifié
#	tabrr(commentaire) : les infos complémentaires sous forme de texte
#	tabrr(respnom) : le nom+prénom du responsable
#	tabrr(respmel) : le mél du responsable
#	tabrr(idcor) : l'id du correspondant ayant fait la dernière modif
#	tabrr(date) : date de la dernière modif
#	tabrr(ip) : les adresses IP sous forme de liste
#	tabrr(mx) : le ou les mx sous la forme {{prio idrr} {prio idrr} ...}
#	tabrr(cname) : l'id de l'objet pointé, si le nom est un alias
#	tabrr(aliases) : les idrr des objets pointant vers cet objet
#	tabrr(rolemail) : l'idrr de l'hébergeur éventuel
#	tabrr(adrmail) : les idrr des adresses de messagerie hébergées
#	tabrr(roleweb) : 1 si role web pour ce rr
#
# Historique
#   2002/04/19 : pda/jean : conception
#   2002/06/02 : pda/jean : hinfo devient un index dans une table
#   2004/02/06 : pda/jean : ajout de rolemail, adrmail et roleweb
#   2004/08/05 : pda/jean : legere simplification et ajout de mac
#   2005/04/08 : pda/jean : ajout de dhcpprofil
#   2008/07/24 : pda/jean : ajout de droitsmtp
#

proc lire-rr-par-id {dbfd idrr tabrr} {
    upvar $tabrr trr

    set fields {nom iddom
	mac iddhcpprofil idhinfo droitsmtp commentaire respnom respmel
	idcor date}

    catch {unset trr}
    set trr(idrr) $idrr

    set trouve 0
    set columns [join $fields ", "]
    set sql "SELECT $columns FROM rr WHERE idrr = $idrr"
    pg_select $dbfd $sql tab {
	set trouve 1
	foreach v $fields {
	    set trr($v) $tab($v)
	}
    }

    if {$trouve} then {
	set trr(domaine) ""
	if {[string equal $trr(iddhcpprofil) ""]} then {
	    set trr(iddhcpprofil) 0
	    set trr(dhcpprofil) "Aucun profil"
	} else {
	    set sql "SELECT nom FROM dhcpprofil
				WHERE iddhcpprofil = $trr(iddhcpprofil)"
	    pg_select $dbfd $sql tab {
		set trr(dhcpprofil) $tab(nom)
	    }
	}
	set sql "SELECT texte FROM hinfo WHERE idhinfo = $trr(idhinfo)"
	pg_select $dbfd $sql tab {
	    set trr(hinfo) $tab(texte)
	}
	set sql "SELECT nom FROM domaine WHERE iddom = $trr(iddom)"
	pg_select $dbfd $sql tab {
	    set trr(domaine) $tab(nom)
	}
	set trr(ip) {}
	pg_select $dbfd "SELECT adr FROM rr_ip WHERE idrr = $idrr" tab {
	    lappend trr(ip) $tab(adr)
	}
	set trr(mx) {}
	pg_select $dbfd "SELECT priorite,mx FROM rr_mx WHERE idrr = $idrr" tab {
	    lappend trr(mx) [list $tab(priorite) $tab(mx)]
	}
	set trr(cname) ""
	pg_select $dbfd "SELECT cname FROM rr_cname WHERE idrr = $idrr" tab {
	    set trr(cname) $tab(cname)
	}
	set trr(aliases) {}
	pg_select $dbfd "SELECT idrr FROM rr_cname WHERE cname = $idrr" tab {
	    lappend trr(aliases) $tab(idrr)
	}
	set trr(rolemail) ""
	pg_select $dbfd "SELECT heberg FROM role_mail WHERE idrr = $idrr" tab {
	    set trr(rolemail) $tab(heberg)
	}
	set trr(adrmail) {}
	pg_select $dbfd "SELECT idrr FROM role_mail WHERE heberg = $idrr" tab {
	    lappend trr(adrmail) $tab(idrr)
	}
	set trr(roleweb) 0
	pg_select $dbfd "SELECT 1 FROM role_web WHERE idrr = $idrr" tab {
	    set trr(roleweb) 1
	}
    }

    return $trouve
}

#
# Détruit un RR étant donné son id
#
# Entrée :
#   - paramètres :
#	- dbfd : accès la base
#	- idrr : l'id du rr à détruire
#	- msg : variable contenant en retour le message d'erreur
# Sortie :
#   - valeur de retour : 1 si ok, 0 si erreur
#   - paramètre msg : le contenu du message d'erreur si besoin
#
# Historique
#   2002/04/19 : pda/jean : conception
#

proc supprimer-rr-par-id {dbfd idrr msg} {
    upvar $msg m

    set sql "DELETE FROM rr WHERE idrr = $idrr"
    return [::pgsql::execsql $dbfd $sql m]
}

#
# Supprime un alias
#
# Entrée :
#   - paramètres :
#	- dbfd : accès la base
#	- idrr : l'id du rr à détruire, correspondant au nom de l'alias
#	- msg : variable contenant en retour le message d'erreur
# Sortie :
#   - valeur de retour : 1 si ok, 0 si erreur
#   - paramètre msg : le contenu du message d'erreur si besoin
#
# Historique
#   2002/04/19 : pda/jean : conception
#

proc supprimer-alias-par-id {dbfd idrr msg} {
    upvar $msg m

    set ok 0
    set sql "DELETE FROM rr_cname WHERE idrr = $idrr"
    if {[::pgsql::execsql $dbfd $sql m]} then {
	if {[supprimer-rr-par-id $dbfd $idrr m]} then {
	    set ok 1
	}
    }
    return $ok
}

#
# Supprime une adresse IP
#
# Entrée :
#   - paramètres :
#	- dbfd : accès la base
#	- idrr : l'id du rr à détruire
#	- adr : l'adresse IPv4 à supprimer
#	- msg : variable contenant en retour le message d'erreur
# Sortie :
#   - valeur de retour : 1 si ok, 0 si erreur
#   - paramètre msg : le contenu du message d'erreur si besoin
#
# Historique
#   2002/04/19 : pda/jean : conception
#

proc supprimer-ip-par-adresse {dbfd idrr adr msg} {
    upvar $msg m

    set ok 0
    set sql "DELETE FROM rr_ip WHERE idrr = $idrr AND adr = '$adr'"
    if {[::pgsql::execsql $dbfd $sql m]} then {
	set ok 1
    }
    return $ok
}

#
# Supprime tous les MX associés à un RR
#
# Entrée :
#   - paramètres :
#	- dbfd : accès la base
#	- idrr : l'id du rr des MX à détruire
#	- msg : variable contenant en retour le message d'erreur
# Sortie :
#   - valeur de retour : 1 si ok, 0 si erreur
#   - paramètre msg : le contenu du message d'erreur si besoin
#
# Historique
#   2002/04/19 : pda/jean : conception
#

proc supprimer-mx-par-id {dbfd idrr msg} {
    upvar $msg m

    set ok 0
    set sql "DELETE FROM rr_mx WHERE idrr = $idrr"
    if {[::pgsql::execsql $dbfd $sql m]} then {
	set ok 1
    }
    return $ok
}

#
# Supprime un role mail
#
# Entrée :
#   - paramètres :
#	- dbfd : accès la base
#	- idrr : l'id du rr des MX à détruire
#	- msg : variable contenant en retour le message d'erreur
# Sortie :
#   - valeur de retour : 1 si ok, 0 si erreur
#   - paramètre msg : le contenu du message d'erreur si besoin
#
# Historique
#   2004/02/06 : pda/jean : conception
#

proc supprimer-rolemail-par-id {dbfd idrr msg} {
    upvar $msg m

    set ok 0
    set sql "DELETE FROM role_mail WHERE idrr = $idrr"
    if {[::pgsql::execsql $dbfd $sql m]} then {
	set ok 1
    }
    return $ok
}

#
# Supprime un role web
#
# Entrée :
#   - paramètres :
#	- dbfd : accès la base
#	- idrr : l'id du rr des MX à détruire
#	- msg : variable contenant en retour le message d'erreur
# Sortie :
#   - valeur de retour : 1 si ok, 0 si erreur
#   - paramètre msg : le contenu du message d'erreur si besoin
#
# Historique
#   2004/02/06 : pda/jean : conception
#

proc supprimer-roleweb-par-id {dbfd idrr msg} {
    upvar $msg m

    set ok 0
    set sql "DELETE FROM role_web WHERE idrr = $idrr"
    if {[::pgsql::execsql $dbfd $sql m]} then {
	set ok 1
    }
    return $ok
}

#
# Supprime un RR et toutes ses dépendances
#
# Entrée :
#   - paramètres :
#	- dbfd : accès la base
#	- tabrr : infos du RR (cf lire-rr-par-id)
#	- msg : variable contenant en retour le message d'erreur
# Sortie :
#   - valeur de retour : 1 si ok, 0 si erreur
#   - paramètre msg : le contenu du message d'erreur si besoin
#
# Historique
#   2002/04/19 : pda/jean : conception
#   2004/02/06 : pda/jean : ajout des roles de messagerie et web
#

proc supprimer-rr-et-dependances {dbfd tabrr msg} {
    upvar $tabrr trr
    upvar $msg m

    set idrr $trr(idrr)

    #
    # S'il y a des adresses de messagerie hébergées, empêcher la
    # suppression
    #

    if {[llength $trr(adrmail)] > 0} then {
	set m "Cette machine héberge des adresses de messagerie"
	return 0
    }

    #
    # Supprimer les rôles éventuels concernant la *machine*
    # (et non les noms qui correspondent à autre chose, comme les
    # adresses de messagerie).
    #

    if {! [supprimer-roleweb-par-id $dbfd $idrr m]} then {
	return 0
    }

    #
    # Supprimer tous les aliases pointant vers cet objet
    #

    foreach a $trr(aliases) {
	if {! [supprimer-alias-par-id $dbfd $a m]} then {
	    return 0
	}
    }

    #
    # Supprimer toutes les adresses IP
    #

    foreach a $trr(ip) {
	if {! [supprimer-ip-par-adresse $dbfd $idrr $a m]} then {
	    return 0
	}
    }

    #
    # Supprimer tous les MX
    #

    if {! [supprimer-mx-par-id $dbfd $idrr m]} then {
	return 0
    }

    #
    # Supprimer enfin le RR lui-même (si possible)
    #

    set m [supprimer-rr-si-orphelin $dbfd $idrr]
    if {! [string equal $m ""]} then {
	return 0
    }

    #
    # Fini !
    #

    return 1
}

#
# Supprimer un RR s'il n'y a plus rien qui pointe dessus (adresse IP,
# alias, rôle de messagerie, etc.)
#
# Entrée :
#   - paramètres :
#	- dbfd : accès à la base
#	- idrr : id du RR à supprimer
# Sortie :
#   - valeur de retour : chaîne vide (ok) ou non vide (message d'erreur)
#
# Note : si le RR n'est pas orphelin, le RR n'est pas supprimé et la
#	chaîne vide est renvoyé (c'est un cas "normal, pas une erreur).
#
# Historique
#   2004/02/13 : pda/jean : conception
#

proc supprimer-rr-si-orphelin {dbfd idrr} {
    set msg ""
    if {[lire-rr-par-id $dbfd $idrr trr]} then {
	set orphelin 1
	foreach x {ip mx aliases rolemail adrmail} {
	    if {! [string equal $trr($x) ""]} then {
		set orphelin 0
		break
	    }
	}
	if {$orphelin && $trr(roleweb)} then {
	    set orphelin 0
	}

	if {$orphelin} then {
	    if {[supprimer-rr-par-id $dbfd $trr(idrr) msg]} then {
		# ça a marché, mais la fonction a pu éventuellement
		# modifier "msg"
		set msg ""
	    }
	}
    }
    return $msg
}

#
# Ajouter un nouveau RR
#
# Entrée :
#   - paramètres :
#	- dbfd : accès à la base
#	- nom : nom du RR à créer (la syntaxe doit être déjà conforme à la RFC)
#	- iddom : id du domaine du RR
#	- mac : adresse MAC, ou vide
#	- iddhcpprofil : id du profil DHCP, ou 0
#	- idhinfo : HINFO ou chaîne vide (le défaut est pris dans la base)
#	- droitsmtp : 1 si droit d'émettre en SMTP non authentifié, ou 0
#	- comment : les infos complémentaires sous forme de texte
#	- respnom : le nom+prénom du responsable
#	- respmel : le mél du responsable
#	- idcor : l'index du correspondant
#	- tabrr : contiendra en retour les informations du RR créé
# Sortie :
#   - valeur de retour : chaîne vide (ok) ou non vide (message d'erreur)
#   - paramètre tabrr : voir lire-rr-par-id
#
# Attention : on suppose que la syntaxe du nom est valide. Ne pas oublier
#   d'appeler "syntaxe-nom" avant cette fonction.
#
# Historique
#   2004/02/13 : pda/jean : conception
#   2004/08/05 : pda/jean : ajout mac
#   2004/10/05 : pda      : changement du format de date
#   2005/04/08 : pda/jean : ajout dhcpprofil
#   2008/07/24 : pda/jean : ajout droitsmtp
#

proc ajouter-rr {dbfd nom iddom mac iddhcpprofil idhinfo droitsmtp
				comment respnom respmel idcor tabrr} {
    upvar $tabrr trr

    if {[string equal $mac ""]} then {
	set qmac NULL
    } else {
	set qmac "'[::pgsql::quote $mac]'"
    }
    set qcomment [::pgsql::quote $comment]
    set qrespnom [::pgsql::quote $respnom]
    set qrespmel [::pgsql::quote $respmel]
    set hinfodef ""
    set hinfoval ""
    if {! [string equal $idhinfo ""]} then {
	set hinfodef "idhinfo,"
	set hinfoval "$idhinfo, "
    }
    if {$iddhcpprofil == 0} then {
	set iddhcpprofil NULL
    }
    set sql "INSERT INTO rr
		    (nom, iddom,
			mac,
			iddhcpprofil,
			$hinfodef
			droitsmtp, commentaire, respnom, respmel,
			idcor)
		VALUES
		    ('$nom', $iddom,
			$qmac,
			$iddhcpprofil,
			$hinfoval
			$droitsmtp, '$qcomment', '$qrespnom', '$qrespmel',
			$idcor)
		    "
    if {[::pgsql::execsql $dbfd $sql msg]} then {
	set msg ""

	if {! [lire-rr-par-nom $dbfd $nom $iddom trr]} then {
	    set msg "Erreur interne : '$nom' inséré, mais non retrouvé dans la base"
	}
    } else {
	set msg "Création du RR impossible : $msg"
    }
    return $msg
}

#
# Met à jour la date et l'id du correspondant qui a modifié le RR
#
# Entrée :
#   - paramètres :
#	- dbfd : accès à la base
#	- idrr : l'index du RR
#	- idcor : l'index du correspondant
# Sortie :
#   - valeur de retour : chaîne vide (ok) ou non vide (message d'erreur)
#
# Historique
#   2002/05/03 : pda/jean : conception
#   2004/10/05 : pda      : changement du format de date
#

proc touch-rr {dbfd idrr idcor} {
    set date [clock format [clock seconds]]
    set sql "UPDATE rr SET idcor = $idcor, date = '$date' WHERE idrr = $idrr"
    if {[::pgsql::execsql $dbfd $sql msg]} then {
       set msg ""
    } else {
	set msg "Mise à jour du RR impossible : $msg"
    }
    return $msg
}

#
# Présente un RR sous forme HTML
#
# Entrée :
#   - paramètres :
#	- dbfd : accès la base
#	- idrr : l'id du rr à chercher ou -1 si tabrr contient déjà tout
#	- tabrr : tableau vide (ou déjà rempli si idrr = -1)
# Sortie :
#   - valeur de retour : chaîne vide (erreur) ou code HTML
#   - paramètre tabrr : cf lire-rr-par-id
#   - variables globales :
#	- libconf(tabmachine) : spécification du tableau utilisé
#
# Historique
#   2008/07/25 : pda/jean : conception
#

proc presenter-rr {dbfd idrr tabrr} {
    global libconf
    upvar $tabrr trr

    #
    # Lire le RR si besoin est
    #

    if {$idrr != -1 && [lire-rr-par-id $dbfd $idrr trr] == -1} then {
	return ""
    }

    #
    # Présenter les différents champs
    #

    set donnees {}

    # nom
    lappend donnees [list Normal "Nom" "$trr(nom).$trr(domaine)"]

    # adresse(s) IP
    set at "Adresse IP"
    set aa $trr(ip)
    switch [llength $trr(ip)] {
	0 { set aa "(aucune)" }
	1 { }
	default { set at "Adresses IP" }
    }
    lappend donnees [list Normal $at $aa]

    # adresse MAC
    lappend donnees [list Normal "Adresse MAC" $trr(mac)]

    # profil DHCP
    lappend donnees [list Normal "Profil DHCP" $trr(dhcpprofil)]

    # type de machine
    lappend donnees [list Normal "Machine" $trr(hinfo)]

    # droit d'émission SMTP : ne le présenter que si c'est utilisé
    # (i.e. s'il y a au moins un groupe qui a les droits)
    set sql "SELECT COUNT(*) AS ndroitsmtp FROM groupe WHERE droitsmtp = 1"
    set ndroitsmtp 0
    pg_select $dbfd $sql tab {
	set ndroitsmtp $tab(ndroitsmtp)
    }
    if {$ndroitsmtp > 0} then {
	if {$trr(droitsmtp)} then {
	    set droitsmtp "Oui"
	} else {
	    set droitsmtp "Non"
	}
	lappend donnees [list Normal "Droit d'émission SMTP" $droitsmtp]
    }

    # infos complémentaires
    lappend donnees [list Normal "Infos complémentaires" $trr(commentaire)]

    # responsable (nom + prénom)
    lappend donnees [list Normal "Responsable (nom + prénom)" $trr(respnom)]

    # responsable (mél)
    lappend donnees [list Normal "Responsable (mél)" $trr(respmel)]

    # aliases
    set la {}
    foreach idalias $trr(aliases) {
	if {[lire-rr-par-id $dbfd $idalias ta]} then {
	    lappend la "$ta(nom).$ta(domaine)"
	}
    }
    if {[llength $la] > 0} then {
	lappend donnees [list Normal "Aliases" [join $la " "]]
    }

    set html [::arrgen::output "html" $libconf(tabmachine) $donnees]
    return $html
}

##############################################################################
# Vérifications syntaxiques
##############################################################################

#
# Valide la syntaxe d'un FQDN complet au sens de la RFC 1035
# élargie pour accepter les chiffres en début de nom.
#
# Entrée :
#   - paramètres :
#	- dbfd : accès à la base
#	- fqdn : le nom à tester
#	- nomvar : contiendra en retour le nom de host
#	- domvar : contiendra en retour le domaine de host
#	- iddomvar : contiendra en retour l'id du domaine
# Sortie :
#   - valeur de retour : chaîne vide (ok) ou non vide (message d'erreur)
#   - paramètre nom : le nom trouvé
#   - paramètre dom : le domaine trouvé
#   - paramètre iddom : l'id du domaine trouvé, ou -1 si erreur
#
# Historique
#   2004/09/21 : pda/jean : conception
#   2004/09/29 : pda/jean : ajout paramètre domvar
#

proc syntaxe-fqdn {dbfd fqdn nomvar domvar iddomvar} {
    upvar $nomvar nom
    upvar $domvar dom
    upvar $iddomvar iddom

    if {! [regexp {^([^\.]+)\.(.*)$} $fqdn bidon nom dom]} then {
	return "FQDN invalide ($fqdn)"
    }

    set msg [syntaxe-nom $nom]
    if {! [string equal $msg ""]} then {
	return $msg
    }

    set iddom [lire-domaine $dbfd $dom]
    if {$iddom < 0} then {
	return "Domaine '$dom' invalide"
    }

    return ""
}

#
# Valide la syntaxe d'un nom (partie de FQDN) au sens de la RFC 1035
# élargie pour accepter les chiffres en début de nom.
#
# Entrée :
#   - paramètres :
#	- nom : le nom à tester
# Sortie :
#   - valeur de retour : chaîne vide (ok) ou non vide (message d'erreur)
#
# Historique
#   2002/04/11 : pda/jean : conception
#

proc syntaxe-nom {nom} {
    # cas général : une lettre-ou-chiffre en début, une lettre-ou-chiffre
    # à la fin (tiret interdit en fin) et lettre-ou-chiffre-ou-tiret au
    # milieu
    set re1 {[a-zA-Z0-9][-a-zA-Z0-9]*[a-zA-Z0-9]}
    # cas particulier d'une seule lettre
    set re2 {[a-zA-Z0-9]}

    if {[regexp "^$re1$" $nom] || [regexp "^$re2$" $nom]} then {
	set m ""
    } else {
	set m "Syntaxe invalide"
    }

    return $m
}



#
# Valide la syntaxe d'une adresse IPv4 ou IPv6
#
# Entrée :
#   - paramètres :
#	- adr : l'adresse à tester
#	- type : "inet", "cidr", "loosecidr", "macaddr", "inet4", "cidr4"
# Sortie :
#   - valeur de retour : chaîne vide (ok) ou non vide (message d'erreur)
#
# Note :
#   - le type "cidr" est strict au sens où les bits spécifiant la
#	partie "machine" doivent être à 0 (i.e. : "1.1.1.0/24" est
#	valide, mais pas "1.1.1.1/24")
#   - le type "loosecidr" accepte les bits de machine non à 0
#
# Historique
#   2002/04/11 : pda/jean : conception
#   2002/05/06 : pda/jean : ajout du type cidr
#   2002/05/23 : pda/jean : reconnaissance des cas cidr simplifiés (a.b/x)
#   2004/01/09 : pda/jean : ajout du cas IPv6 et simplification radicale
#   2004/10/08 : pda/jean : ajout du cas inet4
#   2004/10/20 : jean     : interdit le / pour autre chose que le type cidr
#   2008/07/22 : pda      : nouveau type loosecidr (autorise /)
#   2010/10/07 : pda      : nouveau type cidr4
#

proc syntaxe-ip {dbfd adr type} {

    switch $type {
	inet4 {
	    set cast "inet"
	    set fam  4
	}
	cidr4 {
	    set cast "cidr"
	    set type "cidr"
	    set fam  4
	}
	loosecidr {
	    set cast "inet"
	    set fam ""
	}
	default {
	    set cast $type
	    set fam ""
	}
    }
    set adr [::pgsql::quote $adr]
    set sql "SELECT $cast\('$adr'\) ;"
    set r ""
    if {[::pgsql::execsql $dbfd $sql msg]} then {
	if {! [string equal $fam ""]} then {
	    pg_select $dbfd "SELECT family ('$adr') AS fam" tab {
		if {$tab(fam) != $fam} then {
		    set r "'$adr' n'est pas une adresse IPv$fam"
		}
	    }
	}
	if {! ([string equal $type "cidr"] || [string equal $type "loosecidr"])} then {
	    if {[regexp {/}  $adr ]} then {
		set r "Le caractère '/' est interdit dans l'adresse"
	    }
	}
    } else {
	set r "Syntaxe invalide pour '$adr'"
    }
    return $r
}

#
# Valide la syntaxe d'une adresse MAC
#
# Entrée :
#   - paramètres :
#	- adr : l'adresse à tester
# Sortie :
#   - valeur de retour : chaîne vide (ok) ou non vide (message d'erreur)
#
# Historique
#   2004/08/04 : pda/jean : conception
#

proc syntaxe-mac {dbfd mac} {
    return [syntaxe-ip $dbfd $mac "macaddr"]
}

#
# Valide un identificateur de profil DHCP
#
# Entrée :
#   - paramètres :
#	- dbfd : accès à la base
#	- iddhcpprofil : chaîne de caractère représentant l'id, ou 0
#	- dhcpprofilvar : variable contenant en retour le nom du profil
#	- msgvar : variable contenant en retour le message d'erreur
# Sortie :
#   - valeur de retour : 1 si ok, 0 si erreur
#   - dhcpprofilvar : nom du profil trouvé dans la base (ou Aucun profil)
#   - msgvar : message d'erreur éventuel
#
# Historique
#   2005/04/08 : pda/jean : conception
#

proc check-iddhcpprofil {dbfd iddhcpprofil dhcpprofilvar msgvar} {
    upvar $dhcpprofilvar dhcpprofil
    upvar $msgvar msg

    set msg ""

    if {! [regexp -- {^[0-9]+$} $iddhcpprofil]} then {
	set msg "Syntaxe invalide pour le profil DHCP"
    } else {
	if {$iddhcpprofil != 0} then {
	    set sql "SELECT nom FROM dhcpprofil
				WHERE iddhcpprofil = $iddhcpprofil"
	    set msg "Profil DHCP invalide ($iddhcpprofil)"
	    pg_select $dbfd $sql tab {
		set dhcpprofil $tab(nom)
		set msg ""
	    }
	} else {
	    set dhcpprofil "Aucun profil"
	}
    }

    return [string equal $msg ""]
}

##############################################################################
# Validation d'un domaine
##############################################################################

#
# Cherche un nom de domaine dans la base
#
# Entrée :
#   - paramètres :
#       - dbfd : accès à la base
#	- domaine : le domaine (non terminé par un ".")
# Sortie :
#   - valeur de retour : id du domaine si trouvé, -1 sinon
#
# Historique
#   2002/04/11 : pda/jean : conception
#

proc lire-domaine {dbfd domaine} {
    set domaine [::pgsql::quote $domaine]
    set iddom -1
    pg_select $dbfd "SELECT iddom FROM domaine WHERE nom = '$domaine'" tab {
	set iddom $tab(iddom)
    }
    return $iddom
}

#
# Indique si le correspondant a le droit d'accéder au domaine
#
# Entrée :
#   - paramètres :
#       - dbfd : accès à la base
#	- idcor : le correspondant
#	- iddom : le domaine
#	- roles : liste des rôles à tester (noms des colonnes dans dr_dom)
# Sortie :
#   - valeur de retour : 1 si ok, 0 sinon
#
# Historique
#   2002/04/11 : pda/jean : conception
#   2002/05/06 : pda/jean : utilisation des groupes
#   2004/02/06 : pda/jean : ajout des roles
#

proc droit-correspondant-domaine {dbfd idcor iddom roles} {
    #
    # Clause pour sélectionner les rôles demandés
    #
    set w ""
    foreach r $roles {
	append w "AND dr_dom.$r > 0 "
    }

    set r 0
    set sql "SELECT dr_dom.iddom FROM dr_dom, corresp
			WHERE corresp.idcor = $idcor
				AND corresp.idgrp = dr_dom.idgrp
				AND dr_dom.iddom = $iddom
				$w
				"
    pg_select $dbfd $sql tab {
	set r 1
    }
    return $r
}

#
# Indique si le correspondant a le droit d'accéder à l'adresse IP
#
# Entrée :
#   - paramètres :
#       - dbfd : accès à la base
#	- idcor : le correspondant
#	- adr : l'adresse IP
# Sortie :
#   - valeur de retour : 1 si ok, 0 sinon
#
# Historique
#   2002/04/11 : pda/jean : conception
#   2002/05/06 : pda/jean : utilisation des groupes
#   2004/01/14 : pda/jean : ajout IPv6
#

proc droit-correspondant-ip {dbfd idcor adr} {
    set r 0

    set sql "SELECT valide_ip_cor ('$adr', $idcor) AS ok"
    pg_select $dbfd $sql tab {
	if {[string equal $tab(ok) "t"]} then {
	    set r 1
	} else {
	    set r 0
	}
    }

    return $r
}

#
# Valide les droits d'un correspondant sur un nom de machine, par la
# vérification que toutes les adresses IP lui appartiennent.
#
# Entrée :
#   - paramètres :
#       - dbfd : accès à la base
#	- idcor : le correspondant
#	- tabrr : tableau des informations du RR, cf lire-rr-par-nom
# Sortie :
#   - valeur de retour : 1 si ok ou 0 si erreur
#
# Historique
#   2002/04/19 : pda/jean : conception
#

proc valide-nom-par-adresses {dbfd idcor tabrr} {
    upvar $tabrr trr

    set ok 1
    foreach ip $trr(ip) {
	if {! [droit-correspondant-ip $dbfd $idcor $ip]} then {
	    set ok 0
	    break
	}
    }

    return $ok
}

proc valide-adresses-ip {dbfd idcor idrr} {
    set ok 1
    if {[lire-rr-par-id $dbfd $idrr trr]} then {
	set ok [valide-nom-par-adresses $dbfd $idcor trr]
    }
    return $ok
}

#
# Valider que le correspondant a droit d'ajouter/modifier/supprimer le nom
# fourni suivant un certain contexte.
#
# Entrée :
#   - paramètres :
#       - dbfd : accès à la base
#	- idcor : id du correspondant faisant l'action
#	- nom : nom à tester (premier composant du FQDN)
#	- domaine : domaine à tester (les n-1 derniers composants du FQDN)
#	- trr : contiendra en retour le trr (cf lire-rr-par-id)
#	- contexte : contexte dans lequel on teste le nom
# Sortie :
#   - valeur de retour : chaîne vide (ok) ou non vide (message d'erreur)
#   - paramètre trr : contient le trr du rr trouvé, ou si le rr n'existe
#	pas, trr(idrr) = "" et trr(iddom) contient seulement l'id du domaine
#
# Détail des tests effectués :
#    selon contexte
#	"machine"
#	    valide-domaine (domaine, idcor, "")
#	    si nom.domaine est ALIAS alors erreur
#	    si nom.domaine est MX alors erreur
#	    si nom.domaine est ADRMAIL
#		alors verifier-toutes-les-adresses-IP (hébergeur, idcor)
#		      valide-domaine (domaine, idcor, "")
#	    si nom.domaine a des adresses IP
#		alors verifier-toutes-les-adresses-IP (machine, idcor)
#	    si aucun test n'est faux, alors OK
#	"machine-existante"
#	    idem "machine", mais avec un test comme quoi il y a bien
#		une adresse IP
#	"supprimer-un-nom"
#	    valide-domaine (domaine, idcor, "")
#	    si nom.domaine est ALIAS
#		alors verifier-toutes-les-adresses-IP (machine pointée, idcor)
#	    si nom.domaine est MX alors erreur
#	    si nom.domaine a des adresses IP
#		alors verifier-toutes-les-adresses-IP (machine, idcor)
#	    si nom.domaine est ADRMAIL
#		alors verifier-toutes-les-adresses-IP (hébergeur, idcor)
#		      valide-domaine (domaine, idcor, "")
#	    si aucun test n'est faux, alors OK
#	"alias"
#	    valide-domaine (domaine, idcor, "")
#	    si nom.domaine est ALIAS alors erreur
#	    si nom.domaine est MX alors erreur
#	    si nom.domaine est ADRMAIL alors erreur
#	    si nom.domaine a des adresses IP alors erreur
#	    si aucun test n'est faux, alors OK
#	"mx"
#	    valide-domaine (domaine, idcor, "")
#	    si nom.domaine est ALIAS alors erreur
#	    si nom.domaine est MX
#		alors verifier-toutes-les-adresses-IP (échangeurs, idcor)
#	    si nom.domaine est ADRMAIL alors erreur
#	    si aucun test n'est faux, alors OK
#	"adrmail"
#	    valide-domaine (domaine, idcor, "rolemail")
#	    si nom.domaine est ALIAS alors erreur
#	    si nom.domaine est MX alors erreur
#	    si nom.domaine est ADRMAIL
#		verifier-toutes-les-adresses-IP (hébergeur, idcor)
#		      valide-domaine (domaine, idcor, "")
#	    si nom.domaine est HEBERGEUR
#		verifier qu'il n'est pas hébergeur pour d'autres que lui-même
#	    si nom.domaine a des adresses IP
#		verifier-toutes-les-adresses-IP (nom.domaine, idcor)
#	    si aucun test n'est faux, alors OK
#
#    verifier-adresses-IP (machine, idcor)
#	s'il n'y a pas d'adresse
#	    alors ERREUR
#	    sinon verifier que toutes adr IP sont dans mes plages (avec un AND)
#	fin si
#
# Historique
#   2004/02/27 : pda/jean : spécification
#   2004/02/27 : pda/jean : codage
#   2004/03/01 : pda/jean : remontée du trr à la place de l'id du domaine
#

array set testsdroits {
    machine	{
		    {domaine	{}}
		    {alias	REJECT}
		    {mx		REJECT}
		    {ip		CHECK}
		    {adrmail	CHECK}
		}
    machine-existante	{
		    {domaine	{}}
		    {alias	REJECT}
		    {mx		REJECT}
		    {ip		CHECK}
		    {ip		EXISTS}
		    {adrmail	CHECK}
		}
    alias {
		    {domaine	{}}
		    {alias	REJECT}
		    {mx		REJECT}
		    {ip		REJECT}
		    {adrmail	REJECT}
		}
    supprimer-un-nom {
		    {domaine	{}}
		    {alias	CHECK}
		    {mx		REJECT}
		    {ip		CHECK}
		    {adrmail	CHECK}
		}
    mx		{
		    {domaine	{}}
		    {alias	REJECT}
		    {mx		CHECK}
		    {ip		CHECK}
		    {adrmail	REJECT}
		}
    adrmail	{
		    {domaine	rolemail}
		    {alias	REJECT}
		    {mx		REJECT}
		    {adrmail	CHECK}
		    {hebergeur	CHECK}
		    {ip		CHECK}
		}
}

proc valide-droit-nom {dbfd idcor nom domaine tabrr contexte} {
    upvar $tabrr trr
    global testsdroits

    #
    # Récupérer la liste des actions associée au contexte
    #

    if {! [info exists testsdroits($contexte)]} then {
	return "Erreur interne : contexte '$contexte' incorrect"
    }

    #
    # Enchaîner les tests dans l'ordre souhaité, et sortir
    # dès qu'un test échoue.
    #

    set fqdn "$nom.$domaine"
    set existe 0
    foreach a $testsdroits($contexte) {
	set parm [lindex $a 1]
	switch [lindex $a 0] {
	    domaine {
		set m [valide-domaine $dbfd $idcor $domaine iddom $parm]
		if {! [string equal $m ""]} then {
		    return $m
		}

		set existe [lire-rr-par-nom $dbfd $nom $iddom trr]
		if {! $existe} then {
		    set trr(idrr) ""
		    set trr(iddom) $iddom
		}
	    }
	    alias {
		if {$existe} then {
		    set idrr $trr(cname)
		    if {! [string equal $idrr ""]} then {
			switch $parm {
			    REJECT {
				lire-rr-par-id $dbfd $idrr talias
				set alias "$talias(nom).$talias(domaine)"
				return "'$fqdn' est un alias de '$alias'"
			    }
			    CHECK {
				set ok [valide-adresses-ip $dbfd $idcor $idrr]
				if {! $ok} then {
				    return "Vous n'avez pas les droits sur '$fqdn'"
				}
			    }
			    default {
				return "Erreur interne : paramètre invalide '$parm' pour '$contexte'/$a"
			    }
			}
		    }
		}
	    }
	    mx {
		if {$existe} then {
		    set lmx $trr(mx)
		    foreach mx $lmx {
			switch $parm {
			    REJECT {
				return "'$fqdn' est un MX"
			    }
			    CHECK {
				set idrr [lindex $mx 1]
				set ok [valide-adresses-ip $dbfd $idcor $idrr]
				if {! $ok} then {
				    return "Vous n'avez pas les droits sur '$fqdn'"
				}
			    }
			    default {
				return "Erreur interne : paramètre invalide '$parm' pour '$contexte'/$a"
			    }
			}
		    }
		}
	    }
	    adrmail {
		if {$existe} then {
		    set idrr $trr(rolemail)
		    if {! [string equal $idrr ""]} then {
			switch $parm {
			    REJECT {
				return "'$fqdn' est un rôle de messagerie"
			    }
			    CHECK {
				if {! [lire-rr-par-id $dbfd $idrr trrh]} then {
				    return "Erreur interne : hébergeur d'id '$idrr' inexistant"
				}

				#
				# Vérification des adresses IP
				#
				set ok [valide-nom-par-adresses $dbfd $idcor trrh]
				if {! $ok} then {
				    return "Vous n'avez pas les droits sur l'hébergeur de '$fqdn'"
				}

				#
				# Vérification du domaine de l'hébergeur
				#

				set msg [valide-domaine $dbfd $idcor $trrh(domaine) bidon ""]
				if {! [string equal $msg ""]} then {
				    return "Vous n'avez pas les droits sur l'hébergeur de '$fqdn'\n$msg"
				}
			    }
			    default {
				return "Erreur interne : paramètre invalide '$parm' pour '$contexte'/$a"
			    }
			}
		    }
		}
	    }
	    hebergeur {
		if {$existe} then {
		    set ladr $trr(adrmail)
		    switch $parm {
			REJECT {
			    if {[llength $ladr] > 0} then {
				return "'$fqdn' est un hébergeur pour des adresses de messagerie"
			    }
			}
			CHECK {
			    # éliminer le nom de la liste des adresses
			    # hébergées sur cette machine.
			    set pos [lsearch -exact $ladr $trr(idrr)]
			    if {$pos != -1} then {
				set ladr [lreplace $ladr $pos $pos]
			    }
			    if {[llength $ladr] > 0} then {
				return "'$fqdn' est un hébergeur pour des adresses de messagerie."
			    }
			}
			default {
			    return "Erreur interne : paramètre invalide '$parm' pour '$contexte'/$a"
			}
		    }
		}
	    }
	    ip {
		if {$existe} then {
		    switch $parm {
			REJECT {
			    return "'$fqdn' a des adresses IP"
			}
			EXISTS {
			    if {[string equal $trr(ip) ""]} then {
				return "Le nom '$fqdn' ne correspond pas à une machine"
			    }
			}
			CHECK {
			    set ok [valide-nom-par-adresses $dbfd $idcor trr]
			    if {! $ok} then {
				return "Vous n'avez pas les droits sur '$fqdn'"
			    }
			}
			default {
			    return "Erreur interne : paramètre invalide '$parm' pour '$contexte'/$a"
			}
		    }
		} else {
		    if {[string equal $parm "EXISTS"]} {
			return "Le nom '$fqdn' n'existe pas"
		    }
		}
	    }
	}
    }

    return ""
}

#
# Valide les informations d'un MX telles qu'extraites d'un formulaire
#
# Entrée :
#   - paramètres :
#	- dbfd : accès à la base
#	- prio : priorité lue dans le formulaire
#	- nom : nom du MX, lu dans le formulaire
#	- dom : nom de domaine du MX, lu dans le formulaire
#	- idcor : id du correspondant
#	- msgvar : paramètre passé par variable
# Sortie :
#   - valeur de retour : liste {prio idmx} où
#	- prio = priorité numérique (syntaxe entière ok)
#	- idmx = id d'un RR existant
#   - paramètres :
#	- msgvar : chaîne vide si ok, ou message d'erreur
#
# Historique
#   2003/04/25 : pda/jean : conception
#   2004/03/04 : pda/jean : reprise et mise en commun
#

proc valide-mx {dbfd prio nom domaine idcor msgvar} {
    upvar $msgvar m

    #
    # Validation syntaxique de la priorité
    #

    if {! [regexp {^[0-9]+$} $prio]} then {
	set m "Priorité non valide ($prio)"
	return {}
    }

    #
    # Validation de l'existence du relais, du domaine, etc.
    #

    set m [valide-droit-nom $dbfd $idcor $nom $domaine trr "machine-existante"]
    if {! [string equal $m ""]} then {
	return {}
    }

    #
    # Mettre en forme le résultat
    #

    return [list $prio $trr(idrr)]
}

#
# Valide le domaine et l'autorisation du correspondant
#
# Entrée :
#   - paramètres :
#       - dbfd : accès à la base
#	- idcor : le correspondant
#	- domaine : le domaine (en texte)
#	- iddom : contiendra en retour l'id du domaine
#	- roles : liste des rôles à tester (noms des colonnes dans dr_dom)
# Sortie :
#   - valeur de retour : chaîne vide (ok) ou non vide (message d'erreur)
#   - paramètre iddom : l'id du domaine trouvé, ou -1 si erreur
#
# Historique
#   2002/04/11 : pda/jean : conception
#   2002/04/19 : pda/jean : ajout du paramètre iddom
#   2002/05/06 : pda/jean : utilisation des groupes
#   2004/02/06 : pda/jean : ajout des roles
#

proc valide-domaine {dbfd idcor domaine iddomvar roles} {
    upvar $iddomvar iddom

    set m ""
    set iddom [lire-domaine $dbfd $domaine]
    if {$iddom >= 0} then {
	if {[droit-correspondant-domaine $dbfd $idcor $iddom $roles]} then {
	    set m ""
	} else {
	    set m "Désolé, mais vous n'avez pas accès au domaine '$domaine'"
	}
    } else {
	set m "Domaine '$domaine' inexistant"
    }
    return $m
}

#
# Valide le domaine, les relais de messagerie, par rapport au correspondant
#
# Entrée :
#   - paramètres :
#       - dbfd : accès à la base
#	- idcor : le correspondant
#	- domaine : le domaine (en texte)
#	- iddom : contiendra en retour l'id du domaine
# Sortie :
#   - valeur de retour : chaîne vide (ok) ou non vide (message d'erreur)
#   - paramètre iddom : l'id du domaine trouvé, ou -1 si erreur
#
# Historique
#   2004/03/04 : pda/jean : conception
#

proc valide-domaine-et-relais {dbfd idcor domaine iddomvar} {
    upvar $iddomvar iddom

    #
    # Valider le domaine
    #

    set msg [valide-domaine $dbfd $idcor $domaine iddom "rolemail"]
    if {! [string equal $msg ""]} then {
	return $msg
    }

    #
    # Valider que nous sommes bien propriétaire de tous les relais
    # spécifiés.
    #

    set sql "SELECT r.nom AS nom, d.nom AS domaine
		FROM relais_dom rd, rr r, domaine d
		WHERE rd.iddom = $iddom
			AND r.iddom = d.iddom
			AND rd.mx = r.idrr
		"
    pg_select $dbfd $sql tab {
	set msg [valide-droit-nom $dbfd $idcor $tab(nom) $tab(domaine) \
				trr "machine-existante"]
	if {! [string equal $msg ""]} then {
	    return "Édition refusée pour '$domaine', car vous n'avez pas accès à un relais\n$msg"
	}
    }

    return ""
}

#
# Valide un rôle de messagerie.
#
# Entrée :
#   - paramètres :
#       - dbfd : accès à la base
#	- idcor : le correspondant
#	- nom : nom du rôle (adresse de messagerie)
#	- domaine : domaine du rôle (adresse de messagerie)
#	- trr : contiendra en retour le trr (cf lire-rr-par-id)
#	- trrh : contiendra en retour le trr de l'hébergeur (cf lire-rr-par-id)
# Sortie :
#   - valeur de retour : chaîne vide (ok) ou non vide (message d'erreur)
#   - paramètre trr : contient le trr du rr trouvé, ou si le rr n'existe
#	pas, trr(idrr) = "" et trr(iddom) contient seulement l'id du domaine
#   - paramètre trrh : contient le trr du rr de l'hébergeur,
#	si trr(rolemail) existe, ou un trr fictif contenant au moins
#	trrh(nom) et trrh(domaine)
#
# Historique
#   2004/02/12 : pda/jean : création
#   2004/02/27 : pda/jean : centralisation de la gestion des droits
#   2004/03/01 : pda/jean : ajout trr et trrh
#

proc valide-role-mail {dbfd idcor nom domaine tabrr tabrrh} {
    upvar $tabrr trr
    upvar $tabrrh trrh

    set fqdn "$nom.$domaine"

    #
    # Validation des droits
    #

    set m [valide-droit-nom $dbfd $idcor $nom $domaine trr "adrmail"]
    if {! [string equal $m ""]} then {
	return $m
    }

    #
    # Récupération du rr de l'hébergeur
    #

    catch {unset trrh}
    set trrh(nom)     ""
    set trrh(domaine) ""

    if {! [string equal $trr(idrr) ""]} then {
	set h $trr(rolemail)
	if {! [string equal $h ""]} then {
	    #
	    # Le nom fourni est une adresse de messagerie existante
	    # A-t'on le droit d'agir dessus ?
	    #
	    if {! [lire-rr-par-id $dbfd $h trrh]} then {
		return "Erreur interne sur '$fqdn' (id heberg $h non trouvé)"
	    }
	}
    }

    return ""
}

#
# Valide qu'aucune adresse IP n'empiète sur un intervalle DHCP dynamique
# si l'adresse MAC n'est pas vide.
#
# Entrée :
#   - paramètres :
#       - dbfd : accès à la base
#	- mac : l'adresse MAC (vide ou non)
#	- lip : liste des adresses IP (v4 et v6)
# Sortie :
#   - valeur de retour : chaîne vide (ok) ou non vide (message d'erreur)
#
# Historique
#   2004/08/04 : pda/jean : conception
#

proc valide-dhcp-statique {dbfd mac lip} {
    set r ""
    if {! [string equal $mac ""]} then {
	foreach ip $lip {
	    set sql "SELECT min, max
			    FROM dhcprange
			    WHERE '$ip' >= min AND '$ip' <= max"
	    pg_select $dbfd $sql tab {
		set r "$ip est dans l'intervalle DHCP \[$tab(min)..$tab(max)\]"
	    }
	    if {! [string equal $r ""]} then {
		break
	    }
	}
    }

    return $r
}

##############################################################################
# Validation des correspondants
##############################################################################

#
# Valide l'accès d'un correspondant aux pages de l'application
#
# Entrée :
#   - paramètres :
#       - dbfd : accès à la base
#	- pageerr : page d'erreur avec un trou pour le message
# Sortie :
#   - valeur de retour : id du correspondant si trouvé, pas de sortie sinon
#
# Historique
#   2002/03/27 : pda/jean : conception
#

proc valide-correspondant {dbfd pageerr} {
    #
    # Le login de l'utilisateur (la page est protégée par mot de passe)
    #

    set login [::webapp::user]
    if {[string compare $login ""] == 0} then {
	::webapp::error-exit $pageerr "Pas de login : l'authentification a échoué"
    }

    #
    # Récupération des informations du correspondant
    # et validation de ses droits.
    #

    set qlogin [::pgsql::quote $login]
    set idcor -1
    set sql "SELECT idcor, present FROM corresp WHERE login = '$qlogin'"
    pg_select $dbfd $sql tab {
	set idcor	$tab(idcor)
	set present	$tab(present)
    }

    if {$idcor == -1} then {
	::webapp::error-exit $pageerr "Désolé, vous n'êtes pas dans la base des correspondants."
    }
    if {! $present} then {
	::webapp::error-exit $pageerr "Désolé, $login, mais vous n'êtes pas habilité."
    }

    return $idcor
}


#
# Lit le groupe associé à un correspondant
#
# Entrée :
#   - paramètres :
#       - dbfd : accès à la base
#	- idcor : l'id du correspondant
# Sortie :
#   - valeur de retour : id du groupe si trouvé, ou -1
#
# Historique
#   2002/05/06 : pda/jean : conception
#

proc lire-groupe {dbfd idcor} {
    set idgrp -1
    set sql "SELECT idgrp FROM corresp WHERE idcor = $idcor"
    pg_select $dbfd $sql tab {
	set idgrp	$tab(idgrp)
    }
    return $idgrp
}

#
# Vérifie la syntaxe d'un nom de groupe
#
# Entrée :
#   - paramètres :
#       - groupe : nom du groupe
# Sortie :
#   - valeur de retour : chaîne vide (ok) ou non vide (message d'erreur)
#
# Historique
#   2008/02/13 : pda/jean : conception
#

proc syntaxe-groupe {groupe} {
    if {[regexp {^[-A-Za-z0-9]*$} $groupe]} then {
	set r ""
    } else {
	set r "Nom de groupe '$groupe' invalide (autorisés : lettres, chiffres et caractère moins)"
    }
    return $r
}


##############################################################################
# Validation des hinfo
##############################################################################

#
# Lit l'indice du HINFO dans la table
#
# Entrée :
#   - dbfd : accès à la base
#   - texte : texte hinfo à chercher
# Sortie :
#   - valeur de retour : indice ou -1 si non trouvé
#
# Historique
#   2002/05/03 : pda/jean : conception
#

proc lire-hinfo {dbfd texte} {
    set qtexte [::pgsql::quote $texte]
    set idhinfo -1
    pg_select $dbfd "SELECT idhinfo FROM hinfo WHERE texte = '$qtexte'" tab {
	set idhinfo $tab(idhinfo)
    }
    return $idhinfo
}

##############################################################################
# Validation des dhcpprofil
##############################################################################

#
# Lit l'indice du dhcpprofil dans la table
#
# Entrée :
#   - dbfd : accès à la base
#   - texte : texte dhcpprofil à chercher ou ""
# Sortie :
#   - valeur de retour : indice, ou 0 si "", ou -1 si non trouvé
#
# Historique
#   2005/04/11 : pda/jean : conception
#

proc lire-dhcpprofil {dbfd texte} {
    if {[string equal $texte ""]} then {
	set iddhcpprofil 0
    } else {
	set qtexte [::pgsql::quote $texte]
	set sql "SELECT iddhcpprofil FROM dhcpprofil WHERE nom = '$qtexte'"
	set iddhcpprofil -1
	pg_select $dbfd $sql tab {
	    set iddhcpprofil $tab(iddhcpprofil)
	}
    }
    return $iddhcpprofil
}

##############################################################################
# Récupération d'informations pour les menus
##############################################################################

#
# Récupère les HINFO possibles sous forme d'un menu HTML prêt à l'emploi
#
# Entrée :
#   - dbfd : accès à la base
#   - champ : champ de formulaire (variable du CGI suivant)
#   - defval : hinfo (texte) par défaut
# Sortie :
#   - valeur de retour : code HTML prêt à l'emploi
#
# Historique
#   2002/05/03 : pda/jean : conception
#

proc menu-hinfo {dbfd champ defval} {
    set lhinfo {}
    set sql "SELECT texte FROM hinfo \
				WHERE present = 1 \
				ORDER BY tri, texte"
    set i 0
    set defindex 0
    pg_select $dbfd $sql tab {
	lappend lhinfo [list $tab(texte) $tab(texte)]
	if {[string equal $tab(texte) $defval]} then {
	    set defindex $i
	}
	incr i
    }
    return [::webapp::form-menu $champ 1 0 $lhinfo [list $defindex]]
}

#
# Récupère les profils DHCP accessibles par le groupe sous forme d'un
# menu visible, ou un champ caché si le groupe n'a accès à aucun profil
# DHCP.
#
# Entrée :
#   - dbfd : accès à la base
#   - champ : champ de formulaire (variable du CGI suivant)
#   - idcor : identification du correspondant
#   - iddhcpprofil : identification du profil à sélectionner (le profil
#	pré-existant) ou 0
# Sortie :
#   - valeur de retour : liste avec deux éléments de code HTML prêt à l'emploi
#	(intitulé, menu de sélection)
#
# Historique
#   2005/04/08 : pda/jean : conception
#   2008/07/23 : pda/jean : changement format sortie
#

proc menu-dhcpprofil {dbfd champ idcor iddhcpprofil} {
    #
    # Récupérer les profils DHCP visibles par le groupe
    # ainsi que le profil DHCP pré-existant
    #

    set sql "SELECT p.iddhcpprofil, p.nom
		FROM dr_dhcpprofil dr, dhcpprofil p, corresp c
		WHERE c.idcor = $idcor
		    AND dr.idgrp = c.idgrp
		    AND dr.iddhcpprofil = p.iddhcpprofil
		ORDER BY dr.tri ASC, p.nom"
    set lprof {}
    set lsel {}
    set idx 1
    pg_select $dbfd $sql tab {
	lappend lprof [list $tab(iddhcpprofil) $tab(nom)]
	if {$tab(iddhcpprofil) == $iddhcpprofil} then {
	    lappend lsel $idx
	}
	incr idx
    }

    #
    # A-t'on trouvé au moins un profil ?
    #

    if {[llength $lprof] > 0} then {
	#
	# Est-ce que le profil pré-existant est bien dans notre
	# liste ?
	#

	if {$iddhcpprofil != 0 && [llength $lsel] == 0} then {
	    #
	    # Non. On va donc ajouter à la fin de la liste
	    # le profil pré-existant
	    #
	    set sql "SELECT iddhcpprofil, nom
			    FROM dhcpprofil
			    WHERE iddhcpprofil = $iddhcpprofil"
	    pg_select $dbfd $sql tab {
		lappend lprof [list $tab(iddhcpprofil) $tab(nom)]
		lappend lsel $idx
	    }
	}

	#
	# Ajouter le cas spécial en début de liste
	#

	set lprof [linsert $lprof 0 {0 {Aucun profil}}]

	set intitule "Profil DHCP"
	set html [::webapp::form-menu iddhcpprofil 1 0 $lprof $lsel]

    } else {
	#
	# Aucun profil trouvé. On cache l'information
	#

	set intitule ""
	set html "<INPUT TYPE=HIDDEN NAME=\"$champ\" VALUE=\"$iddhcpprofil\">"
    }

    return [list $intitule $html]
}

#
# Récupère le droit d'émettre en SMTP d'une machine, ou un champ caché
# si le groupe n'a pas accès à la fonctionnalité
#
# Entrée :
#   - dbfd : accès à la base
#   - champ : champ de formulaire (variable du CGI suivant)
#   - idcor : identification du correspondant
#   - droitsmtp : valeur actuelle (donc à présélectionner)
# Sortie :
#   - valeur de retour : liste avec deux éléments de code HTML prêt à l'emploi
#	(intitulé, choix de sélection)
#
# Historique
#   2008/07/23 : pda/jean : conception
#   2008/07/24 : pda/jean : utilisation de idcor plutôt que idgrp
#

proc menu-droitsmtp {dbfd champ idcor droitsmtp} {
    #
    # Récupérer le droit SMTP pour afficher ou non le bouton
    # d'autorisation d'émettre en SMTP non authentifié
    #

    set grdroitsmtp [droit-correspondant-smtp $dbfd $idcor]
    if {$grdroitsmtp} then {
	set intitule "Émettre en SMTP"
	set html [::webapp::form-bool $champ $droitsmtp]
    } else {
	set intitule ""
	set html "<INPUT TYPE=HIDDEN NAME=\"$champ\" VALUE=\"$droitsmtp\">"
    }

    return [list $intitule $html]
}


#
# Fournit le code HTML pour une sélection de liste de domaines, soit
# sous forme de menus déroulants si le nombre de domaines autorisés
# est > 1, soit un texte simple avec un champ HIDDEN si = 1.
#
# Entrée :
#   - dbfd : accès à la base
#   - idcor : id du correspondant
#   - champ : champ de formulaire (variable du CGI suivant)
#   - where : clause where (sans le mot-clef "where") ou chaîne vide
#   - sel : nom du domaine à pré-sélectionner, ou chaîne vide
#   - err : page d'erreur
# Sortie :
#   - valeur de retour : code HTML généré
#
# Historique :
#   2002/04/11 : pda/jean : codage
#   2002/04/23 : pda      : ajout de la priorité d'affichage
#   2002/05/03 : pda/jean : migration en librairie
#   2002/05/06 : pda/jean : utilisation des groupes
#   2003/04/24 : pda/jean : décomposition en deux procédures
#   2004/02/06 : pda/jean : ajout de la clause where
#   2004/02/12 : pda/jean : ajout du paramètre sel
#

proc menu-domaine {dbfd idcor champ where sel err} {
    set lcouples [couple-domaine-par-corresp $dbfd $idcor $where]

    set lsel [lsearch -exact $lcouples [list $sel $sel]]
    if {$lsel == -1} then {
	set lsel {}
    }

    #
    # S'il n'y a qu'un seul domaine, le présenter en texte, sinon
    # présenter tous les domaines dans un menu déroulant
    #

    set taille [llength $lcouples]
    switch -- $taille {
	0	{
	    ::webapp::error-exit $err "Désolé, mais vous n'avez aucun domaine actif"
	}
	1	{
	    set d [lindex [lindex $lcouples 0] 0]
	    set html "$d <INPUT TYPE=\"HIDDEN\" NAME=\"$champ\" VALUE=\"$d\">"
	}
	default	{
	    set html [::webapp::form-menu $champ 1 0 $lcouples $lsel]
	}
    }

    return $html
}

#
# Retourne une liste de couples {nom nom} pour chaque domaine
# autorisé pour le correspondant.
#
# Entrée :
#   - dbfd : accès à la base
#   - idcor : id du correspondant
#   - where : clause where (sans le mot-clef "where") ou chaîne vide
# Sortie :
#   - valeur de retour : liste de couples
#
# Historique :
#   2003/04/24 : pda/jean : codage
#   2004/02/06 : pda/jean : ajout de la clause where
#

proc couple-domaine-par-corresp {dbfd idcor where} {
    #
    # Récupération des domaines auxquels le correspond a accès
    # et construction d'une liste {{domaine domaine}} pour l'appel
    # ultérieur à "form-menu"
    #

    if {! [string equal $where ""]} then {
	set where " AND $where"
    }

    set lcouples {}
    set sql "SELECT domaine.nom
		FROM domaine, dr_dom, corresp
		WHERE domaine.iddom = dr_dom.iddom
		    AND dr_dom.idgrp = corresp.idgrp
		    AND corresp.idcor = $idcor
		    $where
		ORDER BY dr_dom.tri ASC"
    pg_select $dbfd $sql tab {
	lappend lcouples [list $tab(nom) $tab(nom)]
    }

    return $lcouples
}

##############################################################################
# Récupération des informations associées à un groupe
##############################################################################

#
# Récupère la liste des groupes
#
# Entrée :
#   - paramètres :
#	- dbfd : accès à la base
#	- n : 1 s'il faut une liste à 1 élément, 2 s'il en faut 2, etc.
# Sortie :
#   - valeur de retour : liste des noms (ou des {noms noms}) des groupes
#
# Historique
#   2006/02/17 : pda/jean/zamboni : création
#   2007/10/10 : pda/jean         : ignorer le groupe des orphelins
#

proc liste-groupes {dbfd {n 1}} {
    set l {}
    for {set i 0} {$i < $n} {incr i} {
	lappend l "nom"
    }
    return [::pgsql::getcols $dbfd groupe "nom <> ''" "nom ASC" $l]
}

#
# Fournit du code HTML pour chaque groupe d'informations associé à un
# groupe : les droits généraux du groupe, les correspondants, les
# réseaux, les droits hors réseaux, les domaines, les profils DHCP
#
# Entrée :
#   - paramètres :
#	- dbfd : accès à la base
#	- idgrp : identificateur du groupe
#   - variable globale libconf(tabreseaux) : spéc. de tableau
#   - variable globale libconf(tabdomaines) : spéc. de tableau
# Sortie :
#   - valeur de retour : liste à 6 éléments, chaque élément étant
#	le code HTML associé.
#
# Historique
#   2002/05/23 : pda/jean : spécification et conception
#   2005/04/06 : pda      : ajout des profils dhcp
#   2007/10/23 : pda/jean : ajout des correspondants
#   2008/07/23 : pda/jean : ajout des droits du groupe
#

proc info-groupe {dbfd idgrp} {
    global libconf

    #
    # Récupération des droits particuliers : admin et droitsmtp
    #

    set donnees {}
    set sql "SELECT admin, droitsmtp FROM groupe WHERE idgrp = $idgrp"
    pg_select $dbfd $sql tab {
	if {$tab(admin)} then {
	    set admin "oui"
	} else {
	    set admin "non"
	}
	if {$tab(droitsmtp)} then {
	    set droitsmtp "oui"
	} else {
	    set droitsmtp "non"
	}
	lappend donnees [list DROIT "Administration de l'application" $admin]
	lappend donnees [list DROIT "Gestion des émetteurs SMTP" $droitsmtp]
    }
    if {[llength $donnees] == 2} then {
	set tabdroits [::arrgen::output "html" $libconf(tabdroits) $donnees]
    } else {
	set tabdroits "Erreur sur les droits du groupe"
    }

    #
    # Récupération des correspondants
    #

    set lcor {}
    set sql "SELECT login FROM corresp WHERE idgrp=$idgrp ORDER BY login"
    pg_select $dbfd $sql tab {
	lappend lcor [::webapp::html-string $tab(login)]
    }
    set tabcorresp [join $lcor ", "]

    #
    # Récupération des plages auxquelles a droit le correspondant
    #

    set donnees {}
    set sql "SELECT r.idreseau,
			r.nom, r.localisation, r.adr4, r.adr6,
			d.dhcp, d.acl,
			e.nom AS etabl,
			c.nom AS commu
		FROM reseau r, dr_reseau d, etablissement e, communaute c
		WHERE d.idgrp = $idgrp
			AND d.idreseau = r.idreseau
			AND e.idetabl = r.idetabl
			AND c.idcommu = r.idcommu
		ORDER BY d.tri, r.adr4, r.adr6"
    pg_select $dbfd $sql tab {
	set r_nom 	[::webapp::html-string $tab(nom)]
	set r_loc	[::webapp::html-string $tab(localisation)]
	set r_etabl	$tab(etabl)
	set r_commu	$tab(commu)
	set r_dhcp	$tab(dhcp)
	set r_acl	$tab(acl)

	# affadr : utilisé pour l'affichage cosmétique des adresses
	set affadr {}
	# where : partie de la clause WHERE pour la sélection des adresses
	set where  {}
	foreach a {adr4 adr6} {
	    if {! [string equal $tab($a) ""]} then {
		lappend affadr $tab($a)
		lappend where  "adr <<= '$tab($a)'"
	    }
	}
	set affadr [join $affadr ", "]
	set where  [join $where  " OR "]

	lappend donnees [list Reseau $r_nom]
	lappend donnees [list Normal4 Localisation $r_loc \
				Établissement $r_etabl]
	lappend donnees [list Normal4 Plage $affadr \
				Communauté $r_commu]

	set droits {}

	set dres {}
	if {$r_dhcp} then { lappend dres "dhcp" }
	if {$r_acl} then { lappend dres "acl" }
	if {[llength $dres] > 0} then {
	    lappend droits [join $dres ", "]
	}
	set sql2 "SELECT adr, allow_deny
			FROM dr_ip
			WHERE ($where)
			    AND idgrp = $idgrp
			ORDER BY adr"
	pg_select $dbfd $sql2 tab2 {
	    if {$tab2(allow_deny)} then {
		set x "+"
	    } else {
		set x "-"
	    }
	    lappend droits "$x $tab2(adr)"
	}

	lappend donnees [list Droits Droits [join $droits "\n"]]
    }

    if {[llength $donnees] > 0} then {
	set tabreseaux [::arrgen::output "html" $libconf(tabreseaux) $donnees]
    } else {
	set tabreseaux "Aucun réseau autorisé"
    }

    #
    # Sélectionner les droits hors des plages réseaux identifiées
    # ci-dessus.
    #

    set donnees {}
    set trouve 0
    set sql "SELECT adr, allow_deny
		    FROM dr_ip
		    WHERE NOT (adr <<= ANY (
				SELECT r.adr4
					FROM reseau r, dr_reseau d
					WHERE r.idreseau = d.idreseau
						AND d.idgrp = $idgrp
				UNION
				SELECT r.adr6
					FROM reseau r, dr_reseau d
					WHERE r.idreseau = d.idreseau
						AND d.idgrp = $idgrp
				    ) )
			AND idgrp = $idgrp
		    ORDER BY adr"
    set droits {}
    pg_select $dbfd $sql tab {
	set trouve 1
	if {$tab(allow_deny)} then {
	    set x "+"
	} else {
	    set x "-"
	}
	lappend droits "$x $tab(adr)"
    }
    lappend donnees [list Droits Droits [join $droits "\n"]]

    if {$trouve} then {
	set tabcidrhorsreseau [::arrgen::output "html" \
						$libconf(tabreseaux) $donnees]
    } else {
	set tabcidrhorsreseau "Aucun (tout va bien)"
    }


    #
    # Sélectionner les domaines
    #

    set donnees {}
    set sql "SELECT domaine.nom AS nom, dr_dom.rolemail, dr_dom.roleweb \
			FROM dr_dom, domaine
			WHERE dr_dom.iddom = domaine.iddom \
				AND dr_dom.idgrp = $idgrp \
			ORDER BY dr_dom.tri, domaine.nom"
    pg_select $dbfd $sql tab {
	set rm ""
	if {$tab(rolemail)} then {
	    set rm "Édition des rôles de messagerie"
	}
	set rw ""
	if {$tab(roleweb)} then {
	    set rw "Édition des rôles web"
	}

	lappend donnees [list Domaine $tab(nom) $rm $rw]
    }
    if {[llength $donnees] > 0} then {
	set tabdomaines [::arrgen::output "html" $libconf(tabdomaines) $donnees]
    } else {
	set tabdomaines "Aucun domaine autorisé"
    }

    #
    # Sélectionner les profils DHCP
    #

    set donnees {}
    set sql "SELECT p.nom, dr.tri, p.texte \
			FROM dhcpprofil p, dr_dhcpprofil dr
			WHERE p.iddhcpprofil = dr.iddhcpprofil \
				AND dr.idgrp = $idgrp \
			ORDER BY dr.tri, p.nom"
    pg_select $dbfd $sql tab {
	lappend donnees [list DHCP $tab(nom) $tab(texte)]
    }
    if {[llength $donnees] > 0} then {
	set tabdhcpprofil [::arrgen::output "html" $libconf(tabdhcpprofil) $donnees]
    } else {
	set tabdhcpprofil "Aucun profil DHCP autorisé"
    }

    return [list    $tabdroits \
		    $tabcorresp \
		    $tabreseaux \
		    $tabcidrhorsreseau \
		    $tabdomaines \
		    $tabdhcpprofil \
	    ]
}

#
# Fournit la liste des réseaux associés à un groupe avec un certain droit.
#
# Entrée :
#   - paramètres :
#	- dbfd : accès à la base
#	- idgrp : identificateur du groupe
#	- droit : "consult", "dhcp" ou "acl"
# Sortie :
#   - valeur de retour : liste des réseaux sous la forme
#		{idreseau cidr4 cidr6 nom-complet}
#
# Historique
#   2004/01/16 : pda/jean : spécification et conception
#   2004/08/06 : pda/jean : extension des droits sur les réseaux
#   2004/10/05 : pda/jean : adaptation aux nouveaux droits
#   2006/05/24 : pda/jean/boggia : séparation en une fonction élémentaire
#

proc liste-reseaux-autorises {dbfd idgrp droit} {
    #
    # Mettre en forme les droits pour la clause where
    #

    switch -- $droit {
	consult {
	    set w1 ""
	    set w2 ""
	}
	dhcp {
	    set w1 "AND d.$droit > 0"
	    set w2 "AND r.$droit > 0"
	}
	acl {
	    set w1 "AND d.$droit > 0"
	    set w2 ""
	}
    }

    #
    # Récupérer tous les réseaux autorisés par le groupe selon ce droit
    #

    set lres {}
    set sql "SELECT r.idreseau, r.nom, r.adr4, r.adr6
			FROM reseau r, dr_reseau d
			WHERE r.idreseau = d.idreseau
			    AND d.idgrp = $idgrp
			    $w1 $w2
			ORDER BY adr4, adr6"
    pg_select $dbfd $sql tab {
	lappend lres [list $tab(idreseau) $tab(adr4) $tab(adr6) $tab(nom)]
    }

    return $lres
}

#
# Fournit la liste de réseaux associés à un groupe avec un certain droit,
# prête à être utilisée dans un menu.
#
# Entrée :
#   - paramètres :
#	- dbfd : accès à la base
#	- idgrp : identificateur du groupe
#	- droit : "consult", "dhcp" ou "acl"
# Sortie :
#   - valeur de retour : liste des réseaux sous la forme {idreseau nom-complet}
#
# Historique
#   2006/05/24 : pda/jean/boggia : séparation du coeur de la fonction
#

proc liste-reseaux {dbfd idgrp droit} {
    #
    # Présente la liste élémentaire retournée par liste-reseaux-autorises
    #

    set lres {}
    foreach r [liste-reseaux-autorises $dbfd $idgrp $droit] {
	lappend lres [list [lindex $r 0] \
			[format "%s\t%s\t(%s)" \
				[lindex $r 1] \
				[lindex $r 2] \
				[::webapp::html-string [lindex $r 3]] \
			    ] \
			]
    }

    return $lres
}

#
# Valide un idreseau tel que retourné par un formulaire. Cette validation
# est réalisé dans le contexte d'un groupe, avec test d'un droit particulier.
#
# Entrée :
#   - paramètres :
#	- dbfd : accès à la base
#	- idreseau : id à vérifier
#	- idgrp : identificateur du groupe
#	- droit : "consult", "dhcp" ou "acl"
#	- version : 4, 6 ou {4 6}
#	- msgvar : message d'erreur en retour
# Sortie :
#   - valeur de retour : liste de CIDR, ou liste vide
#   - paramètre msgvar : message d'erreur en retour si liste vide
#
# Historique
#   2004/10/05 : pda/jean : spécification et conception
#

proc valide-idreseau {dbfd idreseau idgrp droit version msgvar} {
    upvar $msgvar msg

    #
    # Valider le numéro de réseau au niveau syntaxique
    #
    set idreseau [string trim $idreseau]
    if {! [regexp {^[0-9]+$} $idreseau]} then {
	set msg "Plage réseau invalide ($idreseau)"
	return {}
    }

    #
    # Convertir le droit en clause where
    #

    switch -- $droit {
	consult {
	    set w1 ""
	    set w2 ""
	    set c "en consultation"
	}
	dhcp {
	    set w1 "AND d.$droit > 0"
	    set w2 "AND r.$droit > 0"
	    set c "pour le droit '$droit'"
	}
	acl {
	    set w1 "AND d.$droit > 0"
	    set w2 ""
	    set c "pour le droit '$droit'"
	}
    }

    #
    # Valider le numéro de réseau et récupérer le ou les CIDR associé(s)
    #

    set lcidr {}
    set msg ""

    set sql "SELECT r.adr4, r.adr6
		    FROM dr_reseau d, reseau r
		    WHERE d.idgrp = $idgrp
			AND d.idreseau = r.idreseau
			AND r.idreseau = $idreseau
			$w1 $w2"
    set cidrplage4 ""
    set cidrplage6 ""
    pg_select $dbfd $sql tab {
	set cidrplage4 $tab(adr4)
	set cidrplage6 $tab(adr6)
    }

    if {[lsearch -exact $version 4] == -1} then {
	set cidrplage4 ""
    }
    if {[lsearch -exact $version 6] == -1} then {
	set cidrplage6 ""
    }

    set vide4 [string equal $cidrplage4 ""]
    set vide6 [string equal $cidrplage6 ""]

    switch -glob $vide4-$vide6 {
	1-1 {
	    set msg "Vous n'avez pas accès à ce réseau $c"
	}
	0-1 {
	    lappend lcidr $cidrplage4
	}
	1-0 {
	    lappend lcidr $cidrplage6
	}
	0-0 {
	    lappend lcidr $cidrplage4
	    lappend lcidr $cidrplage6
	}
    }

    return $lcidr
}

#
# Indique si le groupe du correspondant a le droit d'autoriser des
# émetteurs SMTP.
#
# Entrée :
#   - paramètres :
#       - dbfd : accès à la base
#	- idcor : le correspondant
# Sortie :
#   - valeur de retour : 1 si ok, 0 sinon
#
# Historique
#   2008/07/23 : pda/jean : conception
#   2008/07/24 : pda/jean : changement de idgrp en idcor
#

proc droit-correspondant-smtp {dbfd idcor} {
    set sql "SELECT droitsmtp FROM groupe g, corresp c 
				WHERE g.idgrp = c.idgrp AND c.idcor = $idcor"
    set r 0
    pg_select $dbfd $sql tab {
	set r $tab(droitsmtp)
    }
    return $r
}


##############################################################################
# Edition de valeurs de tableau
##############################################################################

#
# Présente le contenu d'une table pour édition des valeurs qui s'y trouvent
#
# Entrée :
#   - paramètres :
#	- largeurs : largeurs des colonnes pour la spécification du tableau
#		au format {largeur1 largeur2 ... largeurn} (en %)
#	- titre : spécification des titres (format et valeur)
#		au format {type valeur} où type = texte ou html
#	- spec : spécification des lignes normales
#		au format {id type defval} où
#			- id : identificateur de la colonne dans la table
#				et nom du champ de formulaire (idNNN ou idnNNN)
#			- type : texte, string N, bool, menu L, textarea L H
#			- defval : valeur par défaut pour les nouvelles lignes
#	- dbfd : accès à la base
#	- sql : requête select contenant en particulier les champs "id"
#	- idnum : nom de la colonne représentant l'identificateur numérique
#	- tabvar : tableau passé par variable, vide en entrée
# Sortie :
#   - valeur de retour : chaîne vide si ok, message d'erreur si pb
#   - paramètre tabvar : un tableau HTML complet
#
# Historique
#   2001/11/01 : pda      : spécification et documentation
#   2001/11/01 : pda      : codage
#   2002/05/03 : pda/jean : type menu
#   2002/05/06 : pda/jean : type textarea
#   2002/05/16 : pda      : conversion à arrgen
#

proc edition-tableau {largeurs titre spec dbfd sql idnum tabvar} {
    upvar $tabvar tab

    #
    # Petit test d'intégrité sur le nombre de colonnes (doit être
    # identique dans les largeurs, dans les titres et dans les
    # lignes normales
    #

    if {[llength $titre] != [llength $spec] || \
	[llength $titre] != [llength $largeurs]} then {
	return "Interne (edition-tableau): Spécification de tableau invalide"
    }

    #
    # Construire la spécification du tableau : comme c'est fastidieux,
    # on l'a mis dans une procédure à part.
    #

    set spectableau [edition-tableau-motif $largeurs $titre $spec]
    set donnees {}

    #
    # Sortir le titre
    #

    set ligne {}
    lappend ligne Titre
    foreach t $titre {
	lappend ligne [lindex $t 1]
    }
    lappend donnees $ligne

    #
    # Sortir les lignes du tableau
    #

    pg_select $dbfd $sql tabsql {
	lappend donnees [edition-ligne $spec tabsql $idnum]
    }

    #
    # Ajouter de nouvelles lignes
    #

    foreach s $spec {
	set clef [lindex $s 0]
	set defval [lindex $s 2]
	set tabdef($clef) $defval
    }

    for {set i 1} {$i <= 5} {incr i} {
	set tabdef($idnum) "n$i"
	lappend donnees [edition-ligne $spec tabdef $idnum]
    }

    #
    # Transformer le tout en joli tableau
    #

    set tab [::arrgen::output "html" $spectableau $donnees]

    #
    # Tout s'est bien passé !
    #

    return ""
}

#
# Construit une spécification de tableau pour arrgen à partir des
# paramètres passés à edition-tableau
#
# Entrée :
#   - paramètres :
#	- largeurs : largeurs des colonnes pour la spécification du tableau
#	- titre : spécification des titres (format et valeur)
#	- spec : spécification des lignes normales
# Sortie :
#   - valeur de retour : une spécification de tableau prête pour arrgen
#
# Note : voir la signification des paramètres dans edition-tableau
#
# Historique
#   2001/11/01 : pda : conception et documentation
#   2002/05/16 : pda : conversion à arrgen
#

proc edition-tableau-motif {largeurs titre spec} {
    #
    # Construire le motif des titres d'abord
    #
    set motif_titre "motif {Titre} {"
    foreach t $titre {
	append motif_titre "vbar {yes} "
	append motif_titre "chars {bold} "
	append motif_titre "align {center} "
	append motif_titre "column { "
	append motif_titre "  botbar {yes} "
	if {[string compare [lindex $t 0] "texte"] != 0} then {
	    append motif_titre "  format {raw} "
	}
	append motif_titre "} "
    }
    append motif_titre "vbar {yes} "
    append motif_titre "} "

    #
    # Ensuite, les lignes normales
    #
    set motif_normal "motif {Normal} {"
    foreach t $spec {
	append motif_normal "topbar {yes} "
	append motif_normal "vbar {yes} "
	append motif_normal "column { "
	append motif_normal "  align {center} "
	append motif_normal "  botbar {yes} "
	set type [lindex [lindex $t 1] 0]
	if {[string compare $type "texte"] != 0} then {
	    append motif_normal "  format {raw} "
	}
	append motif_normal "} "
    }
    append motif_normal "vbar {yes} "
    append motif_normal "} "

    #
    # Et enfin les spécifications globales
    #
    set spectableau "global { chars {12 normal} "
    append spectableau "columns {$largeurs} } $motif_titre $motif_normal"

    return $spectableau
}

#
# Présente le contenu d'une ligne d'une table
#
# Entrée :
#   - paramètres :
#	- spec : spécification des lignes normales, voir edition-tableau
#	- tab : tableau indexé par les champs spécifiés dans spec
#	- idnum : nom de la colonne représentant l'identificateur numérique
# Sortie :
#   - valeur de retour : une ligne de tableau prête pour arrgen
#
# Historique
#   2001/11/01 : pda      : spécification et documentation
#   2001/11/01 : pda      : conception
#   2002/05/03 : pda/jean : ajout du type menu
#   2002/05/06 : pda/jean : ajout du type textarea
#   2002/05/16 : pda      : conversion à arrgen
#

proc edition-ligne {spec tabvar idnum} {
    upvar $tabvar tab

    set ligne {Normal}
    foreach s $spec {
	set clef [lindex $s 0]
	set valeur $tab($clef)

	set type [lindex [lindex $s 1] 0]
	set opt [lindex [lindex $s 1] 1]

	set num $tab($idnum)
	set ref $clef$num

	switch $type {
	    texte {
		set item $valeur
	    }
	    string {
		set item [::webapp::form-text $ref 1 $opt 0 $valeur]
	    }
	    bool {
		set checked ""
		if {$valeur} then { set checked " CHECKED" }
		set item "<INPUT TYPE=checkbox NAME=$ref VALUE=1$checked>"
	    }
	    menu {
		set sel 0
		set i 0
		foreach e $opt {
		    # recherche obligatoirement le premier élément de la liste
		    set id [lindex $e 0]
		    if {[string equal $id $valeur]} then {
			set sel $i
		    }
		    incr i
		}
		set item [::webapp::form-menu $ref 1 0 $opt [list $sel]]
	    }
	    textarea {
		set largeur [lindex $opt 0]
		set hauteur [lindex $opt 1]
		set item [::webapp::form-text $ref $hauteur $largeur 0 $valeur]
	    }
	}
	lappend ligne $item
    }

    return $ligne
}

#
# Récupère les modifications d'un formulaire généré par edition-tableau
# et les enregistre dans la base si nécessaire
#
# Entrée :
#   - paramètres :
#	- dbfd : accès à la base
#	- spec : spécification des colonnes à modifier (voir plus bas)
#	- idnum : nom de la colonne représentant l'identificateur numérique
#	- table : nom de la table à modifier
#	- tabvar : tableau contenant les champs du formulaire
# Sortie :
#   - valeur de retour : chaîne vide si ok, message d'erreur si pb
#
# Notes :
#   - le format du paramètre "spec" est {{colonne defval} ...}, où :
#	- colonne est l'identificateur de la colonne dans la table
#	- defval, si présent, indique la valeur par défaut à mettre dans
#		la table car la valeur n'est pas fournie dans le formulaire
#   - la première colonne de "spec" est utilisée pour savoir s'il faut
#	ajouter ou supprimer l'entrée correspondante
#
# Historique
#   2001/11/02 : pda      : spécification et documentation
#   2001/11/02 : pda      : codage
#   2002/05/03 : pda/jean : suppression contrainte sur les tickets
#

proc enregistrer-tableau {dbfd spec idnum table tabvar} {
    upvar $tabvar ftab

    #
    # Verrouillage de la table concernée
    #

    if {! [::pgsql::execsql $dbfd "BEGIN WORK ; LOCK $table" msg]} then {
	return "Verrouillage impossible ('$msg')"
    }

    #
    # Dernier numéro d'enregistrement attribué
    #

    set max 0
    pg_select $dbfd "SELECT MAX($idnum) FROM $table" tab {
	set max $tab(max)
    }

    #
    # La clef pour savoir si une entrée doit être détruite (pour les
    # id existants) ou ajoutée (pour les nouveaux id)
    #


    set clef [lindex [lindex $spec 0] 0]

    #
    # Parcours des numéros déjà existants dans la base
    #

    set id 1

    for {set id 1} {$id <= $max} {incr id} {
	if {[info exists ftab(${clef}${id})]} {
	    remplir-tabval $spec "" $id ftab tabval

	    if {[string length $tabval($clef)] == 0} then {
		#
		# Destruction de l'entrée.
		#

		set ok [retirer-entree $dbfd msg $id $idnum $table]
		if {! $ok} then {
		    ::pgsql::execsql $dbfd "ABORT WORK" m
		    #
		    # En cas de destruction impossible, il faut
		    # dire ce qu'on n'arrive pas à supprimer.
		    # Pour cela, il faut rechercher le vieux nom dans
		    # la base.
		    #

		    set oldclef ""
		    pg_select $dbfd "SELECT $clef FROM $table \
				    WHERE $idnum = $id" t {
			set oldclef $t($clef)
		    }
		    return "Erreur dans la suppression de '$oldclef' ('$msg')"
		}
	    } else {
		#
		# Modification de l'entrée
		#

		set ok [modifier-entree $dbfd msg $id $idnum $table tabval]
		if {! $ok} then {
		    ::pgsql::execsql $dbfd "ABORT WORK" m
		    return "Erreur dans la modification de '$tabval($clef)' ('$msg')"
		}
	    }
	}
    }

    #
    # Nouvelles entrées
    #

    set idnew 1
    while {[info exists ftab(${clef}n${idnew})]} {
	remplir-tabval $spec "n" $idnew ftab tabval

	if {[string length $tabval($clef)] > 0} then {
	    #
	    # Ajout de l'entrée
	    #

	    set ok [ajouter-entree $dbfd msg $table tabval]
	    if {! $ok} then {
		::pgsql::execsql $dbfd "ABORT WORK" m
		return "Erreur dans l'ajout de '$tabval($clef)' ('$msg')"
	    }
	}

	incr idnew
    }

    #
    # Déverrouillage, et enregistrement des modifications avant la sortie
    #

    if {! [::pgsql::execsql $dbfd "COMMIT WORK" msg]} then {
	::pgsql::execsql $dbfd "ABORT WORK" m
	return "Déverrouillage impossible, modification annulée ('$msg')"
    }

    return ""
}

#
# Lit les champs dans les formulaires, en complétant éventuellement pour
# les champs booléens (checkbox) qui peuvent ne pas être présents.
#
# Entrée :
#   - paramètres :
#	- spec : voir enregistrer-tableau
#	- prefixe : "" (entrée existante) ou "n" (nouvelle entrée)
#	- num : numéro de l'entrée
#	- ftabvar : le tableau issu de get-data
#	- tabvalvar : le tableau à remplir
# Sortie :
#   - valeur de retour : aucune
#   - paramètre tabvalvar : contient les champs
#
# Note :
#   - si spec contient {{login} {nom}}, prefixe contient "n" et num "5"
#     alors on cherche ftab(loginn5) et ftab(nomn5)
#	 et on met ça dans tabval(login) et tabval(nom)
#
# Historique :
#   2001/04/01 : pda : conception
#   2001/04/03 : pda : documentation
#   2001/11/02 : pda : reprise et extension
#

proc remplir-tabval {spec prefixe num ftabvar tabvalvar} {
    upvar $ftabvar ftab
    upvar $tabvalvar tabval

    foreach coldefval $spec {

	set col [lindex $coldefval 0]

	if {[llength $coldefval] == 2} then {
	    #
	    # Valeur par défaut : on ne la prend pas dans le formulaire
	    #

	    set val [lindex $coldefval 1]

	} else {

	    #
	    # Pas de valeur par défaut : on recherche dans le formulaire.
	    # Si on ne trouve pas dans le formulaire, c'est un booléen
	    # qui n'a pas été fourni, on prend 0 comme valeur.
	    #

	    set form ${col}${prefixe}${num}

	    if {[info exists ftab($form)]} then {
		set val [string trim [lindex $ftab($form) 0]]
	    } else {
		set val {0}
	    }
	}

	set tabval($col) $val
    }
}

#
# Modification d'une entrée
#
# Entrée :
#   - paramètres :
#	- dbfd : accès à la base
#	- msg : variable contenant, en retour, le message d'erreur éventuel
#	- id : l'id (valeur) de l'entrée à modifier
#	- idnum : nom de la colonne des id de la table
#	- table : nom de la table à modifier
#	- tabvalvar : tableau contenant les valeurs à modifier
# Sortie :
#   - valeur de retour : 1 si ok, 0 si erreur
#   - paramètres :
#	- msg : message d'erreur si erreur
#
# Historique :
#   2001/04/01 : pda : conception
#   2001/04/03 : pda : documentation
#   2001/11/02 : pda : généralisation
#   2004/01/20 : pda/jean : ajout d'un attribut NULL si chaîne vide (pour ipv6)
#

proc modifier-entree {dbfd msg id idnum table tabvalvar} {
    upvar $msg m
    upvar $tabvalvar tabval

    #
    # Tout d'abord, il n'y a pas besoin de modifier quoi que ce soit
    # si toutes les valeurs sont identiques.
    #

    set different 0
    pg_select $dbfd "SELECT * FROM $table WHERE $idnum = $id" tab {
	foreach attribut [array names tabval] {
	    if {[string compare $tabval($attribut) $tab($attribut)] != 0} then {
		set different 1
		break
	    }
	}
    }

    set ok 1

    if {$different} then {
	#
	# C'est différent, il faut donc y aller...
	#

	set liste {}
	foreach attribut [array names tabval] {
	    if {[string equal $tabval($attribut) ""]} then {
		set v "NULL"
	    } else {
		set v "'[::pgsql::quote $tabval($attribut)]'"
	    }
	    lappend liste "$attribut = $v"
	}
	set sql "UPDATE $table SET [join $liste ,] WHERE $idnum = $id"
	set ok [::pgsql::execsql $dbfd $sql m]
    }

    return $ok
}

#
# Retrait d'une entree
#
# Entrée :
#   - paramètres :
#	- dbfd : accès à la base
#	- msg : variable contenant, en retour, le message d'erreur éventuel
#	- id : l'id (valeur) de l'entrée à modifier
#	- idnum : nom de la colonne des id de la table
#	- table : nom de la table à modifier
# Sortie :
#   - valeur de retour : 1 si ok, 0 si erreur
#   - paramètres :
#	- msg : message d'erreur si erreur
#
# Historique :
#   2001/04/03 : pda      : conception
#   2001/11/02 : pda      : généralisation
#   2002/05/03 : pda/jean : suppression contrainte sur les tickets
#

proc retirer-entree {dbfd msg id idnum table} {
    upvar $msg m

    set sql "DELETE FROM $table WHERE $idnum = $id"
    set ok [::pgsql::execsql $dbfd $sql m]

    return $ok
}

#
# Ajout d'une entrée
#
# Entrée :
#   - paramètres :
#	- dbfd : accès à la base
#	- msg : variable contenant, en retour, le message d'erreur éventuel
#	- table : nom de la table à modifier
#	- tabvalvar : tableau contenant les valeurs à ajouter
# Sortie :
#   - valeur de retour : 1 si ok, 0 si erreur
#   - paramètres :
#	- msg : message d'erreur si erreur
#
# Historique :
#   2001/04/01 : pda : conception
#   2001/04/03 : pda : documentation
#   2001/11/02 : pda : généralisation
#   2004/01/20 : pda/jean : ajout d'un attribut NULL si chaîne vide (pour ipv6)
#

proc ajouter-entree {dbfd msg table tabvalvar} {
    upvar $msg m
    upvar $tabvalvar tabval

    #
    # Nom des colonnes
    #
    set cols [array names tabval]

    #
    # Valeur des colonnes
    #
    set vals {}
    foreach c $cols {
	if {[string equal $tabval($c) ""]} then {
	    set v "NULL"
	} else {
	    set v "'[::pgsql::quote $tabval($c)]'"
	}
	lappend vals $v
    }

    set sql "INSERT INTO $table ([join $cols ,]) VALUES ([join $vals ,])"
    set ok [::pgsql::execsql $dbfd $sql m]
    return $ok
}

##############################################################################
# Accès aux paramètres de configuration
##############################################################################

#
# Lecture des paramètres de configuration
#
# Entrée :
#   - paramètres :
#	- dbfd : accès à la base
#	- clef : clef de configuration
# Sortie :
#   - valeur de retour : clef de configuration
#
# Historique
#   2001/03/21 : pda     : conception
#   2003/12/08 : pda     : reprise de sos
#

proc getconfig {dbfd clef} {
    set valeur {}
    pg_select $dbfd "SELECT * FROM config WHERE clef = '$clef'" tab {
	set valeur $tab(valeur)
    }
    return $valeur
}

#
# Écriture des paramètres de configuration
#
# Entrée :
#   - paramètres :
#	- dbfd : accès à la base
#	- clef : clef de configuration
#	- valeur : la valeur de la clef
#	- varmsg : message d'erreur lors de l'écriture, si besoin
# Sortie :
#   - valeur de retour : 1 si ok, ou 0 en cas d'erreur
#   - paramètre varmsg : message d'erreur éventuel
#
# Historique
#   2001/03/21 : pda     : conception
#   2003/12/08 : pda     : reprise de sos
#

proc setconfig {dbfd clef valeur varmsg} {
    upvar $varmsg msg

    set r 0
    set sql "DELETE FROM config WHERE clef = '$clef'"
    if {[::pgsql::execsql $dbfd $sql msg]} then {
	set v [::pgsql::quote $valeur]
	set sql "INSERT INTO config VALUES ('$clef', '$v')"
	if {[::pgsql::execsql $dbfd $sql msg]} then {
	    set r 1
	}
    }

    return $r
}
