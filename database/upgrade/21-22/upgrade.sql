------------------------------------------------------------------------------
-- Database upgrade to 2.2 version
--
-- Use:
--	- psql -f upgrade.sql database-name
--
------------------------------------------------------------------------------

DELETE FROM global.config WHERE clef = 'dnsupdateperiod' ;

DROP TABLE dns.dhcp ;

-- Update trigger functions

    -- called when an IPv6 address is modified ($1=addr, $2=idview)
    CREATE OR REPLACE FUNCTION gen_rev4 (INET, INTEGER)
	RETURNS INTEGER AS $$
	BEGIN
	    UPDATE dns.zone_reverse4 SET generer = 1
		WHERE $1 <<= selection AND idview = $2 ;
	    RETURN 1 ;
	END ;
	$$ LANGUAGE 'plpgsql' ;

    -- called when an IPv6 address is modified ($1=addr, $2=idview)
    CREATE OR REPLACE FUNCTION gen_rev6 (INET, INTEGER)
	RETURNS INTEGER AS $$
	BEGIN
	    UPDATE dns.zone_reverse6 SET generer = 1
	    	WHERE $1 <<= selection AND idview = $2 ;
	    RETURN 1 ;
	END ;
	$$ LANGUAGE 'plpgsql' ;

    -- ID of RR ($1=idrr, $2=idview)
    CREATE OR REPLACE FUNCTION gen_norm_idrr (INTEGER, INTEGER)
	RETURNS INTEGER AS $$
	BEGIN
	    UPDATE dns.zone_normale SET generer = 1
		    WHERE idview = $2
			AND selection = (
			    SELECT domaine.nom
				    FROM dns.domaine, dns.rr
				    WHERE rr.idrr = $1
					AND rr.iddom = domaine.iddom
			    ) ;
	    RETURN 1 ;
	END ;
	$$ LANGUAGE 'plpgsql' ;

    -- ID of RR ($1=iddom, $2=idview)
    CREATE OR REPLACE FUNCTION gen_norm_iddom (INTEGER, INTEGER)
	RETURNS INTEGER AS $$
	BEGIN
	    UPDATE dns.zone_normale SET generer = 1
		    WHERE idview = $2
			AND selection = (
			    SELECT domaine.nom
				    FROM dns.domaine
				    WHERE domaine.iddom = $1
			    ) ;
	    RETURN 1 ;
	END ;
	$$ LANGUAGE 'plpgsql' ;

    -- called when a RR is modified in a view ($1=idrr, $2=idview)
    CREATE OR REPLACE FUNCTION gen_dhcp (INTEGER, INTEGER)
	RETURNS INTEGER AS $$
	BEGIN
	    UPDATE dns.view SET gendhcp = 1
		FROM dns.rr
		    WHERE rr.idrr = $1
			AND rr.mac IS NOT NULL
			AND view.idview = $2 ;
	    RETURN 1 ;
	END ;
	$$ LANGUAGE 'plpgsql' ;

    CREATE OR REPLACE FUNCTION modifier_ip ()
	RETURNS trigger AS $$
	BEGIN
	    IF TG_OP = 'INSERT'
	    THEN
		PERFORM sum (gen_rev4 (NEW.adr, NEW.idview)) ;
		PERFORM sum (gen_rev6 (NEW.adr, NEW.idview)) ;
		PERFORM sum (gen_norm_idrr (NEW.idrr, NEW.idview)) ;
		PERFORM sum (gen_dhcp (NEW.idrr, NEW.idview)) ;

	    END IF ;

	    IF TG_OP = 'UPDATE'
	    THEN
		PERFORM sum (gen_rev4 (NEW.adr, NEW.idview)) ;
		PERFORM sum (gen_rev4 (OLD.adr, OLD.idview)) ;
		PERFORM sum (gen_rev6 (NEW.adr, NEW.idview)) ;
		PERFORM sum (gen_rev6 (OLD.adr, OLD.idview)) ;
		PERFORM sum (gen_norm_idrr (NEW.idrr, NEW.idview)) ;
		PERFORM sum (gen_norm_idrr (OLD.idrr, OLD.idview)) ;
		PERFORM sum (gen_dhcp (NEW.idrr, NEW.idview)) ;
		PERFORM sum (gen_dhcp (OLD.idrr, OLD.idview)) ;
	    END IF ;

	    IF TG_OP = 'DELETE'
	    THEN
		PERFORM sum (gen_rev4 (OLD.adr, OLD.idview)) ;
		PERFORM sum (gen_rev6 (OLD.adr, OLD.idview)) ;
		PERFORM sum (gen_norm_idrr (OLD.idrr, OLD.idview)) ;
		PERFORM sum (gen_dhcp (OLD.idrr, OLD.idview)) ;
	    END IF ;

	    RETURN NEW ;
	END ;
	$$ LANGUAGE 'plpgsql' ;

    CREATE OR REPLACE FUNCTION modifier_mxcname ()
	RETURNS trigger AS $$
	BEGIN
	    IF TG_OP = 'INSERT'
	    THEN
		PERFORM sum (gen_norm_idrr (NEW.idrr, NEW.idview)) ;
	    END IF ;

	    IF TG_OP = 'UPDATE'
	    THEN
		PERFORM sum (gen_norm_idrr (NEW.idrr, NEW.idview)) ;
		PERFORM sum (gen_norm_idrr (OLD.idrr, OLD.idview)) ;
	    END IF ;

	    IF TG_OP = 'DELETE'
	    THEN
		PERFORM sum (gen_norm_idrr (OLD.idrr, OLD.idview)) ;
	    END IF ;

	    RETURN NEW ;
	END ;
	$$ LANGUAGE 'plpgsql' ;

    -- modify RR and reverse zones for all IP addresses
    CREATE OR REPLACE FUNCTION modifier_rr ()
	RETURNS trigger AS $$
	BEGIN
	    IF TG_OP = 'INSERT'
	    THEN
		PERFORM sum (gen_norm_iddom (NEW.iddom, idview))
			FROM dns.rr_ip WHERE idrr = NEW.idrr ;
		PERFORM sum (gen_rev4 (adr, idview))
			FROM dns.rr_ip WHERE idrr = NEW.idrr ;
		PERFORM sum (gen_rev6 (adr, idview))
			FROM dns.rr_ip WHERE idrr = NEW.idrr ;
		PERFORM sum (gen_dhcp (idrr, idview))
			FROM dns.rr_ip WHERE idrr = NEW.idrr ;

	    END IF ;

	    IF TG_OP = 'UPDATE'
	    THEN
		PERFORM sum (gen_norm_iddom (NEW.iddom, idview))
			FROM dns.rr_ip WHERE idrr = NEW.idrr ;
		PERFORM sum (gen_rev4 (adr, idview))
			FROM dns.rr_ip WHERE idrr = NEW.idrr ;
		PERFORM sum (gen_rev6 (adr, idview))
			FROM dns.rr_ip WHERE idrr = NEW.idrr ;
		PERFORM sum (gen_norm_iddom (OLD.iddom, idview))
			FROM dns.rr_ip WHERE idrr = OLD.idrr ;
		PERFORM sum (gen_rev4 (adr, idview))
			FROM dns.rr_ip WHERE idrr = OLD.idrr ;
		PERFORM sum (gen_rev6 (adr, idview))
			FROM dns.rr_ip WHERE idrr = OLD.idrr ;

		-- rr_ip (giving idview) are the same for OLD and NEW
		PERFORM sum (gen_dhcp (idrr, idview))
			FROM dns.rr_ip WHERE idrr = NEW.idrr ;
	    END IF ;

	    IF TG_OP = 'DELETE'
	    THEN
		PERFORM sum (gen_norm_iddom (OLD.iddom, idview))
			FROM dns.rr_ip WHERE idrr = OLD.idrr ;
		PERFORM sum (gen_rev4 (adr, idview))
			FROM dns.rr_ip WHERE idrr = OLD.idrr ;
		PERFORM sum (gen_rev6 (adr, idview))
			FROM dns.rr_ip WHERE idrr = OLD.idrr ;

		-- no need to modify the dns.view.gendhcp column
		-- since all rr_ip should have been removed before
	    END IF ;

	    RETURN NEW ;
	END ;
	$$ LANGUAGE 'plpgsql' ;

    -- called when a mail relay is modified ($1=iddom, $2=idview)
    CREATE OR REPLACE FUNCTION gen_relais (INTEGER, INTEGER)
	RETURNS INTEGER AS $$
	BEGIN
	    UPDATE dns.zone_normale SET generer = 1
		WHERE idview = $2
		    AND selection =
			(SELECT nom FROM dns.domaine WHERE iddom = $1) ;
	    RETURN 1 ;
	END ;
	$$ LANGUAGE 'plpgsql' ;

    CREATE OR REPLACE FUNCTION modifier_relais ()
	RETURNS trigger AS $$
	BEGIN
	    IF TG_OP = 'INSERT'
	    THEN
		PERFORM sum (gen_relais (NEW.iddom, NEW.idview)) ;
	    END IF ;

	    IF TG_OP = 'UPDATE'
	    THEN
		PERFORM sum (gen_relais (NEW.iddom, NEW.idview)) ;
		PERFORM sum (gen_relais (OLD.iddom, OLD.idview)) ;
	    END IF ;

	    IF TG_OP = 'DELETE'
	    THEN
		PERFORM sum (gen_relais (OLD.iddom, OLD.idview)) ;
	    END IF ;

	    RETURN NEW ;
	END ;
	$$ LANGUAGE 'plpgsql' ;

    -- called when a DHCP parameter (network, range or profile) is modified
    -- update all views
    CREATE OR REPLACE FUNCTION generer_dhcp ()
	RETURNS TRIGGER AS $$
	BEGIN
	    UPDATE dns.view SET gendhcp = 1 ;
	    RETURN NEW ;
	END ;
	$$ LANGUAGE 'plpgsql' ;


-- Add views

CREATE SEQUENCE dns.seq_view START 1 ;
CREATE TABLE dns.view (
    idview	INT		-- view id
	    DEFAULT NEXTVAL ('dns.seq_view'),
    name	TEXT,		-- e.g.: "internal", "external"...
    gendhcp	INT,		-- 1 if dhcp conf must be generated

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

ALTER TABLE dns.zone
    DROP CONSTRAINT zone_pkey ;

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

-- temporarily remove trigger since it may take a looooong time
DROP TRIGGER tr_modifier_ip ON dns.rr_ip ;
UPDATE dns.rr_ip
    SET idview = (SELECT idview FROM dns.view WHERE name = 'default') ;
CREATE TRIGGER tr_modifier_ip
    AFTER INSERT OR UPDATE OR DELETE
    ON dns.rr_ip
    FOR EACH ROW
    EXECUTE PROCEDURE modifier_ip ()
    ;

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
