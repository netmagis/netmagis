#!/bin/sh

#
# $Id$
#
# Génère un fichier de conf "simili-IOS Cisco" synthétisant l'ensemble
# des informations de configuration du serveur.
#
# Les informations sont issues de la configuration du serveur
# (typiquement rc.conf). La seule exception est la liste des
# ports ouverts, récupérée dynamiquement via netstat.
#
# Ce script ne doit utiliser que les outils fournis en standard
# par l'OS (sh, sed, etc.), afin de limiter les prérequis
# d'installation.
#
# Historique
#   2010/06/28 : pda : preuve de concept
#   2010/08/30 : pda : décomposition en fonctions
#   2010/08/30 : pda : svn-isation
#   2010/08/30 : pda : séparation des fonctions récupération / génération
#   2010/08/31 : pda : réécriture fonctions d'interface
#

. /etc/rc.subr
. /etc/network.subr

load_rc_config 'XXX'

erreur ()
{
    echo "$1" >&2
#    exit 1
}

##############################################################################
# Fonctions de récupération des différentes parties
##############################################################################

#
# Découpage du hostname
# Remplit :
#   c_host		(nom de machine)
#   c_domain		(domaine)
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
# La fonction get_ports retourne la liste sous forme "tcp/22 tcp/25 ..."
# et la fonction get_services remplit la variable "c_services"
# Remplit :
#   c_services		(liste de la forme "ssh smtp ...")
#
# Historique
#   2010/08/30 : pda : conception
#

# retourne une liste sous forme "tcp/22 tcp/25 ..."
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

# remplit la liste c_services avec le nom des services
get_services ()
{
    local protoport

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

#
# Obtention de la liste des interfaces qui sont configurées statiquement
# (i.e. qui ne sont pas configurées via DHCP).
#
# Remplit :
#   c_if		(liste d'interfaces)
#   c_if_<if>_desc	(description, ou vide)
#   c_if_<if>_vlans	(vide si interface native, ou liste de tags)
#   c_if_<if>_ip4	(adresse/preflen si interface native)
#   c_if_<if>_ip6	(adresse/preflen si interface native)
#   c_if_<if>_<v>_ip4	(adresse/preflen si interface taguée)
#   c_if_<if>_<v>_ip6	(adresse/preflen si interface taguée)
#
# Historique
#   2010/08/31 : pda : conception
#

# $1 : kw, $2 : valeur dans laquelle il faut chercher le kw
get_kw_value ()
{
    echo "$2" | sed -n "s/.*[[:<:]]${1}[[:>:]][[:space:]][[:space:]]*\([^[:space:]][^[:space:]]*\).*/\1/p"
}

# $1 : kw, $2 : valeur dans laquelle il faut supprimer le kw et sa valeur
rm_kw ()
{
    echo "$2" | sed -n "s/\(.*\)[[:<:]]${1}[[:>:]][[:space:]][[:space:]]*\([^[:space:]][^[:space:]]*\(.*\)/\1\2/p"
}


get_if_ip4 ()
{
    local a ip nm i pref p

    a="$1"

    ip=`get_kw_value inet "$a"`

    # cas simple : le préfixe est indiqué dans l'adresse IP (1.2.3.4/16)
    pref=`echo "$ip" | sed -n "s|.*/\([[:digit:]][[:digit:]]*\)|\1|p"`

    # cas complexe : il faut aller le chercher dans le netmask, s'il est présent
    if [ "${pref}" = "" ]
    then
	nm=`get_kw_value netmask "$a"`
	case "$nm" in
	    "")
		# on en revient aux vieilles classes (A, B ou C)
		po=`echo $ip | sed 's/\..*//'`
		if [ $po -le 127 ]
		then pref=8
		elif [ $po -le 191 ]
		then pref=16
		elif [ $po -le 223 ]
		then pref=24
		else pref=32
		fi
		;;
	    0x*)
		# en hexa
		pref=0
		for i in `echo $nm | sed -e 's/0x//' -e 's/./& /g' | tr A-Z a-z`
		do
		    case "$i" in
			f)	p=4 ;;
			e)	p=3 ;;
			c)	p=2 ;;
			8)	p=1 ;;
			0)	break ;;
			*)
			    erreur "netmask '$nm' non standard"
			    ;;
		    esac
		    pref=`expr $pref + $p`
		done
		;;
	    *)
		# en décimal
		pref=0
		po=`echo $nm | sed 's/\..*//'`
		nm=`echo $nm | sed 's/\([[:digit:]]*\)\..*/\1/'`
		stop=non
		for i in `(IFS=. ; echo $nm)`
		do
		    case "$i" in
			255)	p=8 ;;
			254)	p=7 ;;
			252)	p=6 ;;
			248)	p=5 ;;
			240)	p=4 ;;
			224)	p=3 ;;
			192)	p=2 ;;
			128)	p=1 ;;
			0)	break ;;
			*)
			    erreur "netmask '$nm' non standard"
			    ;;
		    esac
		    pref=`expr $pref + $p`
		done
		;;
	esac
	ip="${ip}/${pref}"
    fi
    echo "${ip}"
}

get_if_ip6 ()
{
}

get_if ()
{
    local i a phys vlan ip4 ip6

    c_if=""

    for i in `list_net_interfaces nodhcp`
    do
	a=`ifconfig_getargs $i`
	case "$a" in
	    "* vlandev *")
		#
		# Interface VLAN : clonée depuis une interface physique
		#
		phys=`get_kw vlandev "$a"`
		vlan=`get_kw vlan "$a"`
		a=`rm_kw vlandev "$a"`
		a=`rm_kw vlan "$a"`
		ip4=`get_if_ip4 "$a"`
		ip6=`get_if_ip6 "$a"`

		# Ajouter l'interface physique si elle n'y est pas déjà
		if [ "x`echo $c_if | sed -n '/[[:<:]]${phys}[[:>:]]/p'`" != x ]
		then
		    echo c_if="${c_if} $phys"
		    ####### TROUVER LA DESC DE $phys
		    eval "c_if_${phys}_desc=\"X\""
		fi

		eval "c_if_${phys}_vlans=\"\${c_if_${phys}_vlans} $vlan\""
		eval "c_if_${phys}_${vlan}_ip4=$ip4"
		eval "c_if_${phys}_${vlan}_ip6=$ip6"
		;;
	    "* vhid *")
		#
		# Interface CARP : on ignore
		#
		;;
	    *)
		#
		# Interface physique
		#

		ip4=`get_if_ip4 "$a"`
		ip6=`get_if_ip6 "$a"`

		c_if="${c_if} $i"
		####### TROUVER LA DESC DE $phys
		eval "c_if_${phys}_desc=\"X\""
		eval "c_if_${phys}_vlans=\"\""
		eval "c_if_${phys}_ip4=\"$ip4\""
		eval "c_if_${phys}_ip6=\"$ip6\""
		;;
	esac
    done

#    for i in `list_net_interfaces dhcp`
#    do
#	echo "interface $i"
#	echo "  description X"
#	echo "  ip address dhcp"
#    done
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
    echo " host-name ${c_host};"
    echo " domain-name ${c_domain};"
}

gen_services ()
{
    if [ "x${c_services}" != x ]
    then
	echo " services {"
	for s in ${c_services}
	do
	    echo "  $s;"
	done
	echo " }"
    fi
}

#
# Génération de la partie "interfaces"
#
# Historique
#   2010/06/28 : pda : preuve de concept
#   2010/08/31 : pda : réécriture en syntaxe pseudo-juniper
#

gen_if ()
{
    local i d vlans v ip4 ip6

    echo "interfaces {"
    for i in ${c_if}
    do
	echo " $i {"

	eval "d=\${c_if_${i}_desc}"
	echo "  description \"$d\";"

	eval "vlans=\"\${c_if_${i}_vlans}\""
	if [ "$vlans" = "" ]
	then					# interface non taguée
	    echo "  unit 0 {"

	    eval "ip4=\${c_if_${i}_ip4}"
	    if [ "$ip4" != "" ]
	    then
		echo "    family inet {"
		echo "     address $ip4;"
		echo "    }"
	    fi

	    eval "ip6=\${c_if_${i}_ip6}"
	    if [ "$ip6" != "" ]
	    then
		echo "    family inet6 {"
		echo "     address $ip6;"
		echo "    }"
	    fi

	    echo "  }"
	else					# interface taguée
	    echo "  vlan-tagging;"
	    for v in $vlans
	    do
		echo "  unit $v {"

		echo "   vlan-id $v;"

		eval "ip4=\${c_if_${i}_${v}_ip4}"
		if [ "$ip4" != "" ]
		then
		    echo "    family inet {"
		    echo "     address $ip4;"
		    echo "    }"
		fi

		eval "ip6=\${c_if_${i}_${v}_ip6}"
		if [ "$ip6" != "" ]
		then
		    echo "    family inet6 {"
		    echo "     address $ip6;"
		    echo "    }"
		fi

		echo "  }"
	    done
	fi

	echo " }"
    done
    echo "}"
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
get_if

#
# Génération de la pseudo-conf
#

gen_system
gen_if
gen_def_router
