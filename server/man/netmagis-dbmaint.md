% NETMAGIS-DBMAINT(1) Netmagis User Manuals | Version %VERSION%
% Pierre David
% June 18, 2016

# NAME

netmagis-dbmaint - Netmagis database maintenance


# SYNOPSIS

netmagis-dbmaint [*OPTIONS*]  hourly|daily


# DESCRIPTION

Perform daily and hourly maintenance jobs on the Netmagis main database:

  * Backup database in the directory specified by the
    `dumpdir` key (in `netmagis.conf`).
    If the value of this parameter is empty, backup is not performed.
  * Create a copy of the Netmagis database into a sandbox database
    specified by the `dbcopy` key (in `netmagis.conf`).
    If the value of this parameter is empty, backup is not performed.
  * Garbage collect database with `vacuumdb` (1).
  * Expire spools used in the `topo` Netmagis module.

Actions are specified by one of the two following parameters:

hourly
  : Perform database backup only.

daily
  : Perform all actions detailed above.

The following options are available:

-h
  : Prints a brief description of options.

-f *CONF*
  : Specifiy the path to the `netmagis.conf` configuration file.

    Default: `%CONFFILE%`, or `NETMAGIS_CONFIG` shell variable


# EXIT STATUS

This utility exits 0 on success, and 1 if an error occurs.


# NOTE

The Netmagis MAC database is not handled by this program.


# NETMAGIS.CONF KEYS

The following `netmagis.conf` keys are used in this program:

  > `dnsdbhost`, `dnsdbport`, `dnsdbname`, `dnsdbuser`, `dnsdbpassword`,
  `dumpdir`, `dbcopy`


# ENVIRONMENT VARIABLES

The following Shell environment variables, if set, provide
alternative values for some installation-defined constants:

`NETMAGIS_CONFIG`
  : path of `netmagis.conf` configuration file.

    Default: `%CONFFILE%`

`NETMAGIS_LIBDIR`
  : library directory, which must contain the worker/
    and pkgtcl/ subdirectories.
    
    Default: `%NMLIBDIR%`

`NETMAGIS_VERSION`
  : Netmagis program version, used to check against database schema.

    Default: %VERSION%


# SEE ALSO

`netmagis.conf` (5),
`netmagis-config` (1),
`netmagis-dbcreate` (1),
`netmagis-dbimport` (1),
`netmagis-dbupgrade` (1),
`netmagis-getoui` (1),
`netmagis-restd` (1),
`pg_dump` (1),
`psql` (1),
`vacuumdb` (1)

<http://netmagis.org>
