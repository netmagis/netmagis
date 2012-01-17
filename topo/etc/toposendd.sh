#!/bin/sh

#
# Start-up script for toposendd daemon
#
# Historique
#   2007/07/03 : pda/jean : design
#   2010/11/05 : pda/jean : copy from old script for the new daemon
#   2010/12/15 : pda/jean : split for toposendd
#

toposendd_program=%NMLIBDIR%/topo/toposendd

case "$1" in
        start)
		echo -n ' toposendd'
		su rancid -c "$toposendd_program &"
		;;
	stop)
		/bin/kill `ps axwww | grep "$toposendd_program" | grep -v "grep" | cut -c1-5`
		;;
	restart)
		echo "Restart toposendd"
		/bin/kill `ps axwww | egrep "$toposendd_program" | grep -v "grep" | cut -c1-5`
		su rancid -c "$toposendd_program &"
		;;
	debug)
		shift
		echo "Reload toposendd with level $1"
		/bin/kill `ps axwww | grep $toposendd_program | grep -v "grep" | cut -c1-5`
		su rancid -c "$toposendd_program -v $1 &"
		;;
	*)
		echo "Usage: $0 {start | stop | restart | debug n}"
		exit 1
		;;
esac

exit 0
