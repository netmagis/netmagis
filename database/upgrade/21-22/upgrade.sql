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
    ADD FOREIGN KEY (idview) REFERENCES dns.view (idview),
    ADD PRIMARY KEY (idzone)
    ;

ALTER TABLE dns.zone_reverse4
    ADD UNIQUE (name),
    ADD FOREIGN KEY (idview) REFERENCES dns.view (idview),
    ADD PRIMARY KEY (idzone)
    ;

ALTER TABLE dns.zone_reverse6
    ADD UNIQUE (name),
    ADD FOREIGN KEY (idview) REFERENCES dns.view (idview),
    ADD PRIMARY KEY (idzone)
    ;

-- Add views

CREATE SEQUENCE dns.seq_view START 1 ;
CREATE TABLE dns.view (
    idview	INT		-- view id
	    DEFAULT NEXTVAL ('dns.seq_view'),
    name	TEXT,		-- e.g.: "internal", "external"...

    UNIQUE (name),
    PRIMARY KEY (idview)
) ;

INSERT INTO dns.view (name) VALUES ('default') ;

ALTER TABLE dns.zone
    ADD COLUMN idview INT ;

UPDATE dns.zone
    SET idview = (SELECT idview FROM dns.view WHERE name = 'default') ;

CREATE TABLE dns.dr_view (
    idgrp	INT,		-- group
    idview	INT,		-- the view
    sort	INT,		-- sort class
    selected	INT,		-- selected by default in menus

    FOREIGN KEY (idgrp) REFERENCES global.groupe (idgrp),
    FOREIGN KEY (idview) REFERENCES dns.view (idview),
    PRIMARY KEY (idgrp, idview)
) ;

INSERT INTO dns.dr_view (idgrp, idview, sort, selected)
    SELECT idgrp, idview, 100, 1
	    FROM global.groupe, dns.view
	    WHERE view.name = 'default' ;
