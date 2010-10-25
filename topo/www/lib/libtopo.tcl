#
# Librairie TCL pour l'application de topologie
#
# Historique
#   2006/06/05 : pda             : conception de la partie topo
#   2006/05/24 : pda/jean/boggia : conception de la partie metro
#   2007/01/11 : pda             : fusion des deux parties
#   2008/10/01 : pda             : ajout de message de statut de la topo
#

set libconf(topodir)	%TOPODIR%
set libconf(graph)	%GRAPH%
set libconf(status)	%STATUS%

set libconf(extractcoll)	"%TOPODIR%/bin/extractcoll %s < %GRAPH%"

array set libconf {
    freq:2412	1
    freq:2417	2
    freq:2422	3
    freq:2427	4
    freq:2432	5
    freq:2437	6
    freq:2442	7
    freq:2447	8
    freq:2452	9
    freq:2457	10
    freq:2462	11
}

#
# Initialiser l'accès à la topo pour les scripts CGI
#
# Entrée :
#   - paramètres :
#	- nologin : nom du fichier testé pour le mode "maintenance"
#	- base : nom de la base
#	- pageerr : fichier HTML contenant une page d'erreur
#	- attr : attribut nécessaire pour exécuter le script ("corresp"/"admin")
#	- form : les paramètres du formulaire
#	- _ftab : tableau contenant en retour les champs du formulaire
#	- _dbfd : accès à la base en retour
#	- _uid : login de l'utilisateur, en retour
#	- _tabuid : tableau contenant les caractéristiques de l'utilisateur
#		(cf lire-utilisateur)
#	- _ouid : login de l'utilisateur original, si substitué, ou chaîne vide
#	- _tabouid : idem tabuid pour l'utilisateur original
#	- _urluid : élément d'url à ajouter en cas de subsitution d'uid
#	- _msgsta : message de status
# Sortie :
#   - valeur de retour : aucune
#   - paramètres :
#	- _ftab, _dbfd, _uid, _tabuid, _ouid, _tabouid, _msgsta : cf ci-dessus
#   - variables dont le nom est défini dans $form : modifiées
#
# Remarque
#  - le champ de formulaire uid est systématiquement ajouté aux champs
#
# Historique
#   2007/01/11 : pda              : conception
#   2008/10/01 : pda              : ajout msgsta
#

proc init-topo {nologin base pageerr attr form _ftab _dbfd _uid _tabuid _ouid _tabouid _urluid _msgsta} {
    global libconf

    upvar $_ftab ftab
    upvar $_dbfd dbfd
    upvar $_uid uid
    upvar $_tabuid tabuid
    upvar $_ouid ouid
    upvar $_tabouid tabouid
    upvar $_urluid urluid
    upvar $_msgsta msgsta

    #
    # Pour le cas où on est en mode maintenance
    #

    ::webapp::nologin $nologin %ROOT% $pageerr

    #
    # Accès à la base SQL DNS
    #

    set dbfd [ouvrir-base $base msg]
    if {[string length $dbfd] == 0} then {
	::webapp::error-exit $pageerr $msg
    }

    #
    # Le login de l'utilisateur (la page est protégée par mot de passe)
    #

    set uid [::webapp::user]
    if {[string equal $uid ""]} then {
	::webapp::error-exit $pageerr \
		"Pas de login : l'authentification a échoué."
    }

    #
    # Les informations relatives à l'utilisateur
    #

    set msg [lire-utilisateur $dbfd $uid tabuid]
    if {! [string equal $msg ""]} then {
	::webapp::error-exit $pageerr $msg
    }

    #
    # Est-ce que la page est réservée à des administrateurs
    # (correspondant ou administrateur) ? Si oui, l'utilisateur
    # doit être dans la base DNS et présent.
    #

    if {! [string equal $attr ""]} then {
	#
	# Si l'utilisateur n'est pas trouvé dans la base DNS
	# alors erreur (reproduit l'erreur dans lire-correspondant-...
	# que nous ignorons plus haut).
	#

	if {$tabuid(idcor) == -1} then {
	    ::webapp::error-exit $pageerr \
		"'$uid' n'est pas dans la base des correspondants."
	}

	#
	# Si le correspondant n'est plus marqué comme "présent" dans la base,
	# on ne lui autorise pas l'accès à l'application
	#

	if {! $tabuid(present)} then {
	    ::webapp::error-exit $pageerr \
		"Désolé, $uid, mais vous n'êtes pas habilité."
	}
	
	#
	# On vérifie si la classe de l'utilisateur est autorisée
	# à accéder cgi, en fonction du niveau demandé par le cgi ($attr)
	# 
	#

        switch -- $attr {
            corresp {
		# si on arrive là, c'est qu'on est correspondant
            }
            admin {
		if {! $tabuid(admin)} then {
                    ::webapp::error-exit $pageerr \
                        "Désolé, $uid, mais vous n'avez pas les droits suffisants"
                }
            }
            default {
                ::webapp::error-exit $pageerr \
                        "Erreur interne sur demande d'attribut '$attr'"
            }
        }
    }

    #
    # Récupération des paramètres du formulaire et importation des
    # valeurs dans des variables.
    #

    lappend form {uid 0 1}
    if {[llength [::webapp::get-data ftab $form]] == 0} then {
	::webapp::error-exit $pageerr \
	    "Formulaire non conforme aux spécifications"
    }

    uplevel 1 [list ::webapp::import-vars $_ftab]

    #
    # Substitution d'utilisateur
    #

    set nuid [string trim [lindex $ftab(uid) 0]]
    set urluid ""
    if {! [string equal $nuid ""]} then {
	if {$tabuid(admin)} then {
	    array set tabouid [array get tabuid]
	    array unset tabuid

	    set ouid $uid
	    set uid $nuid

	    set msg [lire-utilisateur $dbfd $uid tabuid]
	    if {! [string equal $msg ""]} then {
		::webapp::error-exit $pageerr $msg
	    }

	    set urluid "uid=[::webapp::post-string $uid]"
	}
    }

    #
    # Lit le statut général de la topo
    # (seulement si l'utilisateur cible est admin)
    #

    set msgsta ""
    if {$tabuid(admin)} then {
	set f $libconf(status)
	if {[file exists $f] && ![catch {set fd [open $f "r"]}]} then {
	    if {[gets $fd date] > 0} then {
		set msg [::webapp::html-string [read $fd]]
		regsub -all "\n" $msg "<br>" msg

		set texte [::webapp::helem "p" "Erreur de topo"]
		append texte [::webapp::helem "p" \
					    [::webapp::helem "font" $msg \
						    "color" "#ff0000" \
						] \
				    ]
		append texte [::webapp::helem "p" "... depuis $date"]

		set msgsta [::webapp::helem "div" $texte "class" "alerte"]
	    }
	    close $fd
	}
    }
}


#
# Lit les informations d'un utilisateur
#
# Entrée :
#   - paramètres :
#	- dbfd : commande pour afficher le graphe en ascii
#	- uid : login de l'utilisateur
#	- _tabuid : tableau en retour, contenant les champs
#		login	login demandé
#		idcor	id dans la base
#		idgrp	id du groupe dans la base
#		groupe	nom du groupe
#		present	1 si marqué "présent" dans la base
#		admin	1 si admin
#		reseaux	liste des réseaux autorisés
#		eq	regexp des équipements autorisés
#		flags	flags -n/-e à utiliser dans les commandes topo
# Sortie :
#   - valeur de retour : message d'erreur ou chaîne vide
#   - paramètre _tabuid : cf ci-dessus
#
# Historique
#   2007/01/11 : pda             : conception
#

proc lire-utilisateur {dbfd uid _tabuid} {
    upvar $_tabuid tabuid

    #
    # Le segment de code qui suit a des ressemblances avec
    # la fonction "lire-correspondant-par-login" de la libdns,
    # mais celle-ci utilise le package auth que nous ne pouvons
    # pas utiliser.
    #

    set tabuid(login)		$uid

    #
    # Essayer de lire les caractéristiques de l'utilisateur dans la
    # base DNS : c'est alors un correspondant.
    #

    set quid [::pgsql::quote $uid]
    set tabuid(idcor) -1
    set sql "SELECT * FROM corresp, groupe
			WHERE corresp.login = '$quid'
			     AND corresp.idgrp = groupe.idgrp"
    pg_select $dbfd $sql tab {
	set tabuid(idcor)	$tab(idcor)
	set tabuid(idgrp)	$tab(idgrp)
	set tabuid(present)	$tab(present)
	set tabuid(groupe)	$tab(nom)
	set tabuid(admin)	$tab(admin)
    }

    if {$tabuid(idcor) == -1} then {
	return ""
    }

    #
    # Lire les CIDR des réseaux autorisés (fonction de la libdns)
    #

    set tabuid(reseaux) [liste-reseaux-autorises $dbfd $tabuid(idgrp) "dhcp"]

    #
    # Lire les équipements
    #

    set tabuid(eq) [lire-eq-autorises $dbfd $tabuid(groupe)]

    #
    # Construire les flags
    #

    set flags {}
    if {! $tabuid(admin)} then {
	if {! [string equal $tabuid(eq) ""]} then {
	    lappend flags "-e" $tabuid(eq)
	}
	foreach r $tabuid(reseaux) {
	    set r4 [lindex $r 1]
	    if {! [string equal $r4 ""]} then {
		lappend flags "-n" $r4
	    }
	    set r6 [lindex $r 2]
	    if {! [string equal $r6 ""]} then {
		lappend flags "-n" $r6
	    }
	}
    }
    set tabuid(flags) [join $flags " "]

    return ""
}

#
# Utilitaire pour le tri des interfaces : compare deux noms d'interface
#
# Entrée :
#   - paramètres :
#       - i1, i2 : deux noms d'interfaces
# Sortie :
#   - valeur de retour : -1, 0 ou 1 (cf string compare)
#
# Historique
#   2006/12/29 : pda : conception
#

proc compare-interfaces {i1 i2} {
    #
    # Isoler tous les mots
    # Ex: "GigabitEthernet1/0/1" -> " GigabitEthernet 1/0/1"
    #
    regsub -all {[A-Za-z]+} $i1 { & } i1
    regsub -all {[A-Za-z]+} $i2 { & } i2
    #
    # Retirer tous les caractères spéciaux
    # Ex: " GigabitEthernet 1/0/1" -> " GigabitEthernet 1 0 1"
    #
    regsub -all {[^A-Za-z0-9]+} $i1 { } i1
    regsub -all {[^A-Za-z0-9]+} $i2 { } i2
    #
    # Retirer les espaces superflus
    #
    set i1 [string trim $i1]
    set i2 [string trim $i2]

    #
    # Comparer mot par mot
    #
    set r 0
    foreach m1 [split $i1] m2 [split $i2] {
	if {[regexp {^[0-9]+$} $m1] && [regexp {^[0-9]+$} $m2]} then {
	    if {$m1 < $m2} then {
		set r -1
	    } elseif {$m1 > $m2} then {
		set r 1
	    } else {
		set r 0
	    }
	} else {
	    set r [string compare $m1 $m2]
	}
	if {$r != 0} then {
	    break
	}
    }

    return $r
}

#
# Utilitaire pour le tri des adresses IP : compare deux adresses IP
#
# Entrée :
#   - paramètres :
#       - ip1, ip2 : les adresses à comparer
# Sortie :
#   - valeur de retour : -1, 0 ou 1
#
# Historique
#   2006/06/20 : pda             : conception
#   2006/06/22 : pda             : documentation
#

proc comparer-ip {ip1 ip2} {
    set ip1 [::ip::normalize $ip1]
    set v1  [::ip::version $ip1]
    set ip2 [::ip::normalize $ip2]
    set v2  [::ip::version $ip2]

    set r 0
    if {$v1 == 4 && $v2 == 4} then {
	set l1 [split [::ip::prefix $ip1] "."]
	set l2 [split [::ip::prefix $ip2] "."]
	foreach e1 $l1 e2 $l2 {
	    if {$e1 < $e2} then {
		set r -1
		break
	    } elseif {$e1 > $e2} then {
		set r 1
		break
	    }
	}
    } elseif {$v1 == 6 && $v2 == 6} then {
	set l1 [split [::ip::prefix $ip1] ":"]
	set l2 [split [::ip::prefix $ip2] ":"]
	foreach e1 $l1 e2 $l2 {
	    if {"0x$e1" < "0x$e2"} then {
		set r -1
		break
	    } elseif {"0x$e1" > "0x$e2"} then {
		set r 1
		break
	    }
	}
    } else {
	set r [expr $v1 < $v2]
    }
    return $r
}

#
# Indique si une adresse IP est dans une classe
#
# Entrée :
#   - paramètres :
#       - ip : adresse IP (ou CIDR) à tester
#	- net : CIDR de référence
# Sortie :
#   - valeur de retour : 0 (ip pas dans net) ou 1 (ip dans net)
#
# Historique
#   2006/06/22 : pda             : conception
#

proc ip-in {ip net} {
    set v [::ip::version $net]
    if {[::ip::version $ip] != $v} then {
	return 0
    }

    set defmask [expr "$v==4 ? 32 : 128"]

    set ip [::ip::normalize $ip]
    set net [::ip::normalize $net]

    set mask [::ip::mask $net]
    if {[string equal $mask ""]} then {
	set mask $defmask
    }

    set prefnet [::ip::prefix $net]
    regsub {(/[0-9]+)?$} $ip "/$mask" ip2
    set prefip  [::ip::prefix $ip2]

    return [string equal $prefip $prefnet]
}

#
# Valide l'id du point de collecte par rapport aux droits du correspondant.
#
# Entrée :
#   - paramètres :
#	- dbfd : accès à la base
#	- id : id du point de collecte (ou id+id+...)
#	- _tabcor : infos sur le correspondant
#	- _titre : titre du graphe
# Sortie :
#   - valeur de retour : message d'erreur ou chaîne vide
#   - paramètre _titre : titre du graphe trouvé
#
# Historique
#   2006/08/09 : pda/boggia      : conception
#   2006/12/29 : pda             : parametre vlan passé par variable
#   2008/07/30 : pda             : adaptation au nouvel extractcoll
#   2008/07/30 : pda             : codage de multiples id
#   2008/07/31 : pda             : ajout de |
#

proc verifier-metro-id {dbfd id _tabuid _titre} {
    upvar $_tabuid tabuid
    upvar $_titre titre
    global libconf

    #
    # Au cas où les id seraient multiples
    #

    set lid [split $id "+|"]

    #
    # Récupérer la liste des points de collecte
    #

    set cmd [format $libconf(extractcoll) $tabuid(flags)]

    if {[catch {set fd [open "| $cmd" "r"]} msg]} then {
	return "Impossible de lire les points de collecte: $msg"
    }

    while {[gets $fd ligne] > -1} {
	set l [split $ligne]
	set kw [lindex $l 0]
	set i  [lindex $l 1]
	set n [lsearch -exact $lid $i]
	if {$n >= 0} then {
	    set idtab($i) $ligne
	    if {[info exists firstkw]} then {
		if {! [string equal $firstkw $kw]} then {
		    return "Types de points de collecte divergents" 
		}
	    } else {
		set firstkw $kw
	    }
	    set lid [lreplace $lid $n $n]
	}
    }
    catch {close $fd}

    #
    # Erreur si id pas trouvé
    #

    if {[llength $lid] > 0} then {
	return "Point de collecte '$id' non trouvé"
    }

    #
    # Essayer de trouver un titre convenable
    # 

    set lid [array names idtab]
    switch [llength $lid] {
	0 {
	    return "Aucun point de collecte sélectionné"
	}
	1 {
	    set i [lindex $lid 0]
	    set l $idtab($i)
	    switch $firstkw {
		trafic {
		    set eq    [lindex $l 2]
		    set iface [lindex $l 4]
		    set vlan  [lindex $l 5]

		    set titre "Trafic sur"
		    if {! [string equal $vlan "-"]} then {
			append titre " le vlan $vlan"
		    }
		    append titre " de l'interface $iface de $eq"
		}
		nbauthwifi -
		nbassocwifi {
		    set eq    [lindex $l 2]
		    set iface [lindex $l 4]
		    set ssid  [lindex $l 5]

		    set titre "Nombre"
		    if {[string equal $firstkw "nbauthwifi"]} then {
			append titre " d'utilisateurs authentifiés" 
		    } else {
			append titre " de machines associées" 
		    }
		    append titre " sur le ssid $ssid de l'interface $iface de $eq"
		}
		default {
		    return "Erreur interne sur extractcoll"
		}
	    }
	}
	default {
	    switch $firstkw {
		trafic {
		    set titre "Trafic"
		    set le {}
		    foreach i $lid {
			set l $idtab($i)
			set eq    [lindex $l 2]
			set iface [lindex $l 4]
			set vlan  [lindex $l 5]

			set e "$eq/$iface"
			if {! [string equal $vlan "-"]} then {
			    append e ".$vlan"
			}
			lappend le $e
		    }
		    set le [join $le " et "]
		    append titre " sur $le"
		}
		nbauthwifi -
		nbassocwifi {
		    if {[string equal $firstkw "nbauthwifi"]} then {
			set titre "Nombre d'utilisateurs authentifiés"
		    } else {
			set titre "Nombre de machines associées"
		    }
		    foreach i $lid {
			set l $idtab($i)
			set eq    [lindex $l 2]
			set iface [lindex $l 4]
			set ssid  [lindex $l 5]

			set e "$eq/$iface ($ssid)"
			lappend le $e
		    }
		    set le [join $le " et "]
		    append titre " sur $le"
		}
		default {
		    return "Erreur interne sur extractcoll"
		}
	    }
	}
    }

    return ""
}

#
# Récupère une expression régulière caractérisant la liste des
# équipements autorisés.
#
# XXX : cette fonction est à réécrire pour utiliser la base DNS
#	et à intégrer dans la libdns.tcl
# XXX : remplacer groupe par idgrp
#
# Entrée :
#   - paramètres :
#       - dbfd : accès à la base DNS
#	- groupe : nom du groupe DNS (XXX : à supprimer ASAP)
#	- idgrp : id du groupe dans la base DNS (XXX : à utiliser à la place)
# Sortie :
#   - valeur de retour : expression régulière, ou chaîne vide
#
# Historique
#   2006/08/10 : pda/boggia      : création
#

proc lire-eq-autorises {dbfd groupe} {
    set fd [open "%DESTDIR%/lib/droits-eq.data" "r"]
    set r ""
    while {[gets $fd ligne] > -1} {
	regsub "#.*" $ligne "" $ligne
	set ligne [string trim $ligne]
	if {[regexp {^([^\s]+)\s+(.*)} $ligne bidon g re]} then {
	    if {[string equal $g $groupe]} then {
		set r $re
		break
	    }
	}
    }
    close $fd
    return $r
}

#
# Récupère un graphe du métrologiseur et le renvoie
#
# Entrée :
#   - paramètres :
#       - url : l'URL pour aller chercher le graphe sur le métrologiseur
#	- err : une page d'erreur le cas échéant
# Sortie :
#   - aucune sortie, le graphe est récupéré et renvoyé sur la sortie standard
#	avec l'en-tête HTTP qui va bien
#
# Historique
#   2006/05/17 : jean            : création pour dhcplog
#   2006/08/09 : pda/boggia      : récupération, mise en fct et en librairie
#

# cf /local/services/www/sap/dhcplog/bin/gengraph

proc gengraph {url err} {
    package require http

    set token [::http::geturl $url]
    set status [::http::status $token]

    if {![string equal $status "ok"]} then {
	set code [::http::code $token]
	::webapp::error-exit $err "Accès impossible ($code)"
    }

    upvar #0 $token state

    # 
    # Déterminer le type d'image
    # 

    array set meta $state(meta)
    switch -exact $meta(Content-Type) {
	image/png {
	    set contenttype "png"
	}
	image/jpeg {
	    set contenttype "jpeg"
	}
	image/gif {
	    set contenttype "gif"
	}
	default {
	    set contenttype "html"
	}
    }

    # 
    # Renvoyer le résultat
    # 

    ::webapp::send $contenttype $state(body)
}

#
# Lit et décode une date entrée dans un formulaire
#
# Entrée :
#   - paramètres :
#       - date : la date saisie par l'utilisateur dans le formulaire
#	- heure : heure (00:00:00 pour l'heure de début, 23:59:59 pour fin)
# Sortie :
#   - valeur de retour : la date en format postgresql, ou "" si rien
#
# Historique
#   2000/07/18 : pda : conception
#   2000/07/23 : pda : ajout de l'heure
#   2001/03/12 : pda : mise en librairie
#   2008/07/30 : pda : ajout cas spécial pour 24h (= 23:59:59)
#

proc decoder-date {date heure} {
    set date [string trim $date]
    if {[string length $date] == 0} then {
	set datepg ""
    }
    if {[string equal $heure "24"]} then {
	set heure "23:59:59"
    }
    set liste [split $date /]
    switch [llength $liste] {
	1	{
	    set jj   [lindex $liste 0]
	    set mm   [clock format [clock seconds] -format "%m"]
	    set yyyy [clock format [clock seconds] -format "%Y"]
	    set datepg "$mm/$jj/$yyyy $heure"
	}
	2	{
	    set jj   [lindex $liste 0]
	    set mm   [lindex $liste 1]
	    set yyyy [clock format [clock seconds] -format "%Y"]
	    set datepg "$mm/$jj/$yyyy $heure"
	}
	3	{
	    set jj   [lindex $liste 0]
	    set mm   [lindex $liste 1]
	    set yyyy [lindex $liste 2]
	    set datepg "$mm/$jj/$yyyy $heure"
	}
	default	{
	    set datepg ""
	}
    }

    if {! [string equal $datepg ""]} then {
	if {[catch {clock scan $datepg}]} then {
	    set datepg ""
	}
    }
    return $datepg
}

#
# Convertit une fréquence radio 802.11b/g (bande des 2,4 GHz)
# en canal 802.11b/g
#
# Entrée :
#   - paramètres :
#       - freq : la fréquence
# Sortie :
#   - valeur de retour : chaîne exprimant le canal
#
# Historique
#   2008/07/30 : pda : conception
#   2008/10/17 : pda : canal "dfs"
#

proc conv-channel {freq} {
    global libconf

    switch -- $freq {
	dfs {
	    set channel "auto"
	}
	default {
	    if {[info exists libconf(freq:$freq)]} then {
		set channel $libconf(freq:$freq)
	    } else {
		set channel "$freq MHz"
	    }
	}
    }
    return $channel
}
