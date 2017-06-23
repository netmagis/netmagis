% DNSDELIP(1) Netmagis User Manuals
% Jean Benoit, Pierre David, Arnaud Grausem
% June 23, 2017

# NAME

dnsdelip - delete an IP address in Netmagis database


# SYNOPSIS

dnsdelip [*OPTIONS*] *IP* *VIEW*


# DESCRIPTION

Delete an IP (IPv4 or IPv6) address in the Netmagis database. If the
corresponding host has only one IP address, delete the host as well.
Paramers are:

*IP*
  : IP (IPv4 or IPv6) address to delete.

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

-t,--trace
  : verbose trace requests to the Netmagis REST server (`netmagis-restd`).

    Default: do not trace REST requests.


# EXIT STATUS

This program exits 0 on success, and 1 if an error occurs.


# EXAMPLES

Delete the IP address 198.51.100.1, and delete the corresponding
host if it has only one IP address in view `default`:

    $ dnsdelip 198.51.100.1 default



# SEE ALSO

`dnsaddhost` (1),
`dnsdelhost` (1),
`dnsmodattr` (1),
`netmagis-restd` (1),
`netmagisrc` (5)

<http://netmagis.org>
