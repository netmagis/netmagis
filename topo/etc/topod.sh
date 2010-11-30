#!/bin/sh

#
# Script de démarrage du démon topod.
#
# Historique
#   2007/07/03 : pda/jean : conception
#   2010/11/05 : pda/jean : reprise de l'ancien script pour le nouveau topod
#

topod_program=%TOPODIR%/bin/topod

case "$1" in
        start)
		echo -n ' topod'
		su rancid -c "$topod_program &"
		;;
	stop)
		/bin/kill `ps ax | grep $topod_program | grep -v "grep" | cut -c1-5`
		;;
	restart)
		echo "Restart rancid-topo"
		/bin/kill `ps ax | grep $topod_program | grep -v "grep" | cut -c1-5`
		su rancid -c "$topod_program &"
		;;
	debug)
		shift
		echo "Reload rancid-topo with level $1"
		/bin/kill `ps ax | grep $topod_program | grep -v "grep" | cut -c1-5`
		su rancid -c "$topod_program -v $1 &"
		;;
	*)
		echo "Usage: $0 {start | stop | restart | debug n}"
		exit 1
		;;
esac

exit 0
