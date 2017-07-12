% MKZONES(1) Netmagis User Manuals
% Jean Benoit, Pierre David, Arnaud Grausem
% July 12, 2017

# NAME

mkzones - generate zone files for the DNS server


# SYNOPSIS

mkzones [*OPTIONS*] ([-w *VIEW*] | [*ZONE* ... *ZONE*])


# DESCRIPTION

Generates zone files for the DNS server and ask the server to reload
zone files in memory.


-w *VIEW*
  : ask for generation of all modified zones in the specified view.
    This option is mutually exclusive with supplying individual
    zones as parameters.

*ZONE*
  : ask for generation of one or more zones, identified by their
    name.
    This option is mutually exclusive with supplying a view with
    _-w_

Without parameter (i.e. without **-w** nor *ZONE*), `mkzone` generates
zone files for all modified zones.

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

-q,--quiet
  : Keep silent on normal operation (do not provide status messages).

-v,--verbose
  : Be verbose (show differences between old and new zones).

-n,--dry-run
  : Only generate zones, without performing file installation and zone
    reloading. This option may be used to test zone generation, or
    in conjunction with the verbose option (**-v**) to show differences
    with current zones.


# EXIT STATUS

This program exits 0 on success, and 1 if an error occurs.


# EXAMPLES

Command to add to `cron`:

    $ mkzones

For zone example.com, show only differences between current zone
and new one, without installing it:

    $ mkzones -n -v example.com

Generates zones for view `external` only:

    $ mkzones -v -w external

# SEE ALSO

`dnsreadprol` (1),
`dnswriteprol` (1),
`netmagis-restd` (1),
`netmagisrc` (5)

<http://netmagis.org>
