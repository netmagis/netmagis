------------------------------------------------------------------------------
-- Mise à jour de la base vers la version 1.5
--
-- Méthode :
--	- psql -f upgrade.sql dns
--
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- ajout des profils dans les intervalles DHCP
------------------------------------------------------------------------------

ALTER TABLE dhcprange
	ADD COLUMN iddhcpprofil INT ;

ALTER TABLE dhcprange
	ADD CONSTRAINT iddhcpprofilfk
	FOREIGN KEY (iddhcpprofil) REFERENCES dhcpprofil(iddhcpprofil) ;

------------------------------------------------------------------------------
-- ajout des colonnes "droitsmtp" et "ttl" dans la table groupe
------------------------------------------------------------------------------

ALTER TABLE groupe
	ADD COLUMN droitsmtp INT ;

ALTER TABLE groupe
	ALTER COLUMN droitsmtp
	SET DEFAULT 0 ;

UPDATE groupe
	SET droitsmtp = 0
	WHERE droitsmtp IS NULL ;

-- ajout du champ "ttl" dans la table groupe

ALTER TABLE groupe
	ADD COLUMN droitttl INT ;

ALTER TABLE groupe
	ALTER COLUMN droitttl
	SET DEFAULT 0 ;

UPDATE groupe
	SET droitttl = 0
	WHERE droitttl IS NULL ;

------------------------------------------------------------------------------
-- ajout des colonnes "droitsmtp" et "ttl" dans la table RR
------------------------------------------------------------------------------

-- supprimer le trigger temporairement pour accélérer les grosses modifications
DROP TRIGGER tr_modifier_rr ON rr ;

ALTER TABLE rr
	ADD COLUMN droitsmtp INT ;

ALTER TABLE rr
	ALTER COLUMN droitsmtp
	SET DEFAULT 0 ;

UPDATE rr
	SET droitsmtp = 0
	WHERE droitsmtp IS NULL ;

-- ajout du champ "ttl" dans la table RR

ALTER TABLE rr
	ADD COLUMN ttl INT ;

ALTER TABLE rr
	ALTER COLUMN ttl
	SET DEFAULT -1 ;

UPDATE rr
	SET ttl = -1
	WHERE ttl IS NULL ;

-- remettre le trigger dans l'état initial

CREATE TRIGGER tr_modifier_rr
    AFTER INSERT OR UPDATE OR DELETE
    ON rr
    FOR EACH ROW
    EXECUTE PROCEDURE modifier_rr ()
    ;

------------------------------------------------------------------------------
-- ajout d'un trigger sur la table DHCPPROFIL
------------------------------------------------------------------------------

CREATE TRIGGER tr_modifier_dhcpprofil
    BEFORE UPDATE
    ON dhcpprofil
    FOR EACH ROW
    EXECUTE PROCEDURE generer_dhcp ()
    ;


------------------------------------------------------------------------------
-- mettre une valeur par défaut pour le droit d'admin des nouveaux groupes
------------------------------------------------------------------------------

ALTER TABLE groupe
	ALTER COLUMN admin
	SET DEFAULT 0 ;

------------------------------------------------------------------------------
-- utiliser DHCP sur un RR n'a de sens que pour fournir une
-- association statique MAC <-> IP. S'il n'y a pas d'adresse
-- MAC, il n'y a donc pas besoin d'y avoir un profil DHCP
-- Cette ligne supprime donc les cas qui ne correspondent à rien
------------------------------------------------------------------------------

UPDATE rr
    SET iddhcpprofil = NULL
    WHERE mac IS NULL AND iddhcpprofil IS NOT NULL ;


------------------------------------------------------------------------------
-- fonction pour marquer l'espace d'adressage d'un CIDR, et caractériser
-- chaque adresse IPv4 par une des valeurs suivantes
--   0 : unavailable (broadcast addr, no right on addr, etc.)
--   1 : not declared and not in a dhcp range
--   2 : declared and not in a dhcp range
--   3 : not declared and in a dhcp range
--   4 : declared and in a dhcp range
-- Cette fonction crée une table temporaire (allip) qui ne dure
-- que le temps de la session postgresql. Cette table n'est pas visible
-- des autres sessions.
-- Comme cette fonction fait un parcours séquentiel de l'espace d'adressage
-- une valeur limite est indiquée pour ne pas surcharger le moteur
-- PostgreSQL. Cette limite est indiquée par les scripts (cf www/bin/liste
-- et www/bin/traitejout)
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
	    FROM rr_ip, rr, domaine
	    WHERE allip.adr = rr_ip.adr
		AND rr_ip.idrr = rr.idrr
		AND rr.iddom = domaine.iddom
		;

	UPDATE allip
	    SET avail = CASE
			    WHEN avail = 1 THEN 3
			    WHEN avail = 2 THEN 4
			END
	    FROM dhcprange
	    WHERE (avail = 1 OR avail = 2)
		AND adr >= dhcprange.min
		AND adr <= dhcprange.max
	    ;

	UPDATE allip SET avail = 0
	    WHERE adr = min OR adr = max OR NOT valide_ip_grp (adr, grp) ;

	RETURN ;

    END ;
    $$ LANGUAGE plpgsql ;

------------------------------------------------------------------------------
-- fonction pouyr rechercher des blocs d'adresses IP(v4) consécutives
-- disponibles.
-- (version pour postgresql 8.3, la version pour 8.4 aurait été plus élégante)
------------------------------------------------------------------------------

-- ne pas tenir compte du warning si le type n'existe pas.
DROP TYPE IF EXISTS iprange_t CASCADE ;
CREATE TYPE iprange_t AS (a INET, n INTEGER) ;

CREATE OR REPLACE FUNCTION ipranges (reseau CIDR, lim INTEGER, grp INTEGER)
    RETURNS SETOF iprange_t AS $$
    DECLARE
	inarange BOOLEAN ;
	r RECORD ;
	q iprange_t%ROWTYPE ;
    BEGIN
	PERFORM markcidr (reseau, lim, grp) ;
	inarange := FALSE ;
	FOR r IN (SELECT adr, avail FROM allip ORDER BY adr)
	LOOP
	    IF inarange THEN
		-- (q.a, q.n) is already a valid range
		IF r.avail = 1 THEN
		    q.n := q.n + 1 ;
		ELSE
		    RETURN NEXT q ;
		    inarange := FALSE ;
		END IF ;
	    ELSE
		-- not inside a range
		IF r.avail = 1 THEN
		    -- start a new range (q.a, q.n)
		    q.a := r.adr ;
		    q.n := 1 ;
		    inarange := TRUE ;
		END IF ;
	    END IF ;
	END LOOP ;
	IF inarange THEN
	    RETURN NEXT q ;
	END IF ;
	DROP TABLE allip ;
	RETURN ;
    END ;
    $$ LANGUAGE plpgsql ;
