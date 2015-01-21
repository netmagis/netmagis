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

CREATE TABLE global.session (
    token	TEXT NOT NULL,		-- auth token in session cookie
    idcor	INT,			-- user authenticated by this token
    valid	INT,			-- 1 if token is valid, otherwise 0
    lastlogin	TIMESTAMP (0) WITHOUT TIME ZONE
                        DEFAULT CURRENT_TIMESTAMP
			NOT NULL,	-- last successful login
    lastaccess	TIMESTAMP (0) WITHOUT TIME ZONE
                        DEFAULT CURRENT_TIMESTAMP
			NOT NULL,	-- last access to a page

    FOREIGN KEY (idcor) REFERENCES global.nmuser (idcor),
    PRIMARY KEY (token)
) ;

DELETE FROM global.config where key = 'ldapattrpasswd' ;

INSERT INTO global.config (key, value) VALUES ('authexpire', '36000') ;
INSERT INTO global.config (key, value) VALUES ('authtoklen', '32') ;

UPDATE global.config SET value = '23' WHERE key = 'schemaversion' ;
