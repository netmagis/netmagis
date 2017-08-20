#!/bin/sh

if [ $# != 1 ]
then
    echo "usage: $0 conffile" >&2
    exit 1
fi

CONFFILE="$1"

DUMPFILE=dump-test-30-100-load.dump

getconf ()
{
    sed -n "s/^$1[ 	][ 	]*\(.*\)/\1/p" "$CONFFILE"
}

PGHOST=$(getconf dnsdbhost)
PGPORT=$(getconf dnsdbport)
PGDATABASE=$(getconf dnsdbname)
PGUSER=$(getconf dnsdbuser)
PGPASSWORD=$(getconf dnsdbpassword)

PGOPT="--quiet --no-psqlrc"

export PGHOST PGPORT PGDATABASE PGUSER PGPASSWORD
dropdb --if-exists $PGDATABASE \
    && createdb $PGDATABASE \
    && psql $PGOPT -f $DUMPFILE \
    && psql $PGOPT -c "
	INSERT INTO global.utmp (idcor, token, api) VALUES (1, 't1-wheel', 1) ;
	INSERT INTO global.utmp (idcor, token, api) VALUES (2, 't2-simple', 1) ;
	INSERT INTO global.utmp (idcor, token, api) VALUES (3, 't3-genz', 1) ;
	INSERT INTO global.utmp (idcor, token, api) VALUES (4, 't4-mac', 1) ;
	INSERT INTO global.utmp (idcor, token, api) VALUES (5, 't5-ttl', 1) ;
	INSERT INTO global.utmp (idcor, token, api) VALUES (6, 't6-smtp', 1) ;
	INSERT INTO global.utmp (idcor, token, api) VALUES (7, 't7-admin', 1) ;
	INSERT INTO global.utmp (idcor, token, api) VALUES (8, 't8-abset', 1) ;
	"

r=$?
if [ $r = 0 ]
then
    echo "ok 10 Load 3.0 dump"
    echo
else
    echo "not ok 10 Load 3.0 dump"
    echo "	exit code=$r"
    echo
fi

exit $r

