% DNSREADPROL(1) Netmagis User Manuals
% Jean Benoit, Pierre David, Arnaud Grausem
% June 23, 2017

# NAME

dnsreadprol - read the DNS zone prologue from the Netmagis database.


# SYNOPSIS

dnsreadprol [*OPTIONS*] *ZONE* [*VIEW*]


# DESCRIPTION

Prints the specified DNS zone prologue on standard output, according
to the following parameters:


*ZONE*
  : unique name of DNS zone.

*VIEW*
  : if given, provide the view name and checks that the zone is associated
    with this view.

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


Read the prologue for the `example.com` zone:

    $ dnsreadprol example.com > prologue.txt

Read the prologue for the `example.org-ext` zone and check this 
zone is associated with view `external`:

    $ dnsreadprol example.com-ext external > prologue.txt


# BUGS

The *VIEW* parameter is no longer mandatory. It is provided for
compatibility with previous versions of this program, and it may be
removed in future Netmagis releases.


# SEE ALSO

`dnswriteprol` (1),
`netmagis-restd` (1),
`netmagisrc` (5)

<http://netmagis.org>
