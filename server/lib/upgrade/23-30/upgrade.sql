------------------------------------------------------------------------------
-- Database upgrade to 3.0 version
--
-- Use:
--	psql --no-psqlrc --single-transaction -f upgrade.sql database-name
--
-- Please, make a backup of your existing database first!
-- Use a tool such as nohup or script in order to log output and check
-- error messages:
--	- Lines with "NOTICE:" are not important.
--	- You should pay attention to lines with "ERROR:" 
------------------------------------------------------------------------------

-- Stop at the first encountered error
\set ON_ERROR_STOP 1

-- Add a flag for API keys
ALTER TABLE global.tmp ADD COLUMN api INT ;
ALTER TABLE global.tmp ALTER COLUMN api SET DEFAULT 0 ;

UPDATE global.tmp SET api = 0 ;

UPDATE global.config SET value = '30' WHERE key = 'schemaversion' ;
INSERT INTO global.config (key, value) VALUES ('apiexpire', '182') ;

DROP FUNCTION IF EXISTS dns.check_dhcprange_grp (INTEGER, INET, INET) ;

--
-- Create new tables in order to avoid altering existing tables:
-- 	- database schema is deeply altered by splitting rr into names
--		and hosts, so many tables are impacted
--	- rather than altering existing tables, we create fresh tables
--		to avoid renaming constraints (even if constraints would
--		still work)
--

-- Central point : a name (name + domain) in a view

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

    FOREIGN KEY (idhost) REFERENCES dns.host (idhost) ON DELETE CASCADE,
    PRIMARY KEY (idhost, addr)
) ;

-- Some names are aliases to existing hosts

CREATE TABLE dns.alias (
    idname	INT,			-- name id
    idhost	INT,			-- host pointed by this alias
    ttl		INT DEFAULT -1,		-- TTL if different from zone TTL

    FOREIGN KEY (idname)   REFERENCES dns.name     (idname),
    FOREIGN KEY (idhost)   REFERENCES dns.host     (idhost),
    PRIMARY KEY (idname)
) ;

-- Some names may also be MX pointing to one or more hosts

CREATE TABLE dns.mx (
    idname	INT,			-- MX name
    prio	INT,			-- priority
    idhost	INT,			-- MX target host
    ttl		INT DEFAULT -1,		-- TTL if different from zone TTL

    FOREIGN KEY (idname)   REFERENCES dns.name     (idname),
    FOREIGN KEY (idhost)   REFERENCES dns.host     (idhost),
    PRIMARY KEY (idname, idhost)
) ;

-- Some names are mail addresses (served by a mbox host which
-- may be in another view)

CREATE TABLE dns.mailrole (
    idname	INT,			-- mail address
    idhost	INT,			-- host holding mboxes for this address
    ttl		INT DEFAULT -1,		-- TTL if different from zone TTL

    FOREIGN KEY (idname)   REFERENCES dns.name     (idname),
    FOREIGN KEY (idhost)   REFERENCES dns.host     (idhost),
    PRIMARY KEY (idname)
) ;

-- When a mailrole is declared, Netmagis publishes MX declared
-- for the domain in the DNS zone

CREATE TABLE dns.relaydom (
    iddom	INT,			-- domain id
    prio	INT,			-- MX priority
    idhost	INT,			-- relay host for this domain
    ttl		INT DEFAULT -1,		-- TTL if different from zone TTL

    FOREIGN KEY (iddom)      REFERENCES dns.domain (iddom),
    FOREIGN KEY (idhost)     REFERENCES dns.host   (idhost),
    PRIMARY KEY (iddom, idhost)
) ;

INSERT INTO dns.name (idname, name, iddom, idview)
    SELECT idrr, name, iddom, idview
	FROM dns.rr ;

INSERT INTO dns.host (idhost, idname, mac, iddhcpprof, idhinfo,
			comment, respname, respmail, sendsmtp, ttl)
    SELECT DISTINCT idrr, idrr, mac, iddhcpprof, idhinfo,
    		comment, respname, respmail, sendsmtp, ttl
	FROM dns.rr
	    NATURAL INNER JOIN dns.rr_ip
	;

INSERT INTO dns.addr (idhost, addr)
    SELECT idrr, addr FROM dns.rr_ip ;

INSERT INTO dns.alias (idname, idhost)
    SELECT idrr, cname FROM dns.rr_cname ;

INSERT INTO dns.mx (idname, prio, idhost)
    SELECT idrr, prio, mx FROM dns.rr_mx ;

INSERT INTO dns.mailrole (idname, idhost)
    SELECT mailaddr, mboxhost FROM dns.mail_role ;

INSERT INTO dns.relaydom (iddom, prio, idhost)
    SELECT iddom, prio, mx FROM dns.relay_dom ;

-- use a DO block in order to use PERFORM, in order to ignore setval output
DO $$
BEGIN
    PERFORM setval ('dns.seq_name', max (idrr)) FROM dns.rr ;
    PERFORM setval ('dns.seq_host', max (idrr)) FROM dns.rr ;
END $$ ;

-- DROP ... CASCADE also removes our triggers (but not trigger functions)
DROP TABLE dns.relay_dom CASCADE ;
DROP TABLE dns.mail_role CASCADE ;
DROP TABLE dns.rr_mx CASCADE ;
DROP TABLE dns.rr_cname CASCADE ;
DROP TABLE dns.rr_ip CASCADE ;
DROP TABLE dns.rr CASCADE ;

DROP SEQUENCE dns.seq_rr ;

DROP FUNCTION dns.mod_ip () ;
DROP FUNCTION dns.gen_norm_idrr (INTEGER) ;
DROP FUNCTION dns.mod_mxcname () ;
DROP FUNCTION dns.mod_rr () ;

-- New log format
ALTER TABLE global.log
    ADD COLUMN version INTEGER,
    ADD COLUMN jbefore JSONB,
    ADD COLUMN jafter  JSONB ;
UPDATE global.log SET version = 0 ;
ALTER TABLE global.log
    ALTER COLUMN version SET NOT NULL ;
