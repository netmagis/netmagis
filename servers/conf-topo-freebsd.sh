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
#

. /etc/rc.subr
. /etc/network.subr

load_rc_config 'XXX'

##############################################################################
# Fonctions de génération des différentes parties
##############################################################################

#
# Génération de la partie "hosts"
#
# Historique
#   2010/06/28 : pda : preuve de concept
#

gen_host ()
{
    host=`echo $hostname | sed 's/\..*//'`
    domain=`echo $hostname | sed 's/[^.]*\.//'`
    echo "hostname $host"
    echo "ip domain-name $domain"
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

gen_host
gen_if
gen_def_router
