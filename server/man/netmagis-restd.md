% NETMAGIS-RESTD(1) Netmagis User Manuals
% Pierre David
% June 17, 2016

# NAME

netmagis-restd - REST daemon for Netmagis


# SYNOPSIS

netmagis-restd [*OPTIONS*]


# DESCRIPTION

The Netmagis REST daemon answers SCGI requests coming from an HTTP server
such as Apache or Nginx.

The following options are available:

-h
  : Prints a brief description of options.

-d
  : Activates debug messages. When used, error messages returned by
    the daemon will include a stack trace. *Do not activate this
    options* during normal operations.

-f *CONF*
  : Specifiy the configuration file (netmagis.conf) path.

    Default: `%CONFFILE%`

-a *ADDR*
  : Specify the address (IPv4 or IPv6) to listen to SCGI requests from
    the HTTP server.

    Default: `0.0.0.0`

-p *PORT*
  : Specify the TCP port to listen to SCGI requests from the HTTP server.

    Default: `8080`

-l *LIBDIR*
  : Specify the to the library directory, which must contain the
    `worker/` and `pkgtcl/` subdirectories

    Default: `%NMLIBDIR%`

-s *FILES*
  : Specify the list of directories containing static files to be delivered
    by the daemon, under the `/files` URL. This list is separated by colons.

    Example: `netmagis-restd -f /tmp/dir1:/tmp/dir2:/tmp/dir3`

    Default: `%NMLIBDIR%/www`

-m *MIN*
  : Specify the minimum number of worker threads.

    Default: `2`

-x *MAX*
  : Specify the maximum number of worker threads.

    Default: `4`

-i *IDLETIME*
  : Specify the maximum idle time in seconds before a worker thread exits
    (as long as the number of threads does not drop below the `-m`
    minimum number of worker threads).

    Default: `30`

-v *VERSION*
  : Specify an application version for schema checking (e.g. 3.0.0alpha).
    *Use this option only during development of new Netmagis versions*.

    Default: `%VERSION%`


# EXIT STATUS

This daemon never exits, so there is no exit status. See below (BUGS).


# NETMAGIS.CONF KEYS

The following `netmagis.conf` keys are used in this program:

  > `dnsdbhost`, `dnsdbport`, `dnsdbname`, `dnsdbuser`, `dnsdbpassword`,
  `macdbhost`, `macdbport`, `macdbname`, `macdbuser`, `macdbpassword`


# BUGS

The daemon does not fork itself. As such, it never stops.


# SEE ALSO

`netmagis.conf` (5),
`netmagis-config` (1),
`netmagis-dbcreate` (1),
`netmagis-dbimport` (1),
`netmagis-dbmaint` (1),
`netmagis-dbupgrade` (1),
`netmagis-getoui` (1)

<http://netmagis.org>
