% DNSMODATTR(1) Netmagis User Manuals
% Jean Benoit, Pierre David, Arnaud Grausem
% June 23, 2017

# NAME

dnsmodattr - modify one or more host attributes in Netmagis database


# SYNOPSIS

dnsmodattr [*OPTIONS*] *FQDN* *VIEW* *KEY* *VAL* [... *KEY* *VAL*]


# DESCRIPTION

Modify one or more attributes for an existing host in the Netmagis
database, according to the following parameters:


*FQDN*
  : fully-qualified domain name of an existing host to modify.

*VIEW*
  : view name in which the host must reside.

*KEY*
  : attribute name to modify (see ATTRIBUTES below).

*VAL*
  : attribute value to set for this host.

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


# ATTRIBUTES

The following host attributes (case is not significant) may be modified
by this program:

*NAME*
  : host name (first part of FQDN). Domain name is not modifiable.

*MAC*
  : MAC address. Use an empty string to reset the MAC address.

*HINFO*
  : host type (values are specific to each Netmagis installation).

*DHCPPROFILE*
  : name of DHCP profile. Use XXX to remove an existing DHCP profile.

*COMMENT*
  : one-line comment for this host.

*RESPNAME*
  : name of the person in charge of this host.

*RESPMAIL*
  : e-mail adress of the person in charge of this host.

*TTL*
  : time to live (in seconds) for the DNS resource record for this host.
    Use XXX -1 to reset to default zone value.
    This attribute may be used only by persons which have the
    corresponding permission in the Netmagis database.

*SENDSMTP*
  : this host may (value=1) or may not (value=0) use unauthenticated 
    SMTP protocol to send mails to the relays.
    This attribute may be used only by persons which have the
    corresponding permission in the Netmagis database.

# EXIT STATUS

This program exits 0 on success, and 1 if an error occurs.


# EXAMPLES

Modify the MAC address and type of the host `host.example.org` in
view `default`:

    $ dnsmodattr host.example.org default mac 08:00:de:ad:be:ef \
    		hinfo 'PC/Unix'

Modify the DHCP profile for the host `tx01.example.org` in view `internal`:

    $ dnsmodattr tx01.example.org internal dhcpprofile tx

Modify host name `host.example.org` to `newhost.example.org`:

    $ dnsmodattr host.example.org default name newhost

Modify various text fields about the host:

    $ dnsmodattr host.example.org default \
    		comment "John's sample host" \
    		respname "John Doe" \
    		respmail "john@example.com"


# SEE ALSO

`dnsaddhost` (1),
`dnsdelhost` (1),
`dnsdelip` (1),
`netmagis-restd` (1),
`netmagisrc` (5)

<http://netmagis.org>
