-- $Id$

------------------------------------------------------------------------------
-- changement de type de rr.date : devient une vraie date
------------------------------------------------------------------------------

-- nécessite que le langage pltcl soit chargé dans la base
-- correspondante :
--	createlang pltcl dns


-- création de la fonction de modification
CREATE OR REPLACE FUNCTION int2date (INTEGER)
				RETURNS TIMESTAMP WITHOUT TIME ZONE AS '
	    return [clock format $1]
    ' LANGUAGE 'pltcl' WITH (isStrict) ;

-- ajout du champ
ALTER TABLE rr ADD COLUMN date2 TIMESTAMP WITHOUT TIME ZONE ;

-- suppression temporaire des triggers pour accélérer la mise à jour
DROP TRIGGER tr_modifier_rr ON rr ;

-- mise à jour effective : c'est le moteur qui travaille
UPDATE rr SET date2 = int2date (date) ;

-- nettoyage et renommage
ALTER TABLE rr DROP COLUMN date ;
ALTER TABLE rr RENAME COLUMN date2 TO date ;
DROP FUNCTION int2date (INTEGER) ;

-- valeur par défaut du champ
ALTER TABLE rr ALTER COLUMN date SET DEFAULT CURRENT_TIMESTAMP ;

-- on remet le trigger tel qu'il était initialement
CREATE TRIGGER tr_modifier_rr
    AFTER INSERT OR UPDATE OR DELETE
    ON rr
    FOR EACH ROW
    EXECUTE PROCEDURE modifier_rr ()
    ;

------------------------------------------------------------------------------
-- nouvelle colonne rr.mac associée à un nom
-- simplification : une seule adresse MAC par nom
------------------------------------------------------------------------------

ALTER TABLE rr
    ADD COLUMN mac MACADDR		-- adresse MAC associée au nom, ou NULL
    ;

------------------------------------------------------------------------------
-- Le nécessaire pour le trigger de détection des modifications d'adresse MAC
------------------------------------------------------------------------------

-- une table à une seule ligne pour la configuration globale de DHCP
CREATE TABLE dhcp (
    generer INTEGER			-- 1 s'il faut regénerer la config
) ;

INSERT INTO dhcp (generer) VALUES (0) ;


-- fonction de trigger pour actualiser le booléen
CREATE OR REPLACE FUNCTION modifier_rr () RETURNS trigger AS '
    BEGIN
	IF TG_OP = ''INSERT''
	THEN
	    PERFORM sum (gen_norm_iddom (NEW.iddom)) ;
	    PERFORM sum (gen_rev4 (adr)) FROM rr_ip WHERE idrr = NEW.idrr ;
	    PERFORM sum (gen_rev6 (adr)) FROM rr_ip WHERE idrr = NEW.idrr ;

	    IF NEW.mac IS NOT NULL
	    THEN
		UPDATE dhcp SET generer = 1 ;
	    END IF ;
	END IF ;

	IF TG_OP = ''UPDATE''
	THEN
	    PERFORM sum (gen_norm_iddom (NEW.iddom)) ;
	    PERFORM sum (gen_rev4 (adr)) FROM rr_ip WHERE idrr = NEW.idrr ;
	    PERFORM sum (gen_rev6 (adr)) FROM rr_ip WHERE idrr = NEW.idrr ;
	    PERFORM sum (gen_norm_iddom (OLD.iddom)) ;
	    PERFORM sum (gen_rev4 (adr)) FROM rr_ip WHERE idrr = OLD.idrr ;
	    PERFORM sum (gen_rev6 (adr)) FROM rr_ip WHERE idrr = OLD.idrr ;

	    IF OLD.mac IS DISTINCT FROM NEW.mac
		OR OLD.iddhcpprofil IS DISTINCT FROM NEW.iddhcpprofil
	    THEN
		UPDATE dhcp SET generer = 1 ;
	    END IF ;
	END IF ;

	IF TG_OP = ''DELETE''
	THEN
	    PERFORM sum (gen_norm_iddom (OLD.iddom)) ;
	    PERFORM sum (gen_rev4 (adr)) FROM rr_ip WHERE idrr = OLD.idrr ;
	    PERFORM sum (gen_rev6 (adr)) FROM rr_ip WHERE idrr = OLD.idrr ;

	    IF OLD.mac IS NOT NULL
	    THEN
		UPDATE dhcp SET generer = 1 ;
	    END IF ;
	END IF ;

	RETURN NEW ;
    END ;
    ' LANGUAGE 'plpgsql' ;

-- autre fonction de trigger
CREATE OR REPLACE FUNCTION generer_dhcp () RETURNS trigger AS '
    BEGIN
	UPDATE dhcp SET generer = 1 ;
	RETURN NEW ;
    END ;
    ' LANGUAGE 'plpgsql' ;

-- encore une !
CREATE OR REPLACE FUNCTION modifier_ip () RETURNS trigger AS '
    BEGIN
	IF TG_OP = ''INSERT''
	THEN
	    PERFORM sum (gen_rev4 (NEW.adr)) ;
	    PERFORM sum (gen_rev6 (NEW.adr)) ;
	    PERFORM sum (gen_norm_idrr (NEW.idrr)) ;

	    UPDATE dhcp SET generer = 1
		FROM rr WHERE rr.idrr = NEW.idrr AND rr.mac IS NOT NULL ;

	    UPDATE dhcp SET generer = 1
		FROM rr WHERE rr.idrr = NEW.idrr AND rr.mac IS NOT NULL ;
	END IF ;

	IF TG_OP = ''UPDATE''
	THEN
	    PERFORM sum (gen_rev4 (NEW.adr)) ;
	    PERFORM sum (gen_rev4 (OLD.adr)) ;
	    PERFORM sum (gen_rev6 (NEW.adr)) ;
	    PERFORM sum (gen_rev6 (OLD.adr)) ;
	    PERFORM sum (gen_norm_idrr (NEW.idrr)) ;
	    PERFORM sum (gen_norm_idrr (OLD.idrr)) ;

	    UPDATE dhcp SET generer = 1
		FROM rr WHERE rr.idrr = OLD.idrr AND rr.mac IS NOT NULL ;
	    UPDATE dhcp SET generer = 1
		FROM rr WHERE rr.idrr = NEW.idrr AND rr.mac IS NOT NULL ;
	END IF ;

	IF TG_OP = ''DELETE''
	THEN
	    PERFORM sum (gen_rev4 (OLD.adr)) ;
	    PERFORM sum (gen_rev6 (OLD.adr)) ;
	    PERFORM sum (gen_norm_idrr (OLD.idrr)) ;

	    UPDATE dhcp SET generer = 1
		FROM rr WHERE rr.idrr = OLD.idrr AND rr.mac IS NOT NULL ;
	END IF ;

	RETURN NEW ;
    END ;
    ' LANGUAGE 'plpgsql' ;


ALTER TABLE reseau
    ADD COLUMN dhcp INTEGER		-- activer DHCP (1) ou non (0)
    ;

ALTER TABLE reseau
    ALTER COLUMN dhcp SET DEFAULT 0
    ;

UPDATE reseau SET dhcp = 0 ;

ALTER TABLE reseau
    ADD COLUMN gw4 INET			-- routeur par défaut du réseau
    ;

ALTER TABLE reseau
    ADD CONSTRAINT gw4_in_net CHECK (gw4 <<= adr4)
    ;

ALTER TABLE reseau
    ADD COLUMN gw6 INET			-- pour plus tard, mais soyons homogènes
    ;

ALTER TABLE reseau
    ADD CONSTRAINT gw6_in_net CHECK (gw6 <<= adr6)
    ;

ALTER TABLE reseau
    ADD CONSTRAINT dhcp_needs_ipv4_gateway
    CHECK (dhcp = 0 OR (dhcp != 0 AND gw4 IS NOT NULL));

-- le trigger associé
CREATE TRIGGER tr_modifier_reseau
    AFTER INSERT OR UPDATE OR DELETE
    ON reseau
    FOR EACH ROW
    EXECUTE PROCEDURE generer_dhcp ()
    ;

------------------------------------------------------------------------------
-- Extension des droits associés aux réseaux
------------------------------------------------------------------------------

ALTER TABLE plage
    RENAME TO dr_reseau
    ;

ALTER TABLE dr_reseau
    ADD COLUMN tri INTEGER		-- classe tri pour l'affichage
    ;

ALTER TABLE dr_reseau
    ADD COLUMN dhcp INTEGER		-- accès à la gestion DHCP (dynamique)
    ;

ALTER TABLE dr_reseau
    ADD COLUMN acl INTEGER		-- accès aux ACL
    ;

ALTER TABLE dr_reseau ALTER COLUMN dhcp SET DEFAULT 0 ;
ALTER TABLE dr_reseau ALTER COLUMN acl  SET DEFAULT 0 ;

UPDATE dr_reseau SET tri = 10, dhcp = 0, acl = 0 ;

------------------------------------------------------------------------------
-- Table des intervalles d'adresses dynamiques
------------------------------------------------------------------------------

CREATE SEQUENCE seq_dhcprange START 1 ;
CREATE TABLE dhcprange (
    iddhcprange		INT		-- seulement pour l'édition de tableau
				DEFAULT NEXTVAL ('seq_dhcprange'),
    min 		INET UNIQUE,	-- début de l'intervalle dynamique
    max			INET UNIQUE,	-- fin de l'intervalle dynamique
    iddom		INT,		-- domaine fourni par DHCP
    default_lease_time	INT DEFAULT 0,	-- en secondes
    max_lease_time	INT DEFAULT 0,	-- en secondes

    CHECK (min <= max),
    FOREIGN KEY (iddom) REFERENCES domaine (iddom),
    PRIMARY KEY (iddhcprange)
) ;

-- le trigger associé
CREATE TRIGGER tr_modifier_dhcprange
    AFTER INSERT OR UPDATE OR DELETE
    ON dhcprange
    FOR EACH ROW
    EXECUTE PROCEDURE generer_dhcp ()
    ;

GRANT ALL ON dhcp, seq_dhcprange, dhcprange TO dns ;
GRANT ALL ON dhcp, seq_dhcprange, dhcprange TO pda ;
GRANT ALL ON dhcp, seq_dhcprange, dhcprange TO jean ;


------------------------------------------------------------------------------
-- Table des profils DHCP et des droits associés
------------------------------------------------------------------------------

CREATE SEQUENCE seq_dhcpprofil START 1 ;
CREATE TABLE dhcpprofil (
    iddhcpprofil	INT		-- identifiant du profil DHCP
				DEFAULT NEXTVAL ('seq_dhcpprofil'),
    nom 		TEXT UNIQUE,	-- nom du profil
    texte		TEXT,		-- texte à ajouter avant les hosts

    CHECK (iddhcpprofil >= 1),
    PRIMARY KEY (iddhcpprofil)
) ;

CREATE TABLE dr_dhcpprofil (
    idgrp		INT,		-- identifiant du groupe
    iddhcpprofil	INT,		-- identifiant du profil DHCP
    tri			INT,		-- classe de tri pour les menus

    FOREIGN KEY (idgrp)        REFERENCES groupe     (idgrp),
    FOREIGN KEY (iddhcpprofil) REFERENCES dhcpprofil (iddhcpprofil),
    PRIMARY KEY (idgrp, iddhcpprofil)
) ;

GRANT ALL ON dhcpprofil, seq_dhcpprofil, dr_dhcpprofil TO dns ;
GRANT ALL ON dhcpprofil, seq_dhcpprofil, dr_dhcpprofil TO pda ;
GRANT ALL ON dhcpprofil, seq_dhcpprofil, dr_dhcpprofil TO jean ;


------------------------------------------------------------------------------
-- nouvelle colonne rr.iddhcpprofil associée à un nom
------------------------------------------------------------------------------

ALTER TABLE rr
    ADD COLUMN iddhcpprofil INT		-- identifiant du profil DHCP ou NULL
    ;

ALTER TABLE rr ADD
    FOREIGN KEY (iddhcpprofil) REFERENCES dhcpprofil (iddhcpprofil) ;

------------------------------------------------------------------------------
-- valeurs par défaut des paramètres de génération
------------------------------------------------------------------------------

INSERT INTO config (clef, valeur) VALUES ('default_lease_time', 600) ;
INSERT INTO config (clef, valeur) VALUES ('max_lease_time', 3600) ;
INSERT INTO config (clef, valeur) VALUES ('min_lease_time', 300) ;

------------------------------------------------------------------------------
-- valide un intervalle DHCP (min-max) par rapport aux droits du groupe
------------------------------------------------------------------------------
-- $1 : idgrp
-- $2 : dhcp min
-- $3 : dhcp max
CREATE OR REPLACE FUNCTION valide_dhcprange_grp (INTEGER, INET, INET)
		RETURNS BOOLEAN AS '
    set min {}
    foreach o [split $2 "."] {
	lappend min [format "%02x" $o]
    }
    set min [join $min ""]
    set min [expr 0x$min]
    set ipbin [expr 0x$min]

    set max {}
    foreach o [split $3 "."] {
	lappend max [format "%02x" $o]
    }
    set max [join $max ""]
    set max [expr 0x$max]

    set r t
    for {set ipbin $min} {$ipbin <= $max} {incr ipbin} {
	# Preparer la nouvelle adresse IP
	set ip {}
	set o $ipbin
	for {set i 0} {$i < 4} {incr i} {
	    set ip [linsert $ip 0 [expr $o & 0xff]]
	    set o [expr $o >> 8]
	}
	set ip [join $ip "."]

	# Tester la validite
	spi_exec "SELECT valide_ip_grp (\'$ip\', $1) AS v"

	if {! [string equal $v "t"]} then {
	    set r f
	    break
	}
    }
    return $r
    ' LANGUAGE pltcl ;
