% DNSWRITEPROL(1) Netmagis User Manuals
% Jean Benoit, Pierre David, Arnaud Grausem
% June 23, 2017

# NAME

dnswriteprol - write the DNS zone prologue into the Netmagis database.


# SYNOPSIS

dnswriteprol [*OPTIONS*] *ZONE* [*VIEW*] *FILE*


# DESCRIPTION

Write the specified DNS zone prologue in the Netmagis database, according
to the following parameters:


*ZONE*
  : unique name of DNS zone.

*VIEW*
  : if given, provide the view name and checks that the zone is associated
    with this view.

*FILE*
  : file name containing the zone prologue as a text.


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


Write the prologue for the `example.com` zone:

    $ dnswriteprol example.com prologue.txt

Duplicate the zone prologue from the `example.org-ext`, in view `external`
to the `example.org-int` (which must already exists) in view `internal`.

    $ dnsreadprol example.com-ext external > prologue.txt
    $ dnswriteprol example.com-int internal prologue.txt


# BUGS

The *VIEW* parameter is no longer mandatory. It is provided for
compatibility with previous versions of this program, and it may be
removed in future Netmagis releases.


# SEE ALSO

`dnsreadprol` (1),
`netmagis-restd` (1),
`netmagisrc` (5)

<http://netmagis.org>
