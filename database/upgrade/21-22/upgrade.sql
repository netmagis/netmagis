------------------------------------------------------------------------------
-- Database upgrade to 2.2 version
--
-- Use:
--	- psql -f upgrade.sql database-name
--
------------------------------------------------------------------------------

DELETE FROM global.config WHERE clef = 'dnsupdateperiod' ;

ALTER TABLE dns.zone RENAME COLUMN domaine TO name ;

ALTER TABLE dns.zone_normale
    ADD UNIQUE (name),
    ADD PRIMARY KEY (idzone) ;

ALTER TABLE dns.zone_reverse4
    ADD UNIQUE (name),
    ADD PRIMARY KEY (idzone) ;

ALTER TABLE dns.zone_reverse6
    ADD UNIQUE (name),
    ADD PRIMARY KEY (idzone) ;
