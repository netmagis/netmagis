------------------------------------------------------------------------------
-- Database upgrade to 2.3 version
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

-- Template for utmp and wtmp tables
CREATE TABLE global.tmp (
    idcor	INT,			-- user
    token	TEXT NOT NULL,		-- auth token in session cookie
    start	TIMESTAMP (0) WITHOUT TIME ZONE
                        DEFAULT CURRENT_TIMESTAMP
			NOT NULL,	-- login time
    ip		INET,			-- IP address at login time

    FOREIGN KEY (idcor) REFERENCES global.nmuser (idcor),
    PRIMARY KEY (idcor, token)
) ;

-- Currently logged-in users
CREATE TABLE global.utmp (
    lastaccess	TIMESTAMP (0) WITHOUT TIME ZONE
                        DEFAULT CURRENT_TIMESTAMP
			NOT NULL	-- last access to a page
) INHERITS (global.tmp) ;

-- All current and previous users. Table limited to 'wtmpexpire' days
CREATE TABLE global.wtmp (
    stop	TIMESTAMP (0) WITHOUT TIME ZONE
			NOT NULL,	-- logout or last access if expiration
    stopreason	TEXT NOT NULL		-- 'logout', 'expired'
) INHERITS (global.tmp) ;


DELETE FROM global.config where key = 'ldapattrpasswd' ;

INSERT INTO global.config (key, value) VALUES ('authexpire', '36000') ;
INSERT INTO global.config (key, value) VALUES ('authtoklen', '32') ;
INSERT INTO global.config (key, value) VALUES ('wtmpexpire', '365') ;

UPDATE global.config SET value = '23' WHERE key = 'schemaversion' ;
