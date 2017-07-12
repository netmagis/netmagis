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

    [mkclient]
		diff = ...
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


## SECTION [mkclient]

This section is used to configure clients (programs `mk*`) which generate
files for various Internet services (DNS, DHCP, etc.).

diff
  : command to use to show differences between an old file (represented
    as `%s`) and a new content given on standard input.
    
    Example: `diff --unified=0 %s -`

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

[mkclient]
    diff = diff --unified=0 %s -
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
`mkzone` (1)

<http://netmagis.org>
