#!/bin/sh

if [ $# != 1 ]
then
    echo "usage: $0 conffile" >&2
    exit 1
fi

CONFFILE="$1"

DUMPFILE=dump-test-100-load.dump

getconf ()
{
    sed -n "s/^$1[ 	][ 	]*\(.*\)/\1/p" "$CONFFILE"
}

PGHOST=$(getconf dnsdbhost)
PGPORT=$(getconf dnsdbport)
PGDATABASE=$(getconf dnsdbname)
PGUSER=$(getconf dnsdbuser)
PGPASSWORD=$(getconf dnsdbpassword)

export PGHOST PGPORT PGDATABASE PGUSER PGPASSWORD
dropdb --if-exists $PGDATABASE \
    && createdb $PGDATABASE \
    && psql -f $DUMPFILE \
    && psql \
	-c "INSERT INTO global.utmp (idcor, token, api) VALUES (1, 'bla', 1)"
