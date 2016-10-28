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

CREATE TABLE dns.addr (
    idhost	INT,			-- host id
    addr	INET,			-- IP (v4 or v6) address

    FOREIGN KEY (idhost)     REFERENCES dns.host        (idhost),
    PRIMARY KEY (idhost, addr)
) ;

CREATE TABLE dns.alias (
    idname	INT,			-- name id
    idhost	INT,			-- host pointed by this alias

    FOREIGN KEY (idname)     REFERENCES dns.name        (idname),
    FOREIGN KEY (idhost)     REFERENCES dns.host        (idhost),
    PRIMARY KEY (idname)
) ;

CREATE TABLE dns.mx (
    idname	INT,			-- MX name
    prio	INT,			-- priority
    target	INT,			-- target host

    FOREIGN KEY (idname)     REFERENCES dns.name        (idname),
    FOREIGN KEY (target)     REFERENCES dns.host        (idhost),
    PRIMARY KEY (idname, target)
) ;

CREATE TABLE dns.mailrole (
    mailaddr	INT,			-- mail address
    mboxhost	INT,			-- host holding mboxes for this address

    FOREIGN KEY (mailaddr)   REFERENCES dns.name        (idname),
    FOREIGN KEY (mboxhost)   REFERENCES dns.host        (idhost),
    PRIMARY KEY (mailaddr)
) ;

CREATE TABLE dns.relaydom (
    iddom	INT,			-- domain id
    prio	INT,			-- MX priority
    mx		INT,			-- relay host for this domain

    FOREIGN KEY (iddom)      REFERENCES dns.domain      (iddom),
    FOREIGN KEY (mx)         REFERENCES dns.host        (idhost),
    PRIMARY KEY (iddom, mx)
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

INSERT INTO dns.mx (idname, prio, target)
    SELECT idrr, prio, mx FROM dns.rr_mx ;

INSERT INTO dns.mailrole (mailaddr, mboxhost)
    SELECT mailaddr, mboxhost FROM dns.mail_role ;

INSERT INTO dns.relaydom (iddom, prio, mx)
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

DROP FUNCTION dns.mod_ip () ;
DROP FUNCTION dns.gen_norm_idrr (INTEGER) ;
DROP FUNCTION dns.mod_mxcname () ;
DROP FUNCTION dns.mod_rr () ;
