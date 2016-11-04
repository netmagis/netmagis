CREATE SCHEMA global ;
CREATE SCHEMA dns ;
CREATE SCHEMA topo ;
CREATE SCHEMA pgauth ;

---------------------------------------------------------------------------
-- global schema
---------------------------------------------------------------------------

-- Netmagis users and groups
-- We can't use names "user" and "group" since they are reserved SQL words
-- and using them would mean quoting every request.

CREATE SEQUENCE global.seq_nmgroup START 1 ;
CREATE TABLE global.nmgroup (
    idgrp	INT			-- group id
		    DEFAULT NEXTVAL ('global.seq_nmgroup'),
    name	TEXT,			-- group name
    p_admin	INT DEFAULT 0,		-- 1 if root, 0 if normal user
    p_smtp	INT DEFAULT 0,		-- 1 if right to manage SMTP senders
    p_ttl	INT DEFAULT 0,		-- 1 if right to edit TTL for a host
    p_mac	INT DEFAULT 0,		-- 1 if right to access MAC module
    p_genl	INT DEFAULT 0,		-- 1 if right to generate a link number

    UNIQUE (name),
    PRIMARY KEY (idgrp)
) ;

CREATE SEQUENCE global.seq_nmuser START 1 ;
CREATE TABLE global.nmuser (
    idcor	INT			-- user id
		    DEFAULT NEXTVAL ('global.seq_nmuser'),
    login	TEXT,			-- user name
    present	INT,			-- 1 if present, 0 if no longer here
    idgrp	INT,			-- group

    UNIQUE (login),
    FOREIGN KEY (idgrp) REFERENCES global.nmgroup (idgrp),
    PRIMARY KEY (idcor)
) ;

-- Template for utmp and wtmp tables
CREATE TABLE global.tmp (
    idcor	INT,			-- user
    token	TEXT NOT NULL,		-- auth token in session cookie
    start	TIMESTAMP (0) WITHOUT TIME ZONE
                        DEFAULT CURRENT_TIMESTAMP
			NOT NULL,	-- login time
    ip		INET,			-- IP address at login time
    api		INT DEFAULT 0		-- 1: API key, 0: user session
) ;

-- Currently logged-in users
CREATE TABLE global.utmp (
    casticket	TEXT,			-- CAS service ticket
    lastaccess	TIMESTAMP (0) WITHOUT TIME ZONE
                        DEFAULT CURRENT_TIMESTAMP
			NOT NULL,	-- last access to a page

    FOREIGN KEY (idcor) REFERENCES global.nmuser (idcor),
    PRIMARY KEY (idcor, token)
) INHERITS (global.tmp) ;

-- All current and previous users. Table limited to 'wtmpexpire' days
CREATE TABLE global.wtmp (
    stop	TIMESTAMP (0) WITHOUT TIME ZONE
			NOT NULL,	-- logout or last access if expiration
    stopreason	TEXT NOT NULL,		-- 'logout', 'expired'

    FOREIGN KEY (idcor) REFERENCES global.nmuser (idcor),
    PRIMARY KEY (idcor, token)
) INHERITS (global.tmp) ;

-- Failed login attempts
CREATE TABLE global.authfail (
    origin	TEXT,			-- login name or IP address
    otype	TEXT,			-- type of origin ('ip' or 'login')
    nfail	INTEGER,		-- failed attempts count
    lastfail	TIMESTAMP (0)		-- date of last failed
		    WITHOUT TIME ZONE
		    DEFAULT CURRENT_TIMESTAMP,
    blockexpire	TIMESTAMP (0) WITHOUT TIME ZONE,

    PRIMARY KEY (origin, otype)
) ;

-- Netmagis configuration parameters (those which are not in the
-- configuration file)
CREATE TABLE global.config (
    key		TEXT,			-- configuration key
    value	TEXT,			-- key value

    PRIMARY KEY (key)
) ;

-- log
CREATE TABLE global.log (
    date	TIMESTAMP (0) WITHOUT TIME ZONE
		    DEFAULT CURRENT_TIMESTAMP
		    NOT NULL,
    subsys	TEXT NOT NULL,		-- subsystem ("dns", "topo", etc.)
    event	TEXT NOT NULL,		-- "addhost", "delalias", etc.
    login	TEXT,			-- user login
    ip		INET,			-- IP address
    msg		TEXT			-- log message
) ;

---------------------------------------------------------------------------
-- dns schema
---------------------------------------------------------------------------

-- domains

CREATE SEQUENCE dns.seq_domain START 1 ;
CREATE TABLE dns.domain (
    iddom	INT			-- domain id
		    DEFAULT NEXTVAL ('dns.seq_domain'),
    name	TEXT,			-- domain name (ex: "example.com")

    UNIQUE (name),
    PRIMARY KEY (iddom)
) ;

-- network, communities and organization descriptions

CREATE SEQUENCE dns.seq_organization START 1 ;
CREATE TABLE dns.organization (
    idorg	INT			-- organization id
		    DEFAULT NEXTVAL ('dns.seq_organization'),
    name	TEXT,			-- "Example Corp."

    PRIMARY KEY (idorg)
) ;

CREATE SEQUENCE dns.seq_community START 1 ;
CREATE TABLE dns.community (
    idcomm	INT			-- community id
		    DEFAULT NEXTVAL ('dns.seq_community'),
    name	TEXT,			-- "Administration"

    PRIMARY KEY (idcomm)
) ;

CREATE SEQUENCE dns.seq_network START 1 ;
CREATE TABLE dns.network (
    idnet	INT			-- network id
		    DEFAULT NEXTVAL ('dns.seq_network'),
    name	TEXT,			-- name (ex: "Servers")
    location	TEXT,			-- location if any
    addr4	CIDR,			-- IPv4 address range
    addr6	CIDR,			-- IPv6 address range
    idorg	INT,			-- organization this network belongs to
    idcomm	INT,			-- administration, R&D, etc.
    comment	TEXT,			-- comment
    dhcp	INT DEFAULT 0,		-- activate DHCP (1) or no (0)
    gw4		INET,			-- default network IPv4 gateway
    gw6		INET,			-- default network IPv6 gateway

    CONSTRAINT at_least_one_prefix_v4_or_v6
	CHECK (addr4 IS NOT NULL OR addr6 IS NOT NULL),
    CONSTRAINT gw4_in_net CHECK (gw4 <<= addr4),
    CONSTRAINT gw6_in_net CHECK (gw6 <<= addr6),
    CONSTRAINT dhcp_needs_ipv4_gateway
	CHECK (dhcp = 0 OR (dhcp != 0 AND gw4 IS NOT NULL)),
    FOREIGN KEY (idorg) REFERENCES dns.organization (idorg),
    FOREIGN KEY (idcomm) REFERENCES dns.community (idcomm),
    PRIMARY KEY (idnet)
) ;


-- DNS views
-- There is one entry for each observation point, which means
-- a class of clients allowed to see informations. For example:
-- "internal" and "external"

CREATE SEQUENCE dns.seq_view START 1 ;
CREATE TABLE dns.view (
    idview	INT			-- view id
		    DEFAULT NEXTVAL ('dns.seq_view'),
    name	TEXT,			-- e.g.: "internal", "external"...
    gendhcp	INT,			-- 1 if dhcp conf must be generated

    UNIQUE (name),
    PRIMARY KEY (idview)
) ;

-- DNS zone generation

CREATE SEQUENCE dns.seq_zone START 1 ;
CREATE TABLE dns.zone (
    idzone	INT			-- zone id
		    DEFAULT NEXTVAL ('dns.seq_zone'),
    name	TEXT,			-- zone name and name of generated file
    idview	INT,			-- view id
    version	INT,			-- version number
    prologue	TEXT,			-- zone prologue (with %ZONEVERSION% pattern)
    rrsup	TEXT,			-- added to each generated host
    gen		INT			-- modified since last generation
) ;

CREATE TABLE dns.zone_forward (
    selection	TEXT,			-- criterion to select names

    UNIQUE (name),
    FOREIGN KEY (idview) REFERENCES dns.view (idview),
    PRIMARY KEY (idzone)
) INHERITS (dns.zone) ;

CREATE TABLE dns.zone_reverse4 (
    selection	CIDR,			-- criterion to select addresses

    UNIQUE (name),
    FOREIGN KEY (idview) REFERENCES dns.view (idview),
    PRIMARY KEY (idzone)
) INHERITS (dns.zone) ;

CREATE TABLE dns.zone_reverse6 (
    selection	CIDR,			-- criterion to select addresses

    UNIQUE (name),
    FOREIGN KEY (idview) REFERENCES dns.view (idview),
    PRIMARY KEY (idzone)
) INHERITS (dns.zone) ;

-- host types

CREATE SEQUENCE dns.seq_hinfo MINVALUE 0 START 0 ;
CREATE TABLE dns.hinfo (
    idhinfo	INT			-- host type id
		    DEFAULT NEXTVAL ('dns.seq_hinfo'),
    name	TEXT,			-- type as text
    sort	INT,			-- sort class
    present	INT,			-- present or not
    PRIMARY KEY (idhinfo)
) ;

-- ranges allowed to groups

CREATE TABLE dns.p_network (
    idgrp	INT,			-- the group which manages this network
    idnet	INT,			-- the network
    sort	INT,			-- sort class
    dhcp	INT DEFAULT 0,		-- perm to manage DHCP ranges
    acl		INT DEFAULT 0,		-- perm to manage ACL (later...)

    FOREIGN KEY (idgrp) REFERENCES global.nmgroup (idgrp),
    FOREIGN KEY (idnet) REFERENCES dns.network (idnet),
    PRIMARY KEY (idgrp, idnet)
) ;

-- domains allowed to groups

CREATE TABLE dns.p_dom (
    idgrp	INT,			-- group
    iddom	INT,			-- domain id
    sort	INT,			-- sort class
    mailrole	INT DEFAULT 0,		-- perm to manage mail roles

    FOREIGN KEY (idgrp) REFERENCES global.nmgroup (idgrp),
    PRIMARY KEY (idgrp, iddom)
) ;

-- IP ranges allowed to groups

CREATE TABLE dns.p_ip (
    idgrp	INT,			-- group
    addr	CIDR,			-- network range
    allow_deny	INT,			-- 1 = allow, 0 = deny

    FOREIGN KEY (idgrp) REFERENCES global.nmgroup (idgrp),
    PRIMARY KEY (idgrp, addr)
) ;

-- views allowed to groups

CREATE TABLE dns.p_view (
    idgrp	INT,			-- group
    idview	INT,			-- the view
    sort	INT,			-- sort class
    selected	INT,			-- selected by default in menus

    FOREIGN KEY (idgrp) REFERENCES global.nmgroup (idgrp),
    FOREIGN KEY (idview) REFERENCES dns.view (idview),
    PRIMARY KEY (idgrp, idview)
) ;


-- DHCP profiles

CREATE SEQUENCE dns.seq_dhcpprofile START 1 ;
CREATE TABLE dns.dhcpprofile (
    iddhcpprof	INT			-- DHCP profile id
		    DEFAULT NEXTVAL ('dns.seq_dhcpprofile'),
    name 	TEXT UNIQUE,		-- DHCP profile name
    text	TEXT,			-- text to add before host declarations

    CHECK (iddhcpprof >= 1),
    PRIMARY KEY (iddhcpprof)
) ;

-- DHCP profiles allowed to groups

CREATE TABLE dns.p_dhcpprofile (
    idgrp	INT,			-- group
    iddhcpprof	INT,			-- DHCP profile
    sort	INT,			-- sort class

    FOREIGN KEY (idgrp)      REFERENCES global.nmgroup  (idgrp),
    FOREIGN KEY (iddhcpprof) REFERENCES dns.dhcpprofile (iddhcpprof),
    PRIMARY KEY (idgrp, iddhcpprof)
) ;

-- DHCP dynamic ranges

CREATE SEQUENCE dns.seq_dhcprange START 1 ;
CREATE TABLE dns.dhcprange (
    iddhcprange	INT			-- for store-tabular use
		    DEFAULT NEXTVAL ('dns.seq_dhcprange'),
    min 	INET UNIQUE,		-- min address of range
    max		INET UNIQUE,		-- max address of range
    iddom	INT,			-- domain returned by DHCP server
    default_lease_time	INT DEFAULT 0,	-- unit = second
    max_lease_time	INT DEFAULT 0,	-- unit = second
    iddhcpprof	INT,			-- DHCP profile for this range

    CHECK (min <= max),
    FOREIGN KEY (iddom) REFERENCES dns.domain (iddom),
    FOREIGN KEY (iddhcpprof) REFERENCES dns.dhcpprofile (iddhcpprof),
    PRIMARY KEY (iddhcprange)
) ;

-- Central point in Netmagis : a name (name + domain) in a view

CREATE SEQUENCE dns.seq_name START 1 ;
CREATE TABLE dns.name (
    idname	INT			-- name id
		    DEFAULT NEXTVAL ('dns.seq_name'),
    name	TEXT,			-- first component of FQDN
    iddom	INT,			-- domain id
    idview	INT,			-- view id

    UNIQUE (name, iddom, idview),
    PRIMARY KEY (idname)
) ;

-- Some of these names are hosts...

CREATE SEQUENCE dns.seq_host START 1 ;
CREATE TABLE dns.host (
    idhost	INT			-- host id
		    DEFAULT NEXTVAL ('dns.seq_host'),
    idname	INT,			-- reference to the name
    mac		MACADDR,		-- MAC address or NULL
    iddhcpprof	INT,			-- DHCP profile or NULL
    idhinfo	INT DEFAULT 0,		-- host type
    comment	TEXT,			-- comment
    respname	TEXT,			-- name of responsible person
    respmail	TEXT,			-- mail address of responsible person
    sendsmtp	INT DEFAULT 0,		-- 1 if this host may emit with SMTP
    ttl		INT DEFAULT -1,		-- TTL if different from zone TTL

    FOREIGN KEY (idname)     REFERENCES dns.name        (idname),
    FOREIGN KEY (iddhcpprof) REFERENCES dns.dhcpprofile (iddhcpprof),
    FOREIGN KEY (idhinfo)    REFERENCES dns.hinfo       (idhinfo),
    UNIQUE (idname),
    PRIMARY KEY (idhost)
) ;

-- ... hosts with IP (v4 or v6) addresses

CREATE TABLE dns.addr (
    idhost	INT,			-- host id
    addr	INET,			-- IP (v4 or v6) address

    FOREIGN KEY (idhost)     REFERENCES dns.host        (idhost),
    PRIMARY KEY (idhost, addr)
) ;

-- Some names are aliases to existing hosts

CREATE TABLE dns.alias (
    idname	INT,			-- name id
    idhost	INT,			-- host pointed by this alias
    ttl		INT DEFAULT -1,		-- TTL if different from zone TTL

    FOREIGN KEY (idname)     REFERENCES dns.name        (idname),
    FOREIGN KEY (idhost)     REFERENCES dns.host        (idhost),
    PRIMARY KEY (idname)
) ;

-- Some names may also be MX pointing to one or more hosts

CREATE TABLE dns.mx (
    idname	INT,			-- MX name
    prio	INT,			-- priority
    idhost	INT,			-- MX target host
    ttl		INT DEFAULT -1,		-- TTL if different from zone TTL

    FOREIGN KEY (idname)     REFERENCES dns.name        (idname),
    FOREIGN KEY (idhost)     REFERENCES dns.host        (idhost),
    PRIMARY KEY (idname, idhost)
) ;

-- Some names are mail addresses (served by a mbox host which
-- may be in another view)

CREATE TABLE dns.mailrole (
    mailaddr	INT,			-- mail address
    mboxhost	INT,			-- host holding mboxes for this address
    ttl		INT DEFAULT -1,		-- TTL if different from zone TTL

    FOREIGN KEY (mailaddr)   REFERENCES dns.name        (idname),
    FOREIGN KEY (mboxhost)   REFERENCES dns.host        (idhost),
    PRIMARY KEY (mailaddr)
) ;

-- When a mailrole is declared, Netmagis publishes MX declared
-- for the domain in the DNS zone

CREATE TABLE dns.relaydom (
    iddom	INT,			-- domain id
    prio	INT,			-- MX priority
    idhost	INT,			-- relay host for this domain
    ttl		INT DEFAULT -1,		-- TTL if different from zone TTL

    FOREIGN KEY (iddom)      REFERENCES dns.domain      (iddom),
    FOREIGN KEY (idhost)     REFERENCES dns.host        (idhost),
    PRIMARY KEY (iddom, idhost)
) ;

---------------------------------------------------------------------------
-- topo schema
---------------------------------------------------------------------------

-- Modified equipement spool

CREATE TABLE topo.modeq (
    eq		TEXT,			-- fully qualified equipement name
    date	TIMESTAMP (0)		-- detection date
		    WITHOUT TIME ZONE
		    DEFAULT CURRENT_TIMESTAMP,
    login	TEXT,			-- detected user
    processed	INT DEFAULT 0
) ;

CREATE INDEX modeq_index ON topo.modeq (eq) ;

-- Interface change request spool

CREATE TABLE topo.ifchanges (
    login	TEXT,			-- requesting user
    reqdate	TIMESTAMP (0)		-- request date
		    WITHOUT TIME ZONE
		    DEFAULT CURRENT_TIMESTAMP,
    eq		TEXT,			-- fully qualified equipement name
    iface	TEXT,			-- interface name
    ifdesc	TEXT,			-- interface description
    ethervlan	INT,			-- access vlan id
    voicevlan	INT,			-- voice vlan id
    processed	INT DEFAULT 0,		-- modification processed
    moddate	TIMESTAMP (0)		-- modification (or last attempt) date
		     WITHOUT TIME ZONE,
    modlog	TEXT,			-- modification (or last attempt) log

    PRIMARY KEY (eq, reqdate, iface)
) ;

-- Last rancid run

CREATE TABLE topo.lastrun (
    date	TIMESTAMP (0)		-- detection date
		    WITHOUT TIME ZONE
) ;

-- Keepstate events

CREATE TABLE topo.keepstate (
    type	TEXT,			-- "rancid", "anaconf"
    message	TEXT,			-- last message
    date	TIMESTAMP (0)		-- first occurrence of this message
		    WITHOUT TIME ZONE
		    DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (type)
) ;

-- Users to ignore : don't log any event in the modified equipement spool
-- for these users because we know they have only a read-only access to the
-- equipements

CREATE TABLE topo.ignoreequsers (
    login	TEXT UNIQUE NOT NULL		-- user login
) ;

-- Access rights to equipements

CREATE TABLE topo.p_eq (
    idgrp	INT,			-- group upon which this access right applies
    rw		INT,			-- 0 : read, 1 : write
    pattern	TEXT NOT NULL,		-- regular expression
    allow_deny	INT,			-- 1 = allow, 0 = deny

    FOREIGN KEY (idgrp) REFERENCES global.nmgroup (idgrp)
) ;

-- Access rights to L2-only networks

CREATE TABLE topo.p_l2only (
    idgrp	INT,			-- group upon which this access right applies
    vlanid	INT,			-- 1...4094

    PRIMARY KEY (idgrp, vlanid),
    FOREIGN KEY (idgrp) REFERENCES global.nmgroup (idgrp)
) ;

-- Sensor definition

-- type trafic
--	iface = iface[.vlan]
--	param = NULL
-- type number of assoc wifi
--	iface = iface
--	ssid
-- type number of auth wifi
--	iface = iface
--	param = ssid
-- type broadcast traffic
--	iface = iface[.vlan]
--	param = NULL
-- type multicast traffic
--	iface = iface[.vlan]
--	param = NULL

CREATE TABLE topo.sensor (
    id		TEXT,			-- M1234
    type	TEXT,			-- trafic, nbassocwifi, nbauthwifi, etc.
    eq		TEXT,			-- fqdn
    comm	TEXT,			-- snmp communuity
    iface	TEXT,
    param	TEXT,
    lastmod	TIMESTAMP (0)		-- last modification date
		    WITHOUT TIME ZONE
		    DEFAULT CURRENT_TIMESTAMP,
    lastseen	TIMESTAMP (0)		-- last detection date
		    WITHOUT TIME ZONE
		    DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id)
) ;


-- Topod file monitor

CREATE TABLE topo.filemonitor (
	path	TEXT,			-- path to file or directory
	date	TIMESTAMP (0)		-- last modification date
		    WITHOUT TIME ZONE
		    DEFAULT CURRENT_TIMESTAMP,

	PRIMARY KEY (path)
) ;

-- Vlan table

CREATE TABLE topo.vlan (
	vlanid	INT,			-- 1..4094
	descr	TEXT,			-- description
	voip	INT DEFAULT 0,		-- 1 if VoIP vlan, 0 if standard vlan

	PRIMARY KEY (vlanid)
) ;

-- Equipment types and equipment list to create rancid router.db file

CREATE SEQUENCE topo.seq_eqtype START 1 ;

CREATE TABLE topo.eqtype (
    idtype	INTEGER			-- type id
		    DEFAULT NEXTVAL ('topo.seq_eqtype'),
    type	TEXT,			-- cisco, hp, juniper, etc.

    UNIQUE (type),
    PRIMARY KEY (idtype)
) ;

CREATE SEQUENCE topo.seq_eq START 1 ;

CREATE TABLE topo.eq (
    ideq	INTEGER			-- equipment id
		    DEFAULT NEXTVAL ('topo.seq_eq'),
    eq		TEXT,			-- fqdn
    idtype	INTEGER,
    up		INTEGER,		-- 1 : up, 0 : 0

    FOREIGN KEY (idtype) REFERENCES topo.eqtype (idtype),
    UNIQUE (eq),
    PRIMARY KEY (ideq)
) ;

CREATE SEQUENCE topo.seq_confcmd START 1 ;

CREATE TABLE topo.confcmd (
    idccmd	INTEGER			-- entry id
		    DEFAULT NEXTVAL ('topo.seq_confcmd'),
    idtype	INTEGER,		-- equipment type
    action	TEXT,			-- action selector : prologue, ifreset
    rank	INTEGER,		-- sort order
    model	TEXT,			-- regexp matching equipment model
    command	TEXT,			-- command to send

    FOREIGN KEY (idtype) REFERENCES topo.eqtype (idtype),
    PRIMARY KEY (idccmd)
) ;

-- graphviz attributes for equipements in L2 graphs
CREATE TABLE topo.dotattr (
    rank	INTEGER,		-- sort order
    type	INTEGER,		-- 2: l2, 3: l3 graph
    regexp	TEXT,			-- regexp
    gvattr	TEXT,			-- graphviz node attributes
    png		BYTEA,			-- PNG generated by graphviz

    PRIMARY KEY (rank)
) ;

-- link number and description
CREATE SEQUENCE topo.seq_link START 1 ;
CREATE TABLE topo.link (
    idlink	INT             -- group id
		     DEFAULT NEXTVAL ('topo.seq_link'),
    descr	TEXT,           -- link description

    PRIMARY KEY (idlink)
) ;

---------------------------------------------------------------------------
-- pgauth schema
---------------------------------------------------------------------------

CREATE TABLE pgauth.user (
    login	TEXT,			-- login name
    password	TEXT,			-- crypted password
    lastname	TEXT,			-- last name
    firstname	TEXT,			-- first name
    mail	TEXT,			-- mail address
    phone	TEXT,			-- telephone number
    mobile	TEXT,			-- mobile phone number
    fax		TEXT,			-- facsimile number
    addr	TEXT,			-- postal address
    -- columns automatically managed by triggers
    phlast	TEXT,			-- phonetical last name
    phfirst	TEXT,			-- phonetical first name

    PRIMARY KEY (login)
) ;

CREATE TABLE pgauth.realm (
    realm	TEXT,			-- realm name
    descr	TEXT,			-- realm description
    admin	INT,			-- 1 if admin

    PRIMARY KEY (realm)
) ;

CREATE TABLE pgauth.member (
    login	TEXT,			-- login name
    realm	TEXT,			-- realm of this login

    FOREIGN KEY (login) REFERENCES pgauth.user (login),
    FOREIGN KEY (realm) REFERENCES pgauth.realm (realm),
    PRIMARY KEY (login, realm)
) ;
