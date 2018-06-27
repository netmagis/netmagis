% DNSDELHOST(1) Netmagis User Manuals | Version %VERSION%
% Jean Benoit, Pierre David, Arnaud Grausem
% June 23, 2017

# NAME

dnsdelhost - delete a host or an alias in Netmagis database


# SYNOPSIS

dnsdelhost [*OPTIONS*] *FQDN* *VIEW*


# DESCRIPTION

Delete an existing host in the Netmagis database,
according to the following parameters:


*FQDN*
  : fully-qualified domain name of the host or alias to delete. This name
    must already exist (as a host or as an alias) in the Netmagis database
    for the specified view.

*VIEW*
  : view name.

The following options are available:

-h,--help
  : Prints a terse description of options.

-f,--config-file *CONF*
  : Specifiy the user configuration file (netmagisrc) path giving
    credentials to the Netmagis REST server.

    Default: `~/.config/netmagisrc`

-l,--libdir *LIBDIR*
  : Specify the library directory, which must contain the
    `pynm/` (Python library) subdirectory.

    Default: `%NMLIBDIR%`

-d,--debug
  : Display stack trace in case of internal errors and trace
    requests to the Netmagis REST server (`netmagis-restd`).

    Default: do not display debug informations


# EXIT STATUS

This program exits 0 on success, and 1 if an error occurs.


# EXAMPLES

Delete the host `h.example.com` in view `default`:

    $ dnsdelhost h.example.com default

Delete the alias `www.example.com` in view `external`:

    $ dnsdelhost www.example.com external


# SEE ALSO

`dnsaddalias` (1),
`dnsaddhost` (1),
`dnsdelip` (1),
`dnsmodattr` (1),
`netmagis-restd` (1),
`netmagisrc` (5)

<http://netmagis.org>
