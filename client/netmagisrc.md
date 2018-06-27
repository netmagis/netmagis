% NETMAGISRC(5) Netmagis User Manuals | Version %VERSION%
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


## SECTION [mkdhcp]

This section is used to configure the `mkdhcp` client which generates
files for the ISC DHCP server.

lockfile
  : file used as a lock to protect from running multiple instances
    of `mkdhcp`
   
    Example: `/var/run/mkdhcp.lock`

dhcpfile
  : file containing the generated data. This file is meant to be
    included by an `include` directive from the main ISC DHCP
    configuration file.

    Example: `/var/dhcp-gen.conf`

dhcpfailover
  : configuration line to configure an address pool as shared by
    two servers in a fail-over configuration. Leave empty if
    you don't use this feature. Don't forget the final `;`.

    Example: `failover peer "dhcp";`

dhcptest
  : command to issue to test a configuration before reloading it.

    Example: `/usr/sbin/dhcpd -t -cf /etc/dhcpd.conf`


dhcpcmd
  : command to issue to force ISC DHCP server to reload its configuration.

    Example: `service isc-dhcpd.sh restart`


## SECTION [mkmroute]

This section is used to configure the `mkmroute` client which generates
a routing file for the mail transfer agent.

lockfile
  : file used as a lock to protect from running multiple instances
    of `mkmroute`
   
    Example: `/var/run/mkmroute.lock`

mroutefile
  : file containing the generated data. This file is meant to be
    used by your mail transfer agent.

    Example: `/etc/postfix/transport`

mrouteprologue
  : static file containing a hand-crafter prologue to include
    as the first lines in the generated file.

    Example: `/etc/postfix/transport.prologue`

mroutefmt
  : format string to use for each mailroute.

    Example: `{mailaddr:40} smtp:[{mailhost}]`

mroutecmd
  : command to issue to force MTA to reload the mail routing file.

    Example: `/usr/sbin/postmap /etc/postfix/transport`


## SECTION [mksmtpf]

This section is used to configure the `mksmtpf` client which generates
the list of addresses of SMTP-enabled hosts for the packet filter.

lockfile
  : file used as a lock to protect from running multiple instances
    of `mksmtpf`
   
    Example: `/var/run/mksmtpf.lock`

pffile
  : file containing the generated data. This file is meant to be
    used by your packet filter.

    Example: `/etc/smtpf.pf`

pfprologue
  : static file containing a hand-crafter prologue to include
    as the first lines in the generated file.

    Example: `/etc/smtpf.prologue`

pffmt
  : format string to use for each mail address.

    Example: `{addr}`

pftest
  : command to issue to test the generated file before reloading it.

    Example: `pfctl -q -n -t smtpf -T replace -f /etc/smtpf.pf`

pfcmd
  : command to issue to force the packet filter to reload the table.

    Example: `pfctl -q -t smtpf -T replace -f /etc/smtpf.pf`


## SECTION [mkzones]

This section is used to configure the `mkzones` client which generates
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
`mkdhcp` (1),
`mkmroute` (1),
`mksmtpf` (1),
`mkzones` (1)

<http://netmagis.org>
