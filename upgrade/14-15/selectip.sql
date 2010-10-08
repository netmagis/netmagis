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

CREATE OR REPLACE FUNCTION allip (reseau CIDR, lim INTEGER)
    RETURNS SETOF iprange_t AS $$
    DECLARE
	min INET ;
	max INET ;
	q iprange_t%ROWTYPE ;
    BEGIN
	min := INET (HOST (reseau)) + 1 ;
	max := INET (HOST (BROADCAST (reseau))) ;

	IF max - min > lim THEN
	    RAISE EXCEPTION 'Too many addresses' ;
	END IF ;

	q.a := min ;
	q.n := 1 ;
	WHILE q.a < max LOOP
	    RETURN NEXT q ;
	    q.a := q.a + 1 ;
	END LOOP ;

	RETURN ;

    END ;
    $$ LANGUAGE plpgsql ;

CREATE OR REPLACE FUNCTION unusedip (reseau CIDR, lim INTEGER, grp INTEGER)
    RETURNS SETOF iprange_t AS $$
    DECLARE
	b BOOLEAN ;
	r RECORD ;
	q iprange_t%ROWTYPE ;
    BEGIN
	b := FALSE ;
	FOR r IN (SELECT * FROM allip (reseau, lim) AS tuple
			WHERE tuple.a NOT IN (SELECT adr FROM rr_ip)
			AND valide_ip_grp (tuple.a, grp)
		    ORDER BY tuple.a)
	LOOP
	    IF b THEN
		IF q.a + q.n = r.a THEN
		    q.n := q.n + 1 ;
		ELSE
		    RETURN NEXT q ;
		    b := FALSE ;
		END IF ;
	    END IF ;
	    IF NOT b THEN
		b := TRUE ;
		q.a := r.a ;
		q.n := r.n ;
	    END IF ;
	END LOOP ;
	IF b THEN
	    RETURN NEXT q ;
	END IF ;
	RETURN ;
    END ;
    $$ LANGUAGE plpgsql ;

DROP TYPE IF EXISTS availip_t CASCADE ;
CREATE TYPE availip_t AS (adr INET, avail INTEGER) ;

CREATE OR REPLACE FUNCTION availip (reseau CIDR, lim INTEGER, grp INTEGER)
    RETURNS SETOF availip_t AS $$
    DECLARE
    BEGIN
	RETURN QUERY (SELECT * FROM
		    (
			SELECT a AS adr, 1 AS avail
			    FROM allip (reseau, lim) AS tuple
			    WHERE tuple.a NOT IN (SELECT adr FROM rr_ip)
				AND valide_ip_grp (tuple.a, grp)
			UNION
			SELECT a AS adr, 0 AS avail
			    FROM allip (reseau, lim) AS tuple
			    WHERE tuple.a IN (SELECT adr FROM rr_ip)
				OR NOT valide_ip_grp (tuple.a, grp)
		    ) AS foo
		    ORDER BY foo.adr) ;
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

	DROP TABLE IF EXISTS allip ;
	CREATE TEMP TABLE allip (
	    adr INET,
	    avail INTEGER		-- 1 : avail, 2 : busy, 0 : unavailable
	) ;

	a := min ; 
	WHILE a <= max LOOP
	    INSERT INTO allip VALUES (a, 1) ;
	    a := a + 1 ;
	END LOOP ;

	UPDATE allip SET avail = 0
	    WHERE adr = min OR adr = max OR NOT valide_ip_grp (adr, grp) ;

	UPDATE allip SET avail = 2 WHERE adr IN (SELECT adr FROM rr_ip) ;

	RETURN ;

    END ;
    $$ LANGUAGE plpgsql ;

