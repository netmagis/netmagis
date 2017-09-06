#!/bin/sh

if [ $# != 0 ]
then
    echo "usage: $0" >&2
    exit 1
fi

IMPORTDIR=../examples/with-views

# $1 : return code
# $2 : test number
# $3 : message
fail ()
{
    local rcode="$1" num="$2" msg="$3"

    if [ "$rcode" = 0 ]
    then
	echo "ok $num $msg"
	echo
    else
	echo "not ok $num $msg"
	echo "	exit code=$rcode"
	echo
	exit "$rcode"
    fi
}

# Get database parameters
init_env ()
{
    local vars

    vars="dnsdbhost dnsdbport dnsdbname dnsdbuser dnsdbpassword"
    eval $(netmagis-config -c $vars)
    fail $? 10 "init env"

    PGHOST="$dnsdbhost"
    PGPORT="$dnsdbport"
    PGDATABASE="$dnsdbname"
    PGUSER="$dnsdbuser"
    PGPASSWORD="$dnsdbpassword"
    export PGHOST PGPORT PGDATABASE PGUSER PGPASSWORD
}

# Remove database
rmdb ()
{
    dropdb --if-exists $PGDATABASE

    fail $? 20 "drop db"
}

# Import example data
import ()
{
    cd $IMPORTDIR
    fail $? 30 "cd import dir"
    sh run-all.sh
    fail $? 35 "import data"
}

# Patch example data:
# - add appropriate permissions to g-* groups (see README.users)
# - create t-* session tickets for u-* users
patch ()
{
    psql --no-psqlrc --single-transaction -c "
	UPDATE global.nmgroup
	    SET p_admin=1, p_smtp=1, p_ttl=1, p_mac=1, p_genl=1, p_genz=1
	    WHERE name = 'g1-wheel' ;
	UPDATE global.nmgroup
	    SET p_genz=1 WHERE name = 'g3-simple' ;
	UPDATE global.nmgroup
	    SET p_mac=1 WHERE name = 'g4-mac' ;
	UPDATE global.nmgroup
	    SET p_ttl=1 WHERE name = 'g5-ttl' ;
	UPDATE global.nmgroup
	    SET p_smtp=1 WHERE name = 'g6-smtp' ;
	UPDATE global.nmgroup
	    SET p_admin=1 WHERE name = 'g7-admin' ;
	INSERT INTO global.utmp (idcor, token, api)
	    SELECT idcor, regexp_replace (login, '^u', 't') AS token, 1 AS api
		FROM global.nmuser WHERE login like 'u%-%' ;
	"
    fail $? 40 "patch data"
}

init_env \
    && rmdb \
    && import \
    && patch

exit 0
