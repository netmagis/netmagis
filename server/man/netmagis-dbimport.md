% NETMAGIS-DBIMPORT(1) Netmagis User Manuals | Version %VERSION%
% Pierre David
% August 23, 2017

# NAME

netmagis-dbimport - import initial data set into Netmagis database


# SYNOPSIS

**netmagis-dbimport -h**

**netmagis-dbimport** [*OPTIONS*] **group** *FILE*

**netmagis-dbimport** [*OPTIONS*] **network** *FILE*

**netmagis-dbimport** [*OPTIONS*] **view** *FILE*

**netmagis-dbimport** [*OPTIONS*] **domain** *FILE*

**netmagis-dbimport** [*OPTIONS*] **zone** *VIEW* *ZONENAME* *FILE* *SELECTOR* [*RRSUPFILE*]

**netmagis-dbimport** [*OPTIONS*] **mailrelay** *VIEW* *FILE*

**netmagis-dbimport** [*OPTIONS*] **mailrole** *VIEW* *FILE*


# DESCRIPTION

During the Netmagis installation phase, this command is used to load
initial data in the database. It only provides basic facilities: to load
more complex data, you must either use the Web interface or the REST API.

Common options are:

-h
  : Prints a brief description of options.

-f *CONF*
  : Specifiy the path to the `netmagis.conf` configuration file.

    Default: `%CONFFILE%`, or `NETMAGIS_CONFIG` shell variable

-d
  : Enable debug/verbose messages. Each `-d` option increase verbosity
    level.

-l *LIBDIR*
  : Specify the to the library directory, which must contain the
    `pkgtcl/` subdirectory.

    Default: `%NMLIBDIR%`, or `NETMAGIS_LIBDIR` shell variable

-v *VERSION*
  : Specify an application version for schema checking (e.g. 3.0.0alpha).
    *Use this option only during development of new Netmagis versions*.

    Default: `%VERSION%`, or `NETMAGIS_VERSION` shell variable

To shorten this page, you can refer to individual files in the `examples`
directory provided with your Netmagis installation.


# IMPORTING GROUPS

When using `netmagis-dbimport group` subcommand, one must provide a file
containing group definitions.

## Synopsis

**netmagis-dbimport** [*OPTIONS*] **group** *FILE*

## File syntax

The group file contains lines with the format:

*group* *login* *login*...

Each named group is added to the database if it does not already
exist. Each login is created if it does not already exists, and added
to the group if it does not already belong to that group.  If a login
is created, `netmagis-dbimport` displays its generated password on
standard output. Note that each login must appear only in one group.

The special group **wheel** is automatically created by the
`netmagis-dbcreate` program with admin privileges. All users created in
this group will have a complete control on Netmagis.


## Example

Use the command:

    $ netmagis-dbimport -d group group.txt

to import the file `group.txt`.

# IMPORTING NETWORKS

Network definitions are imported with the `netmagis-dbimport network`
subcommand.

## Synopsis

**netmagis-dbimport** [*OPTIONS*] **network** *FILE*

## File syntax

The network file contains blocks of *key*=*value* pairs
separated by empty lines.  Available keys are:


*name*
  : (mandatory) Name of the network

*address*
  : (mandatory) IPv4 or IPv6 network address with prefix (example:
    `198.51.100.0/24` or `2001:db8:1234::/48`). If a network has both
    IPv4 and IPv6 addresses, use one line `adress=` for each IP address.

*gateway*
  : (optional) IPv4 or IPv6 address of the gateway, if any.
    If your network has both IPv4 and IPv6 addresses, you can use one line
    `gateway=` for each IP address.

*comment*
  : (optional) Comment about this network.

*org*
  : (mandatory) Organization which owns this network. New organizations
    are automatically created.

*community*
  : (mandatory) Community for this network. New communities are
    automatically created.

*location*
  : (optional) Location for this network.

*groups*
  : (mandatory) List of groups which have access to this network.

*dhcp*
  : (optional) If the network is DHCP-enabled (IPv4 only), use this line
    to specify the following items:
	*domain* *range* *range*...
    Each range is given by two IPv4 adresses (for example
    `198.51.100.10-198.51.100.20`).  If the network does not have a
    `dhcp` line, DHCP is not enabled for this network.

## Example

Use the command:

    $ netmagis-dbimport -d network network.txt

to import the file `network.txt`.


# IMPORTING VIEWS

Netmagis supports multiple DNS views. Even if multiple views are not used,
one must provide a default view.


## Synopsis

**netmagis-dbimport** [*OPTIONS*] **view** *FILE*

## File syntax

Views are imported with a file containing lines of the form:

  *view* *keyword* *sort* *group* *group*...

Components of this line are:

*view*
  : view name. A view name may be repeated more than once in the file
    (with various parameters).

*keyword*
  : the keyword may be `SET` or `ALLBUT`. With `SET`, access to the
    view is granted to all groups cited on this line with the sort
    order (see below). With `ALLBUT`, access to the view is granted to
    all groups with the sort order, except for those cited on the line
    (which may be an empty list).

*sort*
  : the numerical sort is used to control appearance in interactive
    menus: lower values are listed first. If two views have the same
    sort order, lexicographic order on view names is used.

*group*
  : a valid group, which must already exist. See the `netmagis-dbimport
    group` subcommand to import groups.

Even if you have only one view, you must provide such a file with
the **default** view name, with a line such as:

	default ALLBUT 100

## Example

Use the command:

    $ netmagis-dbimport -d view view.txt

to import the file `view.txt`:


# IMPORTING DOMAINS

## Synopsis

**netmagis-dbimport** [*OPTIONS*] **domain** *FILE*

## File syntax

To import domains, you must supply a file containing lines of the
form:

  *domain* *keyword* *sort* *group* *group*...

Components of this line are:

*domain*
  : domain name. A domain name may be repeated more than once in the file
    (with various parameters).

*keyword*
  : the keyword is `SET` or `ALLBUT`. With `SET`, access to the
    domain is granted to all groups cited on this line with the sort
    order (see below). With `ALLBUT`, access to the domain is granted to
    all groups with the sort order, except for those cited on the line
    (which may be an empty list).

*sort*
  : the numerical sort is used to control appearance in interactive
    menus: lower values are listed first. If two domains have the same
    sort order, lexicographic order on domain names is used.

*group*
  : a valid group, which must already exist. See the `netmagis-dbimport
    group` subcommand to import groups.


## Example

Use the command:

    $ netmagis-dbimport -d domain domain.txt

to import the file `domain.txt`:


# IMPORTING ZONES

In order to import individual hosts and aliases, one must use the
`netmagis-dbimport zone` subcommand, with the following arguments:

## Synopsis

**netmagis-dbimport** [*OPTIONS*] **zone** *VIEW* *ZONENAME* *FILE* *SELECTOR* [*RRSUPFILE*]

This command accepts the following arguments:

VIEW
  : view name (use `default` if you don't use views at all).

ZONENAME
  : zone name to use in the Netmagis database. This name will also be used
    by the `mkzones` program as the file name for this zone on the
    DNS server.

FILE
  : file containing the zone contents, with two patterns described below
    (see the ``Pre-processing zone files'' section).

SELECTOR
  : selection criterion for this zone. For forward zones, this must
    be an existing domain name. For IPv4/IPv6 reverse zones, this must be
    a network prefix, such as `198.51.100.0/24' or '2001:db8:1234::/48'.

RRSUPFILE
  : name of a file containing additional resource records to add
    to each host name in generated zones. This is an obsolete feature
    and should not be used anymore.


## File syntax

Zone files must be pre-processed before importing them. The
`netmagis-dbimport` looks for two patterns, given as regular
expressions here:

**^; CUT HERE**
  : The string `; CUT HERE` must be located at the beginning of a
    line. It marks the end of the prologue and the beginning of regular
    records. The prologue is replicated in generated zones by the
    `mkzones` program. Regular records must be host definitions (type
    A or AAAA records) or alias definitions (type CNAME). Records type
    PTR, NS and MX are ignored.

**^ \d+ ; SERIAL**
  : The prologue must include a string matching this pattern to recognize
    the location of the zone serial number in the SOA resource
    record. This line will be replaced by the `%ZONEVERSION%` string in
    the prologue stored in Netmagis database, such as further zone
    generations will use an appropriate serial number.

Host and alias definitions are imported with forward zones. PTR records
in reverse zones are therefore not used. Importing a reverse zone is
used only for its prologue.

If an alias (A.D1) points to a host in another domain (H.D2), the
corresponding zone (for domain D2) may not be loaded yet and the host
does not exist in the database. If importing D2 first does not solve the
problem (for example if A'.D2 points to H'.D1), importing the zone (D1)
will generate a warning message about the host not found. Simply import
the other zone (D2) to define the host, and re-import the first zone file
(D1) to successfully import the alias.


## Example

Use the command:

    $ netmagis-dbimport -d zone external example.org-ext \
    				zone/example.org-ext example.org

to import the file `zone/example.org-ext` as the zone named
`example.org-ext` for the domain `example.org` in view `external`.

Use the command:

    $ netmagis-dbimport -d zone default 100.51.198.in-addr.arpa \
    				zones/100.51.198.in-addr.arpa 198.51.100/24

to import the file `zone/100.51.198.in-addr.arpa` as the zone named
`100.51.198.in-addr.arpa` containing all PTR records for hosts
in the 198.51.100/24 network. Since multiple views are not used
here, the `default` view name is used.


# IMPORTING MAIL RELAYS

Mail relays are the MX records for a domain.

## Synopsis

**netmagis-dbimport** [*OPTIONS*] **mailrelay** *VIEW* *FILE*

This import operation must be performed when all hosts and domains have
been imported in the database.

## File syntax

The mail relay file contains lines with the format:

  *domain* *priority* *host* *priority* *host*...

You can provide as many couples (*priority*, *host*) as needed for
a domain.

*domain*
  : the domain for which a MX resource record must be added.

*priority*
  : the priority to specify for the MX host.

*host*
  : the host which must receive the mail for this domain.


## Example

Use the command:

    $ netmagis-dbimport -d mailrelay external mailrelay.txt

to import the file `mailrelay.txt` for the view `external`.


# IMPORTING MAIL ROLES

Netmagis supports mail roles (i.e. mail addresses associated with
a supporting SMTP host) in order to provide mail routing inside a
domain. The `mkmroute` program uses Netmagis mail roles to generate a
mail routing file for some MTA (Sendmail, Postfix). Each mail address
is announced in the DNS as a MX pointing to the domain relays.

## Synopsis

**netmagis-dbimport** [*OPTIONS*] **mailrole** *VIEW* *FILE*

## File syntax

The mail role file contains lines with the format:

  *fqdn* *host*/*view* *host*/*view* ...

You can provide as many couples *host*/*view* as needed for a *fqdn*.

*fqdn*
  : the fully-qualified domain name of the mail address to create in
    the *VIEW* supplied as the argument to `netmagis-dbimport`.

*host*
  : the host which receives mail for this mail address.

*view*
  : the view in which the host must reside.
  
The view provided for each host is not necessarily the same as the view
provided as argument to `netmagis-dbimport`. For example, with 2 views
`external` (for external visibility) and `internal` (for internal use
in the organization only), one could use:
    
    netmagis-dbimport mailrole external mailrole.txt

to announce a MX record in the `external` view, and a `mailrole.txt`
file containing a route to a host in the `internal` view.


## Example

Use the command:

    $ netmagis-dbimport -d mailrole external mailrole.txt

to import the file `mailrole.txt` in view `external`



# EXIT STATUS

This utility exits 0 on success, and 1 if an error occurs.


# NETMAGIS.CONF KEYS

The following `netmagis.conf` keys are used in this program:

  > `dnsdbhost`, `dnsdbport`, `dnsdbname`, `dnsdbuser`, `dnsdbpassword`,
  `macdbhost`, `macdbport`, `macdbname`, `macdbuser`, `macdbpassword`,
  `rootusers`, `pwgen`, `ouiurl`


# ENVIRONMENT VARIABLES

The following Shell environment variables, if set, provide
alternative values for some installation-defined constants:

`NETMAGIS_CONFIG`
  : path of `netmagis.conf` configuration file.

    Default: `%CONFFILE%`

`NETMAGIS_LIBDIR`
  : library directory, which must contain the worker/
    and pkgtcl/ subdirectories.
    
    Default: `%NMLIBDIR%`

`NETMAGIS_VERSION`
  : Netmagis program version, used to check against database schema.

    Default: %VERSION%


# SEE ALSO

`netmagis.conf` (5),
`mkmroute` (1),
`mkzones` (1),
`netmagis-config` (1),
`netmagis-dbcreate` (1),
`netmagis-dbmaint` (1),
`netmagis-dbupgrade` (1),
`netmagis-getoui` (1),
`netmagis-restd` (1)

<http://netmagis.org>
