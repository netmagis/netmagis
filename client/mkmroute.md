% MKMROUTE(1) Netmagis User Manuals | Version %VERSION%
% Jean Benoit, Pierre David, Arnaud Grausem
% July 27, 2017

# NAME

mkmroute - generate mail routing file for the mail server


# SYNOPSIS

mkdhcp [*OPTIONS*] [*VIEW*]


# DESCRIPTION

Generates DHCP host/range informations as a file suitable for inclusion
(via the `include` directive) in the main ISC DHCP server configuration
file, test the new configuration and ask the server to reload the whole
configuration.

*VIEW*
  : ask for generation of informations related to the named view.
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
    with current routes.

-w
  : This option is here for compatibility purpose only. It is deprecated
    and will be removed in a future version.


# EXIT STATUS

This program exits 0 on success, and 1 if an error occurs.


# EXAMPLES

Command to add to `cron`:

    $ mkdhcp

For view `internal`, only show differences between current DHCP
informations and new ones, wihtout installing the new configuration:

    $ mkdhcp -n -v internal

Generates information for view `external` only:

    $ mkdhcp -v external

# SEE ALSO

`netmagis-restd` (1),
`mkmroute` (1)
`mksmtpf` (1)
`mkzones` (1)
`netmagisrc` (5),

<http://netmagis.org>
