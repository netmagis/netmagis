% MKSMTPF(1) Netmagis User Manuals | Version %VERSION%
% Jean Benoit, Pierre David, Arnaud Grausem
% July 27, 2017

# NAME

mksmtpf - generate packet filter file for SMTP-enabled hosts


# SYNOPSIS

mksmtpf [*OPTIONS*] [*VIEW*]


# DESCRIPTION

Generates a file for the packet filter in order to allow connections
from SMTP-enabled hosts.

*VIEW*
  : ask for generation of addresses related to the named view.
    This argument is optional if there is only one view in the
    Netmagis database.

The following options are available:

-h,--help
  : Prints a terse description of options.

-f,--config-file *CONF*
  : Specifiy the user configuration file (netmagisrc) path giving
    credentials to the Netmagis REST server and other configuration
    information.

    Default: `~/.config/netmagisrc`

-l,--libdir *LIBDIR*
  : Specify the library directory, which must contain the
    `pynm/` (Python library) subdirectory.

    Default: `%NMLIBDIR%`

-d,--debug
  : Display stack trace in case of internal errors and trace
    requests to the Netmagis REST server (`netmagis-restd`).

    Default: do not display debug informations

-q,--quiet
  : Keep silent on normal operation (do not provide status messages).

-v,--verbose
  : Be verbose (show differences between old and new zones).

-n,--dry-run
  : Only generate zones, without performing file installation and zone
    reloading. This option may be used to test zone generation, or
    in conjunction with the verbose option (**-v**) to show differences
    with current filter list.

-w
  : This option is here for compatibility purpose only. It is deprecated
    and will be removed in a future version.


# EXIT STATUS

This program exits 0 on success, and 1 if an error occurs.


# EXAMPLES

Command to add to `cron`:

    $ mksmtpf

For view `internal`, only show differences between current addresses
and new ones, wihtout installing the new configuration:

    $ mksmtpf -n -v internal

Generates filters for view `external` only:

    $ mksmtpf -v external

# SEE ALSO

`netmagis-restd` (1),
`mkdhcp` (1)
`mkmroute` (1)
`mkzones` (1)
`netmagisrc` (5),

<http://netmagis.org>
