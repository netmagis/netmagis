#!/bin/sh

#
# This script launches all tests files (beginning with "test-") in
# the "$TESTDIR" subdirectory
#

LIBDIR=${LIBDIR:-../lib}
CONFFILE=${CONFFILE:-./nm.conf}
FILES=$(echo $(ls -d ${FILES:-../www/static/*}) | sed 's/ /:/g')

if [ $# != 3 ]
then
    echo "usage: $0 tclsh version testdir" >&2
    exit 1
fi

TCLSH="$1"
VERSION="$2"
TESTDIR="$3"

for tfile in ${TESTDIR}/test-*
do
    base=$(echo "$tfile" | sed 's:\.[^/.]*$::')
    log="$base.log"
    ret=ignore
    case "$tfile" in
	*.sh)			# e.g. load database
	    sh $tfile > $log 2>&1
	    ret=$?
	    ;;
	*.tct)			# Tcl test
	    "$TCLSH" nmtest.tcl $VERSION \
	    			$CONFFILE \
				$LIBDIR \
				$FILES \
				$tfile \
				> $log 2>&1
	    ret=$?
	    ;;
	*.log)
	    ;;
	*)
	    echo "Unknown file type '$t'" >&2
	    exit 1
	    ;;
    esac

    case $ret in
	ignore)
	    ;;
	0)
	    echo "OK $tfile"
	    ;;
	*)
	    echo "FAIL $tfile. Log is $log" >&2
	    cat $log >&2
	    exit 1
	    ;;
    esac
done

exit 0
