% NETMAGIS-CONFIG(1) Netmagis User Manuals
% Pierre David
% June 17, 2016

# NAME

netmagis-config - standalone configuration key fetcher for Netmagis


# SYNOPSIS

netmagis-config [*OPTIONS*] *KEY* ... *KEY*


# DESCRIPTION

Return the value of one or more Netmagis configuration keys as
shell variables definitions.

The following options are available:

-h
  : Prints a brief description of options.

-f *CONF*
  : Specifiy the path to the `netmagis.conf` configuration file.

    Default: `%CONFFILE%`

-c
  : Checks that the configuration key is present in the configuration
    file. Without this option, an invalid configuration key is assumed
    to be empty.


# EXIT STATUS

This utility exits 0 on success, and 1 if an error occurs.

# EXAMPLES

Fetch the values of some parameters:

    $ netmagis-config dnsdbname foobar
    dnsdbname='netmagis' foobar=''

Fetch and check values:

    $ netmagis-config -c dnsdbname foobar
    Netmagis configuration parameter 'foobar' is not initialized

Use values in a script:

    eval $(netmagis-config dnsdbname dnsdbport)
    if [ $dnsdbname = "netmagis" -a $dnsdbport = "5432" ]
    then ...
    fi


# SEE ALSO

`netmagis.conf` (5),
`netmagis-dbcreate` (1),
`netmagis-dbimport` (1),
`netmagis-dbmaint` (1),
`netmagis-dbupgrade` (1),
`netmagis-getoui` (1),
`netmagis-restd` (1)

<http://netmagis.org>
