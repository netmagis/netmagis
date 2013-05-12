------------------------------------------------------------------------------
-- Database upgrade to 2.2 version
--
-- Use:
--	- psql -f upgrade.sql database-name
--
------------------------------------------------------------------------------


------------------------------------------------------------------------------
-- Remove triggers in order to quietly make changes on tables
------------------------------------------------------------------------------

DROP TRIGGER IF EXISTS tr_modifier_cname ON dns.rr_cname	CASCADE ;
DROP TRIGGER IF EXISTS tr_modifier_dhcpprofil ON dns.dhcpprofil	CASCADE ;
DROP TRIGGER IF EXISTS tr_modifier_dhcprange ON dns.dhcprange	CASCADE ;
DROP TRIGGER IF EXISTS tr_modifier_ip ON dns.rr_ip		CASCADE ;
DROP TRIGGER IF EXISTS tr_modifier_mx ON dns.rr_mx		CASCADE ;
DROP TRIGGER IF EXISTS tr_modifier_relais ON dns.relais_dom	CASCADE ;
DROP TRIGGER IF EXISTS tr_modifier_reseau ON dns.reseau		CASCADE ;
DROP TRIGGER IF EXISTS tr_modifier_rr ON dns.rr			CASCADE ;
DROP TRIGGER IF EXISTS tr_modifier_zone ON dns.zone_normale	CASCADE ;
DROP TRIGGER IF EXISTS tr_modifier_zone4 ON dns.zone_reverse4	CASCADE ;
DROP TRIGGER IF EXISTS tr_modifier_zone6 ON dns.zone_reverse6	CASCADE ;
DROP TRIGGER IF EXISTS phnom ON pgauth."user"			CASCADE ;
DROP TRIGGER IF EXISTS tr_mod_eq ON topo.eq			CASCADE ;
DROP TRIGGER IF EXISTS tr_mod_vlan ON topo.vlan			CASCADE ;

DROP FUNCTION IF EXISTS add_soundex ()				CASCADE ;
DROP FUNCTION IF EXISTS pgauth.add_soundex ()			CASCADE ;
DROP FUNCTION IF EXISTS soundex (TEXT)				CASCADE ;
DROP FUNCTION IF EXISTS pgauth.soundex (TEXT)			CASCADE ;
DROP FUNCTION IF EXISTS gen_dhcp (INTEGER, INTEGER)		CASCADE ;
DROP FUNCTION IF EXISTS gen_norm_iddom (INTEGER)		CASCADE ;
DROP FUNCTION IF EXISTS gen_norm_iddom (INTEGER, INTEGER)	CASCADE ;
DROP FUNCTION IF EXISTS gen_norm_idrr (INTEGER)			CASCADE ;
DROP FUNCTION IF EXISTS gen_norm_idrr (INTEGER, INTEGER)	CASCADE ;
DROP FUNCTION IF EXISTS gen_relais (INTEGER)			CASCADE ;
DROP FUNCTION IF EXISTS gen_relais (INTEGER, INTEGER)		CASCADE ;
DROP FUNCTION IF EXISTS gen_rev4 (INET)				CASCADE ;
DROP FUNCTION IF EXISTS gen_rev4 (INET, INTEGER)		CASCADE ;
DROP FUNCTION IF EXISTS gen_rev6 (INET)				CASCADE ;
DROP FUNCTION IF EXISTS gen_rev6 (INET, INTEGER)		CASCADE ;
DROP FUNCTION IF EXISTS generer_dhcp ()				CASCADE ;
DROP FUNCTION IF EXISTS ipranges (CIDR, INTEGER, INTEGER)	CASCADE ;
DROP FUNCTION IF EXISTS markcidr (CIDR, INTEGER, INTEGER)	CASCADE ;
DROP FUNCTION IF EXISTS modif_routerdb ()			CASCADE ;
DROP FUNCTION IF EXISTS modif_vlan ()				CASCADE ;
DROP FUNCTION IF EXISTS modifier_ip ()				CASCADE ;
DROP FUNCTION IF EXISTS modifier_mxcname ()			CASCADE ;
DROP FUNCTION IF EXISTS modifier_relais ()			CASCADE ;
DROP FUNCTION IF EXISTS modifier_rr ()				CASCADE ;
DROP FUNCTION IF EXISTS modifier_zone ()			CASCADE ;
DROP FUNCTION IF EXISTS valide_dhcprange_grp (INTEGER, INET, INET) CASCADE ;
DROP FUNCTION IF EXISTS valide_ip_cor (INET, INTEGER)		CASCADE ;
DROP FUNCTION IF EXISTS valide_ip_grp (INET, INTEGER)		CASCADE ;

------------------------------------------------------------------------------
-- Schema changes
------------------------------------------------------------------------------

DELETE FROM global.config WHERE clef = 'dnsupdateperiod' ;
INSERT INTO global.config (clef, valeur) VALUES ('schemaversion', '22') ;

DROP TABLE dns.role_web ;

-- Remove all constraints on "to be renamed" tables: we will rebuild them later
-- This is done in order to get new implicit names consistent with table name

ALTER TABLE dns.etablissement
    DROP CONSTRAINT IF EXISTS etablissement_pkey		CASCADE
    ;

ALTER TABLE dns.communaute
    DROP CONSTRAINT IF EXISTS communaute_pkey			CASCADE
    ;

ALTER TABLE dns.dr_dom
    DROP CONSTRAINT IF EXISTS dr_dom_idgrp_fkey			CASCADE,
    DROP CONSTRAINT IF EXISTS dr_dom_pkey			CASCADE
    ;

ALTER TABLE dns.domaine
    DROP CONSTRAINT IF EXISTS domaine_nom_key			CASCADE,
    DROP CONSTRAINT IF EXISTS domaine_pkey			CASCADE
    ;

ALTER TABLE dns.dr_reseau
    DROP CONSTRAINT IF EXISTS dr_reseau_idgrp_fkey		CASCADE,
    DROP CONSTRAINT IF EXISTS dr_reseau_idreseau_fkey		CASCADE,
    DROP CONSTRAINT IF EXISTS dr_reseau_pkey			CASCADE
    ;

ALTER TABLE dns.reseau
    DROP CONSTRAINT IF EXISTS reseau_pkey			CASCADE,
    DROP CONSTRAINT IF EXISTS reseau_idetabl_fkey		CASCADE,
    DROP CONSTRAINT IF EXISTS reseau_idcommu_fkey		CASCADE,
    DROP CONSTRAINT IF EXISTS au_moins_un_prefixe_v4_ou_v6	CASCADE,
    DROP CONSTRAINT IF EXISTS gw4_in_net,
    DROP CONSTRAINT IF EXISTS gw6_in_net
    ;

ALTER TABLE dns.dr_ip
    DROP CONSTRAINT IF EXISTS dr_ip_pkey			CASCADE,
    DROP CONSTRAINT IF EXISTS dr_ip_idgrp_fkey			CASCADE
    ;

ALTER TABLE dns.relais_dom
    DROP CONSTRAINT IF EXISTS relais_dom_pkey			CASCADE,
    DROP CONSTRAINT IF EXISTS relais_dom_iddom_fkey		CASCADE,
    DROP CONSTRAINT IF EXISTS relais_dom_mx_fkey		CASCADE
    ;


-- Rename tables and columns, and rebuild constraints

ALTER TABLE dns.seq_etablissement RENAME TO seq_organization ;

ALTER TABLE dns.etablissement RENAME TO organization ;
ALTER TABLE dns.organization RENAME COLUMN idetabl	TO idorg ;
ALTER TABLE dns.organization RENAME COLUMN nom		TO name ;
ALTER TABLE dns.organization
    ADD PRIMARY KEY (idorg) ;

ALTER TABLE dns.seq_communaute RENAME TO seq_community ;
ALTER TABLE dns.communaute RENAME TO community ;
ALTER TABLE dns.community RENAME COLUMN nom		TO name ;
ALTER TABLE dns.community
    ADD PRIMARY KEY (idcommu) ;

ALTER TABLE dns.dr_dom RENAME TO p_dom ;
ALTER TABLE dns.p_dom RENAME COLUMN tri			TO sort ;
ALTER TABLE dns.p_dom DROP COLUMN roleweb ;
ALTER TABLE dns.p_dom
    ADD FOREIGN KEY (idgrp) REFERENCES global.groupe(idgrp),
    ADD PRIMARY KEY (idgrp, iddom) ;

ALTER TABLE dns.seq_domaine RENAME TO seq_domain ;

ALTER TABLE dns.domaine RENAME TO domain ;
ALTER TABLE dns.domain RENAME COLUMN nom		TO name ;
ALTER TABLE dns.domain
    ADD UNIQUE (name),
    ADD PRIMARY KEY (iddom) ;

ALTER TABLE dns.seq_reseau RENAME TO seq_network ;

ALTER TABLE dns.reseau RENAME TO network ;
ALTER TABLE dns.network RENAME COLUMN idreseau		TO idnet ;
ALTER TABLE dns.network RENAME COLUMN nom		TO name ;
ALTER TABLE dns.network RENAME COLUMN localisation	TO location ;
ALTER TABLE dns.network RENAME COLUMN adr4		TO addr4 ;
ALTER TABLE dns.network RENAME COLUMN adr6		TO addr6 ;
ALTER TABLE dns.network RENAME COLUMN idetabl		TO idorg ;
ALTER TABLE dns.network RENAME COLUMN commentaire	TO comment ;
ALTER TABLE dns.network
    ADD CONSTRAINT at_least_one_prefix_v4_or_v6
		CHECK (addr4 IS NOT NULL OR addr6 IS NOT NULL),
    ADD CONSTRAINT gw4_in_net CHECK (gw4 <<= addr4),
    ADD CONSTRAINT gw6_in_net CHECK (gw6 <<= addr6),
    ADD FOREIGN KEY (idorg) REFERENCES dns.organization (idorg),
    ADD FOREIGN KEY (idcommu) REFERENCES dns.community (idcommu),
    ADD PRIMARY KEY (idnet) ;

ALTER TABLE dns.dr_reseau RENAME TO p_network ;
ALTER TABLE dns.p_network RENAME COLUMN idreseau TO idnet ;
ALTER TABLE dns.p_network RENAME COLUMN tri		TO sort ;
ALTER TABLE dns.p_network
    ADD FOREIGN KEY (idnet) REFERENCES dns.network (idnet),
    ADD FOREIGN KEY (idgrp) REFERENCES global.groupe (idgrp),
    ADD PRIMARY KEY (idgrp, idnet) ;

ALTER TABLE dns.dr_ip RENAME TO p_ip ;
ALTER TABLE dns.p_ip RENAME COLUMN adr			TO addr ;
ALTER TABLE dns.p_ip
    ADD FOREIGN KEY (idgrp) REFERENCES global.groupe (idgrp),
    ADD PRIMARY KEY (idgrp, addr) ;

ALTER TABLE dns.relais_dom RENAME TO relay_dom ;
ALTER TABLE dns.relay_dom RENAME COLUMN priorite	TO prio ;
ALTER TABLE dns.relay_dom
    ADD FOREIGN KEY (iddom)  REFERENCES dns.domain  (iddom),
    ADD FOREIGN KEY (mx)     REFERENCES dns.rr      (idrr),
    ADD PRIMARY KEY (iddom, mx) ;

ALTER TABLE dns.hinfo RENAME COLUMN texte		TO text ;
ALTER TABLE dns.hinfo RENAME COLUMN tri			TO sort ;

ALTER TABLE dns.rr_mx RENAME COLUMN priorite		TO prio ;

DROP TABLE dns.dhcp ;

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

ALTER TABLE dns.zone ADD COLUMN idview INT ;
ALTER TABLE dns.zone RENAME COLUMN domaine		TO name ;
ALTER TABLE dns.zone RENAME COLUMN generer		TO gen ;

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

CREATE TABLE dns.p_view (
    idgrp	INT,		-- group
    idview	INT,		-- the view
    sort	INT,		-- sort class
    selected	INT,		-- selected by default in menus

    FOREIGN KEY (idgrp) REFERENCES global.groupe (idgrp),
    FOREIGN KEY (idview) REFERENCES dns.view (idview),
    PRIMARY KEY (idgrp, idview)
) ;

INSERT INTO dns.p_view (idgrp, idview, sort, selected)
    SELECT idgrp, idview, 100, 1
	    FROM global.groupe, dns.view
	    WHERE view.name = 'default' ;


-- Attach views to RR

ALTER TABLE dns.rr
    DROP CONSTRAINT IF EXISTS rr_nom_key,
    DROP CONSTRAINT IF EXISTS rr_nom_iddom_key,
    DROP CONSTRAINT IF EXISTS rr_mac_key
    ;

ALTER TABLE dns.rr
    ADD COLUMN idview INT ;

UPDATE dns.rr
    SET idview = (SELECT idview FROM dns.view WHERE name = 'default') ;

ALTER TABLE dns.rr
    ADD FOREIGN KEY (idview) REFERENCES dns.view (idview),
    ADD UNIQUE (nom, iddom, idview),
    ADD UNIQUE (mac, idview)
    ;

------------------------------------------------------------------------------
-- Create new functions/triggers for the new version
------------------------------------------------------------------------------

\i %NMLIBDIR%/sql22/functions.sql
\i %NMLIBDIR%/sql22/triggers.sql
