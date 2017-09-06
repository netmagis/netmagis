#!/bin/sh

if [ $# != 0 ]
then
    echo "usage: $0" >&2
    exit 1
fi

#export PGHOST PGPORT PGDATABASE PGUSER PGPASSWORD
#dropdb --if-exists $PGDATABASE \
#    && createdb $PGDATABASE \
#    && psql $PGOPT -f $DUMPFILE \
#    && psql $PGOPT -c "
#	INSERT INTO global.utmp (idcor, token, api) VALUES (1, 't1-wheel', 1) ;
#	INSERT INTO global.utmp (idcor, token, api) VALUES (2, 't2-simple', 1) ;
#	INSERT INTO global.utmp (idcor, token, api) VALUES (3, 't3-genz', 1) ;
#	INSERT INTO global.utmp (idcor, token, api) VALUES (4, 't4-mac', 1) ;
#	INSERT INTO global.utmp (idcor, token, api) VALUES (5, 't5-ttl', 1) ;
#	INSERT INTO global.utmp (idcor, token, api) VALUES (6, 't6-smtp', 1) ;
#	INSERT INTO global.utmp (idcor, token, api) VALUES (7, 't7-admin', 1) ;
#	INSERT INTO global.utmp (idcor, token, api) VALUES (8, 't8-abset', 1) ;
#	"

IMPORTDIR=../examples/with-views

(
eval $(netmagis-config -c dnsdbhost dnsdbport dnsdbname dnsdbuser dnsdbpassword)
PGHOST="$dnsdbhost"
PGPORT="$dnsdbport"
PGDATABASE="$dnsdbname"
PGUSER="$dnsdbuser"
PGPASSWORD="$dnsdbpassword"

export PGHOST PGPORT PGDATABASE PGUSER PGPASSWORD
dropdb --if-exists $PGDATABASE
)

cd $IMPORTDIR
sh run-all.sh

r=$?
if [ $r = 0 ]
then
    echo "ok 10 Load 3.0 import"
    echo
else
    echo "not ok 10 Load 3.0 import"
    echo "	exit code=$r"
    echo
fi

exit $r

