#!/bin/sh

#
# This script launches all tests files (beginning with "test-") in
# the "$TESTDIR" subdirectory
# Note: this script must be run with working directory set to here.
#

if [ $# != 2 ]
then
    echo "usage: $0 version testdir" >&2
    exit 1
fi

VERSION="$1"
TESTDIR="$2"

here=$(pwd)

NETMAGIS_LIBDIR=${NETMAGIS_LIBDIR:-${here}/../lib}
NETMAGIS_CONFIG=${NETMAGIS_CONFIG:-${here}/nm.conf}
NETMAGIS_VERSION="$VERSION"
FILES=$(echo $(ls -d ${FILES:-${here}/../www/static/*}) | sed 's/ /:/g')

export NETMAGIS_LIBDIR NETMAGIS_CONFIG NETMAGIS_VERSION

PATH=$(pwd)/../bin:$PATH ; export PATH

for tfile in ${TESTDIR}/test-*
do
    base=$(echo "$tfile" | sed 's:\.[^/.]*$::')
    log="$base.log"
    ret=ignore
    case "$tfile" in
	*.sh)			# e.g. load database
	    # Shell scripts may execute Netmagis programs which use
	    # NETMAGIS_* environment variables
	    rm -f $log
	    echo "# sh $tfile" > $log
	    sh $tfile >> $log 2>&1
	    ret=$?
	    ;;
	*.tct)			# Tcl test
	    # The nmtest.tcl program does not use NETMAGIS_* environment
	    # variables
	    rm -f $log
	    echo "# ./nmtest.tcl $NETMAGIS_VERSION $NETMAGIS_CONFIG $NETMAGIS_LIBDIR $FILES $tfile" > $log
	    ./nmtest.tcl $NETMAGIS_VERSION \
	    			$NETMAGIS_CONFIG \
				$NETMAGIS_LIBDIR \
				$FILES \
				$tfile \
				>> $log 2>&1
	    ret=$?
	    ;;
	*.log)
	    ;;
	*)
	    echo "Unknown file type '$tfile'" >&2
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
