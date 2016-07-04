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

-- Add a flag for API keys
ALTER TABLE global.tmp ADD COLUMN api INT ;
ALTER TABLE global.tmp ALTER COLUMN api SET DEFAULT 0 ;

UPDATE global.tmp SET api = 0 ;

UPDATE global.config SET value = '30' WHERE key = 'schemaversion' ;
INSERT INTO global.config (key, value) VALUES ('apiexpire', '182') ;

DROP FUNCTION IF EXISTS dns.check_dhcprange_grp (INTEGER, INET, INET) ;
