------------------------------------------------------------------------------
-- Topo Schema
--
-- Method :
--	- psql -f topo.sql dns
--
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Schema
------------------------------------------------------------------------------

CREATE USER detecteq ;
ALTER USER detecteq UNENCRYPTED PASSWORD 'XXXXXX' ;

GRANT SELECT ON rr, rr_ip, domaine TO detecteq ;

CREATE SCHEMA topo ;

------------------------------------------------------------------------------
-- Modified equipement spool
------------------------------------------------------------------------------

CREATE TABLE topo.modeq (
	eq		TEXT,		-- fully qualified equipement name
	date		TIMESTAMP (0)	-- detection date
			    WITHOUT TIME ZONE
			    DEFAULT CURRENT_TIMESTAMP,
	login		TEXT,		-- detected user
	processed	INT DEFAULT 0,
	PRIMARY KEY (eq, date)
) ;

------------------------------------------------------------------------------
-- Interface change request spool
------------------------------------------------------------------------------

CREATE TABLE topo.ifchanges (
	login		TEXT,		-- requesting user
	reqdate		TIMESTAMP (0)	-- request date
			    WITHOUT TIME ZONE
			    DEFAULT CURRENT_TIMESTAMP,
	idrr		INT,		-- equipement id
	iface		TEXT,		-- interface name
	ifdesc		TEXT,		-- interface description
	ethervlan	INT,		-- access vlan id
	voicevlan	INT,		-- voice vlan id
	processed	INT DEFAULT 0,	-- modification processed
	moddate		TIMESTAMP (0)	-- modification (or last attempt) date
			    WITHOUT TIME ZONE,
	modlog		TEXT,		-- modification (or last attempt) log
	FOREIGN KEY (idrr) REFERENCES rr (idrr),
	PRIMARY KEY (idrr, reqdate)
) ;

------------------------------------------------------------------------------
-- Last rancid run
------------------------------------------------------------------------------

CREATE TABLE topo.lastrun (
	date		TIMESTAMP (0)	-- detection date
			    WITHOUT TIME ZONE
) ;

------------------------------------------------------------------------------
-- Keepstate events
------------------------------------------------------------------------------

CREATE TABLE topo.keepstate (
    type	TEXT,		-- "rancid", "anaconf"
    message	TEXT,		-- last message
    date	TIMESTAMP (0)	-- first occurrence of this message
			WITHOUT TIME ZONE
			DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (type)
) ;

------------------------------------------------------------------------------
-- Users to ignore : don't log any event in the modified equipement spool
-- for these users because we know they have only a read-only access to the
-- equipements
------------------------------------------------------------------------------

CREATE TABLE topo.ignoreequsers (
	login		TEXT UNIQUE NOT NULL	-- user login
) ;

INSERT INTO topo.ignoreequsers VALUES ('conf') ;

------------------------------------------------------------------------------
-- Authorizations
------------------------------------------------------------------------------

GRANT USAGE ON SCHEMA topo TO dns, detecteq, pda, jean ;
GRANT CREATE ON SCHEMA topo TO pda, jean ;

GRANT SELECT ON topo.ignoreequsers TO detecteq ;
GRANT INSERT ON topo.modeq TO detecteq ;

GRANT ALL
    ON topo.modeq, topo.ifchanges, topo.lastrun, topo.keepstate
    TO dns, pda, jean ;
