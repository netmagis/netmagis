% DNSADDALIAS(1) Netmagis User Manuals
% Jean Benoit, Pierre David, Arnaud Grausem
% June 23, 2017

# NAME

dnsaddalias - add an alias to an existing host in Netmagis database


# SYNOPSIS

dnsaddalias [*OPTIONS*] *FQDN-ALIAS* *FQDN-HOST* *VIEW*


# DESCRIPTION

Either add a new host in the Netmagis database or add an IP address to
an existing host, according to the following parameters:


*FQDN-ALIAS*
  : fully-qualified domain name of the alias to add. This name must not
    already exists in the Netmagis database for the specified view.

*FQDN-HOST*
  : fully-qualified domain name of an existing host in the specified
    view.

*VIEW*
  : view name in which the alias must be added.

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

Add an alias `www.example.com` to host `host.example.com` in view `default`:

    $ dnsaddalias www.example.com host.example.com default

Add an alias `www.example.org` to host `host.example.com` in view `external`
using a different configuration file:

    $ dnsaddalias -f ~/.config/netmagisrc.alt \
	    	www.example.org host.example.com external

# SEE ALSO

`dnsaddhost` (1),
`dnsdelhost` (1),
`dnsdelip` (1),
`dnsmodattr` (1),
`netmagis-restd` (1),
`netmagisrc` (5)

<http://netmagis.org>
