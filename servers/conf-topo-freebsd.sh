#!/bin/sh

#
# $Id$
#
# Génère un fichier de conf "simili-IOS Cisco" synthétisant
# l'ensemble des informations de configuration du serveur.
#
# Historique
#   2010/06/28 : pda : preuve de concept
#   2010/08/30 : pda : décomposition en fonctions
#   2010/08/30 : pda : svn-isation
#   2010/08/30 : pda : séparation des fonctions récupération / génération
#

. /etc/rc.subr
. /etc/network.subr

load_rc_config 'XXX'

##############################################################################
# Fonctions de récupération des différentes parties
##############################################################################

#
# Découpage du hostname
#
# Historique
#   2010/06/28 : pda : preuve de concept
#

get_host ()
{
    c_host=`echo $hostname | sed 's/\..*//'`
    c_domain=`echo $hostname | sed 's/[^.]*\.//'`
}

#
# Obtention de la liste des services. On le fait par examen des ports
# ouverts (netstat -a) au moment où le script s'exécute (et non via
# le fichier de conf).
# La fonction get_ports retourne la liste sous forme "tcp.22 tcp.25 ..."
# et la fonction get_services remplit la variable "c_services"
#
# Historique
#   2010/08/30 : pda : conception
#

# retourne une liste 
get_ports ()
{
    (
	netstat -an -f inet
	netstat -an -f inet6
    ) \
	| grep LISTEN \
	| grep "\*\.[0-9]" \
	| sed 's|\(...\).*\*.\([0-9][0-9]*\) .*|\1/\2|' \
	| sort -u
}

get_services ()
{
    c_services=""

    for protoport in `get_ports`
    do
	case "$protoport" in
	    tcp/22)   c_services="${c_services} ssh" ;;
	    tcp/80)   c_services="${c_services} http" ;;
	    tcp/25)   c_services="${c_services} smtp" ;;
	    tcp/111)  c_services="${c_services} portmap" ;;
	    tcp/389)  c_services="${c_services} ldap" ;;
	    tcp/443)  c_services="${c_services} https" ;;
	    tcp/631)  c_services="${c_services} ipp" ;;
	    tcp/636)  c_services="${c_services} ldaps" ;;
	    tcp/5432) c_services="${c_services} postgresql" ;;
	esac
    done
}

##############################################################################
# Fonctions de génération des différentes parties
##############################################################################

#
# Génération de la partie "hosts"
#
# Historique
#   2010/06/28 : pda : preuve de concept
#

gen_system ()
{
    echo "system {"
	gen_host
	gen_services
    echo "}"
}

gen_host ()
{
    echo "    host-name ${c_host};"
    echo "    domain-name ${c_domain};"
}

gen_services ()
{
    if [ "x${c_services}" != x ]
    then
	echo "    services {"
	for s in ${c_services}
	do
	    echo "        $s;"
	done
	echo "    }"
    fi
}

#
# Génération de la partie "interfaces"
#
# Historique
#   2010/06/28 : pda : preuve de concept
#

gen_if ()
{
    iflist=`list_net_interfaces`

    for i in `list_net_interfaces nodhcp`
    do
	echo "interface $i"
	ip=`ifconfig_getargs $i | sed 's/.*inet \([0-9]*\.[0-9]*\.[0-9]*\.[0-9]*\).*/\1/'`
	nm=`ifconfig_getargs $i | sed -n 's/.*netmask \([0-9]*\.[0-9]*\.[0-9]*\.[0-9]*\).*/\1/p'`
	if [ "${nm}" = "" ]
	then
	    po=`echo $ip | sed 's/\..*//'`
	    if [ $po -le 127 ]
	    then nm="255.0.0.0"
	    elif [ $po -le 191 ]
	    then nm="255.255.0.0"
	    elif [ $po -le 223 ]
	    then nm="255.255.255.0"
	    else nm="255.255.255.255"
	    fi
	fi
	echo "  description X"
	echo "  ip address $ip $nm"
    done

    for i in `list_net_interfaces dhcp`
    do
	echo "interface $i"
	echo "  description X"
	echo "  ip address dhcp"
    done
}

#
# Génération de la partie "default router"
#
# Historique
#   2010/06/28 : pda : preuve de concept
#

gen_def_router ()
{
    case ${defaultrouter} in
	[Nn][Oo] | '')
		;;
	*)
	    echo "ip default-gateway ${defaultrouter}"
	    ;;
    esac
}

##############################################################################
# Programme principal
##############################################################################

#
# Obtention des informations
#

get_host
get_services

#
# Génération de la pseudo-conf
#

gen_system
gen_if
gen_def_router
