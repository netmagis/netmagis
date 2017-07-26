% NETMAGISRC(5) Netmagis User Manuals
% Jean Benoit, Pierre David, Arnaud Grausem
% June 23, 2017

# NAME

`netmagisrc` - user configuration file for Netmagis client programs


# DESCRIPTION

The `netmagisrc` file contains user configuration for various programs in
the Netmagis server package.

    [general]
		url = ...
		key = ...

    [mkzones]
		lockfile = ...
		zonedir = ...
		zonecmd = ...

    ...

The global configuration file (`%ETCDIR%/netmagisrc`) is read first,
then the per-user configuration file (`$HOME/.config/netmagisrc`) is
read. This way, one can provide default values in the global configuration
file, and users need only provide their specific values without having
to specify all keys.


# CONFIGURATION KEYS

Configuration keys are divided in sections.

## SECTION [general]

url
  : URL of Netmagis REST server.

    Example: `https://www.example.com/netmagis`

key
  : API session key for this user. See the Netmagis Web application
    in order to get such a key or extend its lifetime.


## SECTION [mkzones]

This section is used to configure `mkzones` client which generate
files for the ISC BIND daemon.

lockfile
  : file used as a lock to protect from running multiple instances
    of `mkzones`
   
    Example: `/var/run/mkzones.lock`

zonedir
  : directory where DNS zone files are read by the DNS server.

    Example: `/var/namedb/primary`

zonecmd
  : command to issue to force DNS server to reload zone files.

    Example: `/usr/sbin/rndc reload`


# FILES

`%ETCDIR%/netmagisrc`,
`~/.config/netmagisrc`


# EXAMPLE

```
[general]
   url = https://www.example.com/netmagis
   key = averylongtokenprovidedbytheNetmagisWebserver

[mkzones]
    lockfile = /var/run/mkzones.lock
    zonedir = /var/namedb/primary
    zonecmd = /usr/sbin/rndc reload
```


# SEE ALSO

`dnsaddalias` (1),
`dnsaddhost` (1),
`dnsdelhost` (1),
`dnsdelip` (1),
`dnsmodattr` (1),
`dnsreadprol` (1),
`dnswriteprol` (1),
`mkzones` (1)

<http://netmagis.org>
