-- $Id$

------------------------------------------------------------------------------
-- -- version pour postgresql 8.4
-- -- version pour 8.3 ci-après

-- -- récupère toutes les adresses IP possibles du CIDR "reseau", dans
-- -- la limite de "lim" adresses
-- CREATE OR REPLACE FUNCTION allip (reseau CIDR, lim INTEGER)
--     RETURNS TABLE (a INET, n INT) AS $$
--     DECLARE
-- 	min INET ;
-- 	max INET ;
--     BEGIN
-- 	min := INET (HOST (reseau)) + 1 ;
-- 	max := INET (HOST (BROADCAST (reseau))) ;
-- 
-- 	IF max - min > lim THEN
-- 	    RAISE EXCEPTION 'Too many addresses' ;
-- 	END IF ;
-- 
-- 	a := min ;
-- 	n := 1 ;
-- 	WHILE a < max LOOP
-- 	    RETURN NEXT ;
-- 	    a := a + 1 ;
-- 	END LOOP ;
-- 
-- 	RETURN ;
-- 
--     END ;
--     $$ LANGUAGE plpgsql ;
-- 
-- -- récupère toutes les adresses IP du CIDR "reseau" autorisées 
-- -- pour le groupe "grp" qui ne sont pas actuellement utilisées
-- -- et les réduit en une table d'intervalles
-- CREATE OR REPLACE FUNCTION unusedip (reseau CIDR, lim INTEGER, grp INTEGER)
--     RETURNS TABLE (a INET, n INT) AS $$
--     DECLARE
-- 	b BOOLEAN ;
-- 	r RECORD ;
-- 	a INET ;
-- 	n INTEGER ;
--     BEGIN
-- 	b := FALSE ;
-- 	FOR r IN (SELECT * FROM allip (reseau, lim) AS tuple
-- 			WHERE tuple.a NOT IN (SELECT adr FROM rr_ip)
-- 			AND valide_ip_grp (tuple.a, grp)
-- 		    ORDER BY tuple.a)
-- 	LOOP
-- 	    IF b THEN
-- 		IF a + n = r.a THEN
-- 		    n := n + 1 ;
-- 		ELSE
-- 		    RETURN NEXT ;
-- 		    b := FALSE ;
-- 		END IF ;
-- 	    END IF ;
-- 	    IF NOT b THEN
-- 		b := TRUE ;
-- 		a := r.a ;
-- 		n := r.n ;
-- 	    END IF ;
-- 	END LOOP ;
-- 	IF b THEN
-- 	    RETURN NEXT ;
-- 	END IF ;
-- 	RETURN ;
--     END ;
--     $$ LANGUAGE plpgsql ;


------------------------------------------------------------------------------
-- version pour postgresql 8.3

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

	UPDATE allip SET avail = 0
	    WHERE adr = min OR adr = max OR NOT valide_ip_grp (adr, grp) ;

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

	RETURN ;

    END ;
    $$ LANGUAGE plpgsql ;

