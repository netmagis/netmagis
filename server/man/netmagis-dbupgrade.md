% NETMAGIS-DBUPGRADE(1) Netmagis User Manuals
% Pierre David
% June 18, 2016

# NAME

netmagis-dbupgrade - upgrade Netmagis database to current version


# SYNOPSIS

netmagis-dbupgrade [*OPTIONS*]  [*TARGET*]


# DESCRIPTION

Upgrade the Netmagis database schema to the current version.

Netmagis versions are numbered *X*.*Y*.*Z*. Database versions are
numbered *XY*. Minor version changes (modifications of the *Z* value)
do not imply modifications to a database.  Netmagis includes a mechanism
to ensure that programs do not risk to access data from a database with
a different version.

  * Without parameter, `netmagis-dbupgrade` displays the version of
    current database (under the form *XY*).

  * When given the *TARGET* parameter, `netmagis-dbupgrade` upgrades
    the database to the *TARGET* version (under the form *XY*).

The following options are available:

-h
  : Prints a brief description of options.

-f *CONF*
  : Specifiy the path to the `netmagis.conf` configuration file.

    Default: `%CONFFILE%`

-l *DIR*
  : Specify the library directory. This directory must contain
    an `upgrade` subdirectory, which in turn must contain
    sub-sub-directories called *XY*-*ZT* giving the upgrade path.

    Default: `%NMLIBDIR%`


# EXIT STATUS

This utility exits 0 on success, and 1 if an error occurs.


# NETMAGIS.CONF KEYS

The following `netmagis.conf` keys are used in this program:

  > `dnsdbhost`, `dnsdbport`, `dnsdbname`, `dnsdbuser`, `dnsdbpassword`,
  `macdbhost`, `macdbport`, `macdbname`, `macdbuser`, `macdbpassword`


# NOTE

This program does not perform upgrade of underlying PostgreSQL versions.
For this task, read PostgreSQL release notes and use `pg_upgrade`.


# BUGS

This utility cannot upgrade from versions (strictly) lower than Netmagis
2.0.


# SEE ALSO

`netmagis.conf` (5),
`netmagis-config` (1),
`netmagis-dbcreate` (1),
`netmagis-dbimport` (1),
`netmagis-dbmaint` (1),
`netmagis-getoui` (1),
`netmagis-restd` (1),
`pg_upgrade` (1),
`psql` (1)

<http://netmagis.org>
