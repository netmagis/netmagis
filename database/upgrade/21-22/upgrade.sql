------------------------------------------------------------------------------
-- Database upgrade to 2.2 version
--
-- Use:
--	- psql -f upgrade.sql database-name
--
------------------------------------------------------------------------------

DELETE FROM global.config WHERE clef = 'dnsupdateperiod' ;

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

-- Disambiguate zone name and attach zones to views

ALTER TABLE dns.zone
    RENAME COLUMN domaine TO name ;

ALTER TABLE dns.zone
    ADD COLUMN idview INT
    ;

UPDATE dns.zone
    SET idview = (SELECT idview FROM dns.view WHERE name = 'default') ;

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

-- Add a new access right to views

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


-- Attach IP addresses to views

ALTER TABLE dns.rr_ip
    DROP CONSTRAINT rr_ip_pkey ;

ALTER TABLE dns.rr_ip
    ADD COLUMN idview INT ;

UPDATE dns.rr_ip
    SET idview = (SELECT idview FROM dns.view WHERE name = 'default') ;

ALTER TABLE dns.rr_ip
    ADD FOREIGN KEY (idview) REFERENCES dns.view (idview),
    ADD PRIMARY KEY (idrr, adr, idview)
    ;

-- Attach CNAME to views (CNAME and pointed RR must be in the same view)

ALTER TABLE dns.rr_cname
    DROP CONSTRAINT rr_cname_pkey ;

ALTER TABLE dns.rr_cname
    ADD COLUMN idview INT ;

UPDATE dns.rr_cname
    SET idview = (SELECT idview FROM dns.view WHERE name = 'default') ;

ALTER TABLE dns.rr_cname
    ADD FOREIGN KEY (idview) REFERENCES dns.view (idview),
    ADD PRIMARY KEY (idrr, cname, idview)
    ;

-- Attach MX to views (MX and pointed RR must be in the same view)

ALTER TABLE dns.rr_mx
    DROP CONSTRAINT rr_mx_pkey ;

ALTER TABLE dns.rr_mx
    ADD COLUMN idview INT ;

UPDATE dns.rr_mx
    SET idview = (SELECT idview FROM dns.view WHERE name = 'default') ;

ALTER TABLE dns.rr_mx
    ADD FOREIGN KEY (idview) REFERENCES dns.view (idview),
    ADD PRIMARY KEY (idrr, mx, idview)
    ;

-- Attach roles to views

ALTER TABLE dns.role_web
    DROP CONSTRAINT role_web_pkey ;

ALTER TABLE dns.role_web
    ADD COLUMN idview INT ;

UPDATE dns.role_web
    SET idview = (SELECT idview FROM dns.view WHERE name = 'default') ;

ALTER TABLE dns.role_web
    ADD FOREIGN KEY (idview) REFERENCES dns.view (idview),
    ADD PRIMARY KEY (idrr, idview)
    ;


ALTER TABLE dns.role_mail
    DROP CONSTRAINT role_mail_pkey ;

ALTER TABLE dns.role_mail
    ADD COLUMN idviewrr INT,
    ADD COLUMN idviewheb INT ;

UPDATE dns.role_mail
    SET idviewrr = (SELECT idview FROM dns.view WHERE name = 'default'),
	idviewheb = (SELECT idview FROM dns.view WHERE name = 'default')
    ;

ALTER TABLE dns.role_mail
    ADD FOREIGN KEY (idviewrr) REFERENCES dns.view (idview),
    ADD FOREIGN KEY (idviewheb) REFERENCES dns.view (idview),
    ADD PRIMARY KEY (idrr, idviewrr)
    ;

-- Attach mail relays to views

ALTER TABLE dns.relais_dom
    DROP CONSTRAINT relais_dom_pkey ;

ALTER TABLE dns.relais_dom
    ADD COLUMN idview INT ;

UPDATE dns.relais_dom
    SET idview = (SELECT idview FROM dns.view WHERE name = 'default') ;

ALTER TABLE dns.relais_dom
    ADD FOREIGN KEY (idview) REFERENCES dns.view (idview),
    ADD PRIMARY KEY (iddom, mx, idview)
    ;

