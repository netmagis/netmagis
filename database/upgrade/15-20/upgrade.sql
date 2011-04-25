------------------------------------------------------------------------------
-- Database upgrade to 2.0 version
--
-- Use:
--	- psql -f upgrade.sql dns
--
------------------------------------------------------------------------------

CREATE USER detecteq ;
-- ALTER USER detecteq UNENCRYPTED PASSWORD 'XXXXXX' ;

------------------------------------------------------------------------------
-- new schemas
------------------------------------------------------------------------------

CREATE SCHEMA global ;
CREATE SCHEMA dns ;
CREATE SCHEMA topo ;
CREATE SCHEMA pgauth ;

GRANT USAGE  ON SCHEMA global, dns, topo, pgauth TO pda, jean, dns ;
GRANT USAGE  ON SCHEMA         dns, topo         TO                 detecteq ;
GRANT CREATE ON SCHEMA global, dns, topo, pgauth TO pda, jean ;

ALTER TABLE config  SET SCHEMA global ;
ALTER TABLE corresp SET SCHEMA global ;
ALTER TABLE groupe  SET SCHEMA global ;
ALTER TABLE log     SET SCHEMA global ;

ALTER TABLE communaute    SET SCHEMA dns ;
ALTER TABLE dhcp          SET SCHEMA dns ;
ALTER TABLE dhcpprofil    SET SCHEMA dns ;
ALTER TABLE dhcprange     SET SCHEMA dns ;
ALTER TABLE domaine       SET SCHEMA dns ;
ALTER TABLE dr_dhcpprofil SET SCHEMA dns ;
ALTER TABLE dr_dom        SET SCHEMA dns ;
ALTER TABLE dr_ip         SET SCHEMA dns ;
ALTER TABLE dr_mbox       SET SCHEMA dns ;
ALTER TABLE dr_reseau     SET SCHEMA dns ;
ALTER TABLE etablissement SET SCHEMA dns ;
ALTER TABLE hinfo         SET SCHEMA dns ;
ALTER TABLE relais_dom    SET SCHEMA dns ;
ALTER TABLE reseau        SET SCHEMA dns ;
ALTER TABLE role_mail     SET SCHEMA dns ;
ALTER TABLE role_web      SET SCHEMA dns ;
ALTER TABLE rr            SET SCHEMA dns ;
ALTER TABLE rr_cname      SET SCHEMA dns ;
ALTER TABLE rr_ip         SET SCHEMA dns ;
ALTER TABLE rr_mx         SET SCHEMA dns ;
ALTER TABLE zone          SET SCHEMA dns ;
ALTER TABLE zone_normale  SET SCHEMA dns ;
ALTER TABLE zone_reverse4 SET SCHEMA dns ;
ALTER TABLE zone_reverse6 SET SCHEMA dns ;

ALTER SEQUENCE seq_communaute    SET SCHEMA dns ;
ALTER SEQUENCE seq_corresp       SET SCHEMA dns ;
ALTER SEQUENCE seq_dhcpprofil    SET SCHEMA dns ;
ALTER SEQUENCE seq_dhcprange     SET SCHEMA dns ;
ALTER SEQUENCE seq_domaine       SET SCHEMA dns ;
ALTER SEQUENCE seq_etablissement SET SCHEMA dns ;
ALTER SEQUENCE seq_groupe        SET SCHEMA dns ;
ALTER SEQUENCE seq_hinfo         SET SCHEMA dns ;
ALTER SEQUENCE seq_reseau        SET SCHEMA dns ;
ALTER SEQUENCE seq_rr            SET SCHEMA dns ;
ALTER SEQUENCE seq_zone          SET SCHEMA dns ;

------------------------------------------------------------------------------
-- Schema
------------------------------------------------------------------------------

GRANT SELECT ON dns.rr, dns.rr_ip, dns.domaine TO detecteq ;

------------------------------------------------------------------------------
-- Group permission to access the MAC module
------------------------------------------------------------------------------

ALTER TABLE global.groupe
    ADD COLUMN droitmac INT DEFAULT 0
    ;

UPDATE global.groupe SET droitmac = 0 ;

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
) ;

CREATE INDEX modeq_index ON topo.modeq (eq) ;

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
	FOREIGN KEY (idrr) REFERENCES dns.rr (idrr),
	PRIMARY KEY (idrr, reqdate, iface)
) ;

------------------------------------------------------------------------------
-- Last rancid run
------------------------------------------------------------------------------

CREATE TABLE topo.lastrun (
	date		TIMESTAMP (0)	-- detection date
			    WITHOUT TIME ZONE
) ;

-- insert an empty value to bootstrap the full rancid run
INSERT INTO topo.lastrun (date) VALUES (NULL) ;

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
-- Access rights to equipements
------------------------------------------------------------------------------

CREATE TABLE topo.dr_eq (
    idgrp	INT,		-- group upon which this access right applies
    rw		INT,		-- 0 : read, 1 : write
    pattern	TEXT NOT NULL,	-- regular expression
    allow_deny	INT,		-- 1 = allow, 0 = deny

    FOREIGN KEY (idgrp) REFERENCES global.groupe (idgrp)
) ;

------------------------------------------------------------------------------
-- Sensor definition
------------------------------------------------------------------------------

-- type trafic
--	iface = iface[.vlan]
--	param = NULL
-- type number of assoc wifi
--	iface = iface
--	ssid
-- type number of auth wifi
--	iface = iface
--	param = ssid
-- type broadcast traffic
--	iface = iface[.vlan]
--	param = NULL
-- type multicast traffic
--	iface = iface[.vlan]
--	param = NULL

CREATE TABLE topo.sensor (
    id		TEXT,		-- M1234
    type	TEXT,		-- trafic, nbassocwifi, nbauthwifi, etc.
    eq		TEXT,		-- fqdn
    comm	TEXT,		-- snmp communuity
    iface	TEXT,
    param	TEXT,
    lastmod	TIMESTAMP (0)	-- last modification date
		    WITHOUT TIME ZONE
		    DEFAULT CURRENT_TIMESTAMP,
    lastseen	TIMESTAMP (0)	-- last detection date
		    WITHOUT TIME ZONE
		    DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id)
) ;


------------------------------------------------------------------------------
-- Topod file monitor
------------------------------------------------------------------------------

CREATE TABLE topo.filemonitor (
	path	TEXT,		-- path to file or directory
	date	TIMESTAMP (0)	-- last modification date
			    WITHOUT TIME ZONE
			    DEFAULT CURRENT_TIMESTAMP,

	PRIMARY KEY (path)
) ;

------------------------------------------------------------------------------
-- Topo programs result cache
------------------------------------------------------------------------------

CREATE TABLE topo.cache (
	key	    TEXT,		-- hash key
	command	    TEXT,		-- command called with arguments
	file	    TEXT,		-- file containing cached command output
	hit	    INTEGER,		-- number of calls for this entry
	runtime	    INTEGER,		-- time taken for last command execution
	lastread    TIMESTAMP		-- last time the entry was read
		    WITHOUT TIME ZONE,
	lastrun	    TIMESTAMP		-- last time the entry was written
		    WITHOUT TIME ZONE,
	PRIMARY KEY (key)
) ;

------------------------------------------------------------------------------
-- Vlan table
------------------------------------------------------------------------------

CREATE TABLE topo.vlan (
	vlanid	INT,		-- 1..4095
	descr	TEXT,		-- description
	voip	INT DEFAULT 0,	-- 1 if VoIP vlan, 0 if standard vlan

	PRIMARY KEY (vlanid)
) ;

COPY topo.vlan (vlanid, descr) FROM stdin;
1	default
\.

CREATE OR REPLACE FUNCTION modif_vlan () RETURNS trigger AS $$
    BEGIN
	INSERT INTO topo.modeq (eq) VALUES ('_vlan') ;
	RETURN NEW ;
    END ;
    $$ LANGUAGE 'plpgsql' ;

CREATE TRIGGER tr_mod_vlan
    AFTER INSERT OR UPDATE OR DELETE
    ON topo.vlan
    FOR EACH ROW
    EXECUTE PROCEDURE modif_vlan () ;

------------------------------------------------------------------------------
-- Equipment types and equipment list to create rancid router.db file
------------------------------------------------------------------------------

CREATE SEQUENCE topo.seq_eqtype START 1 ;

CREATE TABLE topo.eqtype (
    idtype	INTEGER		-- type id
	DEFAULT NEXTVAL ('topo.seq_eqtype'),
    type	TEXT,		-- cisco, hp, juniper, etc.

    UNIQUE (type),
    PRIMARY KEY (idtype)
) ;

CREATE SEQUENCE topo.seq_eq START 1 ;

CREATE TABLE topo.eq (
    ideq	INTEGER		-- equipment id
	DEFAULT NEXTVAL ('topo.seq_eq'),
    eq		TEXT,		-- fqdn
    idtype	INTEGER,
    up		INTEGER,	-- 1 : up, 0 : 0

    FOREIGN KEY (idtype) REFERENCES topo.eqtype (idtype),
    UNIQUE (eq),
    PRIMARY KEY (ideq)
) ;

COPY topo.eqtype (type) FROM stdin;
cisco
juniper
hp
\.

CREATE OR REPLACE FUNCTION modif_routerdb () RETURNS trigger AS $$
    BEGIN
	INSERT INTO topo.modeq (eq) VALUES ('_routerdb') ;
	RETURN NEW ;
    END ;
    $$ LANGUAGE 'plpgsql' ;

CREATE TRIGGER tr_mod_eq
    AFTER INSERT OR UPDATE OR DELETE
    ON topo.eq
    FOR EACH ROW
    EXECUTE PROCEDURE modif_routerdb () ;

------------------------------------------------------------------------------
-- pgauth tables
------------------------------------------------------------------------------

CREATE TABLE pgauth.user (
    login	TEXT,		-- login name
    password	TEXT,		-- crypted password
    nom		TEXT,		-- name
    prenom	TEXT,		-- first name
    mel		TEXT,		-- mail
    tel		TEXT,		-- phone number
    mobile	TEXT,		-- mobile phone number
    fax		TEXT,		-- facsimile number
    adr		TEXT,		-- address

    -- fields managed by a trigger function
    phnom	TEXT,		-- phonetical name
    phprenom	TEXT,		-- phonetical first name

    PRIMARY KEY (login)
) ;

CREATE TABLE pgauth.realm (
    realm	TEXT,		-- realm name
    descr	TEXT,		-- description
    admin	INT DEFAULT 0,	-- 1 if admin

    PRIMARY KEY (realm)
) ;

CREATE TABLE pgauth.member (
    login	TEXT,		-- login name
    realm	TEXT,		-- realm for this user

    FOREIGN KEY (login) REFERENCES pgauth.user (login),
    FOREIGN KEY (realm) REFERENCES pgauth.realm (realm),
    PRIMARY KEY (login, realm)
) ;

------------------------------------------------------------------------------
-- Authorizations
------------------------------------------------------------------------------

GRANT SELECT ON topo.ignoreequsers, dns.rr, dns.rr_ip, dns.domaine TO detecteq ;
GRANT INSERT ON topo.modeq TO detecteq ;

GRANT ALL
    ON topo.modeq, topo.ifchanges, topo.lastrun, topo.keepstate, topo.dr_eq,
	topo.sensor, topo.filemonitor, topo.cache, topo.vlan,
	topo.seq_eqtype, topo.seq_eq, topo.eqtype, topo.eq
	pgauth.user, pgauth.realm, pgauth.member
    TO dns, pda, jean ;

------------------------------------------------------------------------------
-- New configuration values
------------------------------------------------------------------------------

COPY global.config (clef, valeur) FROM stdin;
topoactive	0
topofrom	nobody.topo@unistra.fr
topoto	di-infra-expl-res@unistra.fr pda@unistra.fr
topographddelay	5
toposendddelay	5
topomaxstatus	100
sensorexpire	30
dhcpdefdomain	mycompany.com
dhcpdefdnslist	1.2.3.4,5.6.7.8
modeqexpire	30
ifchangeexpire	30
fullrancidmin	2
fullrancidmax	4
\.

------------------------------------------------------------------------------
-- Adapt functions to new schemas
------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION markcidr (reseau CIDR, lim INTEGER, grp INTEGER)
    RETURNS void AS $$
    DECLARE
	min INET ;
	max INET ;
	a INET ;
    BEGIN
	min := INET (HOST (reseau)) ;
	max := INET (HOST (BROADCAST (reseau))) ;

	IF max - min - 2 > lim THEN
	    RAISE EXCEPTION 'Too many addresses' ;
	END IF ;

	-- All this exception machinery is here since we can't use :
	--    DROP TABLE IF EXISTS allip ;
	-- It raises a notice exception, which prevents
	-- script "ajout" to function
	BEGIN
	    DROP TABLE allip ;
	EXCEPTION
	    WHEN OTHERS THEN -- nothing
	END ;

	CREATE TEMPORARY TABLE allip (
	    adr INET,
	    avail INTEGER,
		-- 0 : unavailable (broadcast addr, no right on addr, etc.)
		-- 1 : not declared and not in a dhcp range
		-- 2 : declared and not in a dhcp range
		-- 3 : not declared and in a dhcp range
		-- 4 : declared and in a dhcp range
	    fqdn TEXT			-- if 2 or 4, then fqdn else NULL
	) ;

	a := min ; 
	WHILE a <= max LOOP
	    INSERT INTO allip VALUES (a, 1) ;
	    a := a + 1 ;
	END LOOP ;

	UPDATE allip
	    SET fqdn = rr.nom || '.' || domaine.nom,
		avail = 2
	    FROM dns.rr_ip, dns.rr, dns.domaine
	    WHERE allip.adr = rr_ip.adr
		AND rr_ip.idrr = rr.idrr
		AND rr.iddom = domaine.iddom
		;

	UPDATE allip
	    SET avail = CASE
			    WHEN avail = 1 THEN 3
			    WHEN avail = 2 THEN 4
			END
	    FROM dns.dhcprange
	    WHERE (avail = 1 OR avail = 2)
		AND adr >= dhcprange.min
		AND adr <= dhcprange.max
	    ;

	UPDATE allip SET avail = 0
	    WHERE adr = min OR adr = max OR NOT valide_ip_grp (adr, grp) ;

	RETURN ;

    END ;
    $$ LANGUAGE plpgsql ;

CREATE OR REPLACE FUNCTION gen_rev4 (INET)
    RETURNS INTEGER AS $$
    BEGIN
	UPDATE dns.zone_reverse4 SET generer = 1 WHERE $1 <<= selection ;
	RETURN 1 ;
    END ;
    $$ LANGUAGE 'plpgsql' ;

-- appelé lors de la modification d'une adresse IPv6
CREATE OR REPLACE FUNCTION gen_rev6 (INET)
    RETURNS INTEGER AS $$
    BEGIN
	UPDATE dns.zone_reverse6 SET generer = 1 WHERE $1 <<= selection ;
	RETURN 1 ;
    END ;
    $$ LANGUAGE 'plpgsql' ;

-- ID du RR
CREATE OR REPLACE FUNCTION gen_norm_idrr (INTEGER)
    RETURNS INTEGER AS $$
    BEGIN
	UPDATE dns.zone_normale SET generer = 1
		WHERE selection = (
			SELECT domaine.nom
				FROM dns.domaine, dns.rr
				WHERE rr.idrr = $1 AND rr.iddom = domaine.iddom
			) ;
	RETURN 1 ;
    END ;
    $$ LANGUAGE 'plpgsql' ;

CREATE OR REPLACE FUNCTION gen_norm_iddom (INTEGER)
    RETURNS INTEGER AS $$
    BEGIN
	UPDATE dns.zone_normale SET generer = 1
		WHERE selection = (
			SELECT domaine.nom
				FROM dns.domaine
				WHERE domaine.iddom = $1
			) ;
	RETURN 1 ;
    END ;
    $$ LANGUAGE 'plpgsql' ;

CREATE OR REPLACE FUNCTION modifier_ip ()
    RETURNS trigger AS $$
    BEGIN
	IF TG_OP = 'INSERT'
	THEN
	    PERFORM sum (gen_rev4 (NEW.adr)) ;
	    PERFORM sum (gen_rev6 (NEW.adr)) ;
	    PERFORM sum (gen_norm_idrr (NEW.idrr)) ;

	    UPDATE dns.dhcp SET generer = 1
		FROM dns.rr WHERE rr.idrr = NEW.idrr AND rr.mac IS NOT NULL ;

	    UPDATE dns.dhcp SET generer = 1
		FROM dns.rr WHERE rr.idrr = NEW.idrr AND rr.mac IS NOT NULL ;
	END IF ;

	IF TG_OP = 'UPDATE'
	THEN
	    PERFORM sum (gen_rev4 (NEW.adr)) ;
	    PERFORM sum (gen_rev4 (OLD.adr)) ;
	    PERFORM sum (gen_rev6 (NEW.adr)) ;
	    PERFORM sum (gen_rev6 (OLD.adr)) ;
	    PERFORM sum (gen_norm_idrr (NEW.idrr)) ;
	    PERFORM sum (gen_norm_idrr (OLD.idrr)) ;

	    UPDATE dns.dhcp SET generer = 1
		FROM dns.rr WHERE rr.idrr = OLD.idrr AND rr.mac IS NOT NULL ;
	    UPDATE dns.dhcp SET generer = 1
		FROM dns.rr WHERE rr.idrr = NEW.idrr AND rr.mac IS NOT NULL ;
	END IF ;

	IF TG_OP = 'DELETE'
	THEN
	    PERFORM sum (gen_rev4 (OLD.adr)) ;
	    PERFORM sum (gen_rev6 (OLD.adr)) ;
	    PERFORM sum (gen_norm_idrr (OLD.idrr)) ;

	    UPDATE dns.dhcp SET generer = 1
		FROM dns.rr WHERE rr.idrr = OLD.idrr AND rr.mac IS NOT NULL ;
	END IF ;

	RETURN NEW ;
    END ;
    $$ LANGUAGE 'plpgsql' ;

CREATE OR REPLACE FUNCTION modifier_mxcname ()
    RETURNS trigger AS $$
    BEGIN
	IF TG_OP = 'INSERT'
	THEN
	    PERFORM sum (gen_norm_idrr (NEW.idrr)) ;
	END IF ;

	IF TG_OP = 'UPDATE'
	THEN
	    PERFORM sum (gen_norm_idrr (NEW.idrr)) ;
	    PERFORM sum (gen_norm_idrr (OLD.idrr)) ;
	END IF ;

	IF TG_OP = 'DELETE'
	THEN
	    PERFORM sum (gen_norm_idrr (OLD.idrr)) ;
	END IF ;

	RETURN NEW ;
    END ;
    $$ LANGUAGE 'plpgsql' ;

-- modifier le RR et les zones reverses pour toutes les adresses IP
CREATE OR REPLACE FUNCTION modifier_rr ()
    RETURNS trigger AS $$
    BEGIN
	IF TG_OP = 'INSERT'
	THEN
	    PERFORM sum (gen_norm_iddom (NEW.iddom)) ;
	    PERFORM sum (gen_rev4 (adr)) FROM dns.rr_ip WHERE idrr = NEW.idrr ;
	    PERFORM sum (gen_rev6 (adr)) FROM dns.rr_ip WHERE idrr = NEW.idrr ;

	    IF NEW.mac IS NOT NULL
	    THEN
		UPDATE dns.dhcp SET generer = 1 ;
	    END IF ;
	END IF ;

	IF TG_OP = 'UPDATE'
	THEN
	    PERFORM sum (gen_norm_iddom (NEW.iddom)) ;
	    PERFORM sum (gen_rev4 (adr)) FROM dns.rr_ip WHERE idrr = NEW.idrr ;
	    PERFORM sum (gen_rev6 (adr)) FROM dns.rr_ip WHERE idrr = NEW.idrr ;
	    PERFORM sum (gen_norm_iddom (OLD.iddom)) ;
	    PERFORM sum (gen_rev4 (adr)) FROM dns.rr_ip WHERE idrr = OLD.idrr ;
	    PERFORM sum (gen_rev6 (adr)) FROM dns.rr_ip WHERE idrr = OLD.idrr ;

	    IF OLD.mac IS DISTINCT FROM NEW.mac
		OR OLD.iddhcpprofil IS DISTINCT FROM NEW.iddhcpprofil
	    THEN
		UPDATE dns.dhcp SET generer = 1 ;
	    END IF ;
	END IF ;

	IF TG_OP = 'DELETE'
	THEN
	    PERFORM sum (gen_norm_iddom (OLD.iddom)) ;
	    PERFORM sum (gen_rev4 (adr)) FROM dns.rr_ip WHERE idrr = OLD.idrr ;
	    PERFORM sum (gen_rev6 (adr)) FROM dns.rr_ip WHERE idrr = OLD.idrr ;

	    IF OLD.mac IS NOT NULL
	    THEN
		UPDATE dns.dhcp SET generer = 1 ;
	    END IF ;
	END IF ;

	RETURN NEW ;
    END ;
    $$ LANGUAGE 'plpgsql' ;

CREATE OR REPLACE FUNCTION gen_relais (INTEGER)
    RETURNS INTEGER AS $$
    BEGIN
	UPDATE dns.zone_normale SET generer = 1
	    WHERE selection = (SELECT nom FROM dns.domaine WHERE iddom = $1) ;
	RETURN 1 ;
    END ;
    $$ LANGUAGE 'plpgsql' ;

CREATE OR REPLACE FUNCTION generer_dhcp ()
    RETURNS TRIGGER AS $$
    BEGIN
	UPDATE dns.dhcp SET generer = 1 ;
	RETURN NEW ;
    END ;
    $$ LANGUAGE 'plpgsql' ;

CREATE OR REPLACE FUNCTION valide_ip_cor (INET, INTEGER)
    RETURNS BOOLEAN AS $$
    BEGIN
	RETURN valide_ip_grp ($1, idgrp) FROM global.corresp WHERE idcor = $2 ;
    END ;
    $$ LANGUAGE 'plpgsql' ;

-- arg 1: address to test
-- arg 2: group id
CREATE OR REPLACE FUNCTION valide_ip_grp (INET, INTEGER)
    RETURNS BOOLEAN AS $$
    BEGIN
	RETURN ($1 <<= ANY (SELECT adr FROM dns.dr_ip
				WHERE allow_deny = 1 AND idgrp = $2)
	    AND NOT $1 <<= ANY (SELECT adr FROM dns.dr_ip
				WHERE allow_deny = 0 AND idgrp = $2)
	    ) ;
    END ;
    $$ LANGUAGE 'plpgsql' ;

\encoding latin9
CREATE FUNCTION soundex (TEXT) RETURNS TEXT AS '
	array set soundexFrenchCode {
	    a 0 b 1 c 2 d 3 e 0 f 9 g 7 h 0 i 0 j 7 k 2 l 4 m 5
	    n 5 o 0 p 1 q 2 r 6 s 8 t 3 u 0 v 9 w 9 x 8 y 0 z 8
	}
	set accentedFrenchMap {
	    é e  ë e  ê e  è e   É E  Ë E  Ê E  È E
	     ä a  â a  à a        Ä A  Â A  À A
	     ï i  î i             Ï I  Î I
	     ö o  ô o             Ö O  Ô O
	     ü u  û u  ù u        Ü U  Û U  Ù U
	     ç ss                 Ç SS
	}
	set key ""

	# Map accented characters
	set TempIn [string map $accentedFrenchMap $1]

	# Only use alphabetic characters, so strip out all others
	# also, soundex index uses only lower case chars, so force to lower

	regsub -all {[^a-z]} [string tolower $TempIn] {} TempIn
	if {[string length $TempIn] == 0} {
	    return Z000
	}
	set last [string index $TempIn 0]
	set key  [string toupper $last]
	set last $soundexFrenchCode($last)

	# Scan rest of string, stop at end of string or when the key is
	# full

	set count    1
	set MaxIndex [string length $TempIn]

	for {set index 1} {(($count < 4) && ($index < $MaxIndex))} {incr index } {
	    set chcode $soundexFrenchCode([string index $TempIn $index])
	    # Fold together adjacent letters sharing the same code
	    if {![string equal $last $chcode]} {
		set last $chcode
		# Ignore code==0 letters except as separators
		if {$last != 0} then {
		    set key $key$last
		    incr count
		}
	    }
	}
	return [string range ${key}0000 0 3]
    ' LANGUAGE 'pltcl' WITH (isStrict) ;

CREATE FUNCTION add_soundex () RETURNS TRIGGER AS '
    BEGIN
	NEW.phnom    := SOUNDEX (NEW.nom) ;
	NEW.phprenom := SOUNDEX (NEW.prenom) ;
	RETURN NEW ;
    END ;
    ' LANGUAGE 'plpgsql' ;

CREATE TRIGGER phnom
    BEFORE INSERT OR UPDATE
    ON pgauth.user
    FOR EACH ROW
    EXECUTE PROCEDURE add_soundex ()
    ;

-- do not forget to upgrade the zone generation script on the DNS server
update dns.zone_normale  set prologue=replace(prologue, '%VERSION%', '%ZONEVERSION%') ;
update dns.zone_reverse4 set prologue=replace(prologue, '%VERSION%', '%ZONEVERSION%') ;
update dns.zone_reverse6 set prologue=replace(prologue, '%VERSION%', '%ZONEVERSION%') ;
