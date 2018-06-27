% NETMAGIS.CONF(5) Netmagis User Manuals | Version %VERSION%
% Pierre David
% June 18, 2016

# NAME

netmagis.conf - configuration file for Netmagis server package


# DESCRIPTION

The `netmagis.conf` file contains configuration for various programs in
the Netmagis server package.

Each configuration item is given as a line under the format:

> _key_ _value_

Key and value are separated by any number of blanks and/or tab characters.
A `#` character indicates the beginning of a comment.


# CONFIGURATION KEYS

Netmagis programs use the following keys:

dnsdbhost
  : Host name of PostgreSQL server supporting Netmagis main database.

dnsdbport
  : TCP port number of PostgreSQL instance supporting Netmagis main
    database.

dnsdbname
  : Name of Netmagis main database.

dnsdbuser
  : Netmagis PostgreSQL user.

dnsdbpassword
  : Password of Netmagis PostgreSQL user.


macdbhost
  : Host name of PostgreSQL server supporting Netmagis-MAC database
    (which may be the same as the main database).

macdbport
  : TCP port number of PostgreSQL instance supporting Netmagis-MAC
    database (which may be the same as the main database).

macdbname
  : Name of Netmagis-MAC database (which may be the same as the main
    database).

macdbuser
  : Netmagis-MAC PostgreSQL user (which may be the same as the main
    database).

macdbpassword
  : Password of Netmagis-MAC PostgreSQL user (which may be the same as
    the main database).


ouiurl
  : URL of the Wireshark `manuf` file, which lists MAC prefixes allocated
    to manufacturers.

dumpdir
  : If non empty, gives a directory where `netmagis-dbmaint` stores
    periodic database backups.

dbcopy
  : If non empty, gives the name of a database which will be re-created
    every day by `netmagis-dbmaint`. This database may be used as a
    victim for your manipulations.


# FILES

%CONFFILE%


# SEE ALSO

`netmagis-dbcreate` (1),
`netmagis-dbimport` (1),
`netmagis-dbmaint` (1),
`netmagis-dbupgrade` (1),
`netmagis-getoui` (1),
`netmagis-restd` (1)

<http://netmagis.org>
