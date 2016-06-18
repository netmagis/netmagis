% NETMAGIS-DBCREATE(1) Netmagis User Manuals
% Pierre David
% June 17, 2016

# NAME

netmagis-dbcreate - standalone configuration key fetcher for Netmagis


# SYNOPSIS

netmagis-dbcreate [*OPTIONS*] [netmagis] [mac]


# DESCRIPTION

Create the databases used by Netmagis and initialize them with default
items.

This utility may be used with the following parameters:

netmagis
  : Create and initialize the Netmagis main database.

mac
  : Create and initialize the Netmagis MAC database or schema. If
    the database configured in `netmagis.conf` is the same as the
    main database, the `mac` schema is only added to the main
    database.

Without parameter, both databases are created and configured.

The following options are available:

-h
  : Prints a brief description of options.

-f *CONF*
  : Specifiy the path to the `netmagis.conf` configuration file.

    Default: `%CONFFILE%`


# EXIT STATUS

This utility exits 0 on success, and 1 if an error occurs.


# SEE ALSO

`netmagis-config` (1),
`netmagis-dbimport` (1),
`netmagis-dbmaint` (1),
`netmagis-dbupgrade` (1),
`netmagis-getoui` (1),
`netmagis-restd` (1)

<http://netmagis.org>
