% DNSADDHOST(1) Netmagis User Manuals
% Jean Benoit, Pierre David, Arnaud Grausem
% June 23, 2017

# NAME

dnsaddhost - add a host in Netmagis database


# SYNOPSIS

dnsaddhost [*OPTIONS*] *FQDN* *IP* *VIEW*


# DESCRIPTION

Either add a new host in the Netmagis database or add an IP address to
an existing host, according to the following parameters:


*FQDN*
  : fully-qualified domain name of the host. If the host does not already
    exists in the Netmagis database, it is created. Otherwise, the IP
    address is added to the existing host.

*IP*
  : IP (IPv4 or IPv6) address to add.

*VIEW*
  : view name in which the host must be added.

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

Add the host `h.example.com` with two IP addresses 198.51.100.1 and
2001:db8:1234::1 in view `default`:

    $ dnsaddhost h.example.com 198.51.100.1 default
    $ dnsaddhost h.example.com 2001:db8:1234::1 default


# SEE ALSO

`dnsaddalias` (1),
`dnsdelhost` (1),
`dnsdelip` (1),
`dnsmodattr` (1),
`netmagis-restd` (1),
`netmagisrc` (5)

<http://netmagis.org>
