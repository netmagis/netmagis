#!/bin/sh

#
# Start-up script for topographd daemon
#
# Historique
#   2007/07/03 : pda/jean : design
#   2010/11/05 : pda/jean : copy from old script for the new daemon
#   2010/12/15 : pda/jean : split for topographd
#

topographd_program=%TOPOBINDIR%/topographd

case "$1" in
        start)
		echo -n ' topographd'
		su rancid -c "$topographd_program &"
		;;
	stop)
		/bin/kill `ps axwww | grep "$topographd_program" | grep -v "grep" | cut -c1-5`
		;;
	restart)
		echo "Restart topographd"
		/bin/kill `ps axwww | egrep "$topographd_program" | grep -v "grep" | cut -c1-5`
		su rancid -c "$topographd_program &"
		;;
	debug)
		shift
		echo "Reload topographd with level $1"
		/bin/kill `ps axwww | grep $topographd_program | grep -v "grep" | cut -c1-5`
		su rancid -c "$topographd_program -v $1 &"
		;;
	*)
		echo "Usage: $0 {start | stop | restart | debug n}"
		exit 1
		;;
esac

exit 0
