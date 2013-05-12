------------------------------------------------------------------------------
-- Netmagis SQL functions
------------------------------------------------------------------------------


------------------------------------------------------------------------------
-- Check a DHCP range against group permissions
-- 
-- Input:
--   - $1 : idgrp
--   - $2 : dhcp min
--   - $3 : dhcp max
-- Output:
--   - true (all addresses in DHCP range are allowed) or false
--
-- History
--    200?/??/?? : pda : design
--


-- check a DHCP range against group permissions
CREATE OR REPLACE FUNCTION dns.check_dhcprange_grp (INTEGER, INET, INET)
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
	# Prepare the new IP address
	set ip {}
	set o $ipbin
	for {set i 0} {$i < 4} {incr i} {
	    set ip [linsert $ip 0 [expr $o & 0xff]]
	    set o [expr $o >> 8]
	}
	set ip [join $ip "."]

	# Check validity
	spi_exec "SELECT dns.check_ip_grp (''$ip'', $1) AS v"

	if {! [string equal $v "t"]} then {
	    set r f
	    break
	}
    }
    return $r
    ' LANGUAGE pltcl ;


------------------------------------------------------------------------------
-- Classifies each IPv4 address in a network
--
-- Input:
--   - net: network address
--   - lim: limit on the number of addresses classified
--   - grp: group id
-- Output:
--    - table with columns:
--		adr   INET
--		avail INTEGER (see below)
--		fqdn  TEXT
--
-- Note: addresses are classified according to:
--     0 : unavailable (broadcast addr, no right on addr, etc.)
--     1 : not declared and not in a dhcp range
--     2 : declared and not in a dhcp range
--     3 : not declared and in a dhcp range
--     4 : declared and in a dhcp range
--   This function creates a temporary table (allip) which only exists
--   during the postgresql session lifetime. This table is internal to
--   the session (other sessions cannot see it).
--   Since this function performs a sequential traversal of IP range,
--   a limit value must be given to not overload the PostgreSQL engine.
--
-- History
--    200?/??/?? : pda : design
--

CREATE OR REPLACE FUNCTION dns.mark_cidr (net CIDR, lim INTEGER, grp INTEGER)
    RETURNS void AS $$
    DECLARE
	min INET ;
	max INET ;
	a INET ;
    BEGIN
	min := INET (HOST (net)) ;
	max := INET (HOST (BROADCAST (net))) ;

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
	    fqdn TEXT		-- if 2 or 4, then fqdn else NULL
	) ;

	a := min ; 
	WHILE a <= max LOOP
	    INSERT INTO allip VALUES (a, 1) ;
	    a := a + 1 ;
	END LOOP ;

	UPDATE allip
	    SET fqdn = rr.nom || '.' || domain.name,
		avail = 2
	    FROM dns.rr_ip, dns.rr, dns.domain
	    WHERE allip.adr = rr_ip.adr
		AND rr_ip.idrr = rr.idrr
		AND rr.iddom = domain.iddom
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
	    WHERE adr = min OR adr = max OR NOT dns.check_ip_grp (adr, grp) ;

	RETURN ;

    END ;
    $$ LANGUAGE plpgsql ;

------------------------------------------------------------------------------
-- Search IPv4 address range for available blocks
--
-- Input:
--   - net: network address
--   - lim: limit on the number of addresses classified
--   - grp: group id
-- Output:
--    - table with columns:
--		a	INET		-- starting address
--		n	INTEGER		-- number of addresses in block
--
-- Note: this is the PostgreSQL 8.3 version (the 8.4 version would have
--   been more elegant)
--
-- History
--    200?/??/?? : pda : design
--

DROP TYPE IF EXISTS iprange_t ;
CREATE TYPE iprange_t AS (a INET, n INTEGER) ;

CREATE OR REPLACE FUNCTION dns.ipranges (net CIDR, lim INTEGER, grp INTEGER)
    RETURNS SETOF iprange_t AS $$
    DECLARE
	inarange BOOLEAN ;
	r RECORD ;
	q iprange_t%ROWTYPE ;
    BEGIN
	PERFORM dns.mark_cidr (net, lim, grp) ;
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
-- Set the generation flag for one or more zones. These functions
-- are called from the corresponding trigger functions and set the
-- generation flag for all modified zones.
--
-- Input:
--   - $1: IPv4/v6 address or domain id or RR id
--   - $2: view id
-- Output:
--   - an unused integer value, just to be able to call sum() on result
--
-- History
--    2002/??/?? : pda/jean : design
--

-- called when an IPv6 address is modified ($1=addr, $2=idrr)
CREATE OR REPLACE FUNCTION dns.gen_rev4 (INET, INTEGER)
    RETURNS INTEGER AS $$
    BEGIN
	UPDATE dns.zone_reverse4 AS z SET gen = 1
	    FROM dns.rr
	    WHERE $1 <<= selection
		AND rr.idrr = $2
		AND z.idview = rr.idview ;
	RETURN 1 ;
    END ;
    $$ LANGUAGE 'plpgsql' ;

-- called when an IPv6 address is modified ($1=addr, $2=idrr)
CREATE OR REPLACE FUNCTION dns.gen_rev6 (INET, INTEGER)
    RETURNS INTEGER AS $$
    BEGIN
	UPDATE dns.zone_reverse6 AS z SET gen = 1
	    FROM dns.rr
	    WHERE $1 <<= selection
		AND rr.idrr = $2
		AND z.idview = rr.idview ;
	RETURN 1 ;
    END ;
    $$ LANGUAGE 'plpgsql' ;

-- ID of RR ($1=idrr)
CREATE OR REPLACE FUNCTION dns.gen_norm_idrr (INTEGER)
    RETURNS INTEGER AS $$
    BEGIN
	UPDATE dns.zone_normale SET gen = 1
		WHERE (selection, idview) = 
			(
			    SELECT domain.name, rr.idview
				FROM dns.domain, dns.rr
				WHERE rr.idrr = $1
				    AND rr.iddom = domain.iddom
			) ;
	RETURN 1 ;
    END ;
    $$ LANGUAGE 'plpgsql' ;

-- ID of RR ($1=iddom, $2=idview)
CREATE OR REPLACE FUNCTION dns.gen_norm_iddom (INTEGER, INTEGER)
    RETURNS INTEGER AS $$
    BEGIN
	UPDATE dns.zone_normale SET gen = 1
		WHERE idview = $2
		    AND selection = (
			SELECT domain.name
				FROM dns.domain
				WHERE domain.iddom = $1
			) ;
	RETURN 1 ;
    END ;
    $$ LANGUAGE 'plpgsql' ;

-- utility function for the mod_relay trigger function
-- called when a mail relay is modified ($1=iddom, $2=idrr of mx)
CREATE OR REPLACE FUNCTION dns.gen_relay (INTEGER, INTEGER)
    RETURNS INTEGER AS $$
    BEGIN
	UPDATE dns.zone_normale SET gen = 1
	    WHERE selection = ( SELECT name FROM dns.domain WHERE iddom = $1 )
		AND idview = ( SELECT idview FROM dns.rr WHERE idrr = $2 )
	    ;
	RETURN 1 ;
    END ;
    $$ LANGUAGE 'plpgsql' ;

------------------------------------------------------------------------------
-- Set the DHCP generation flag for one or more views.
--
-- Input:
--   - $1: RR id
-- Output:
--   - an unused integer value, just to be able to call sum() on result
--
-- History
--    201?/??/?? : pda/jean : design
--

CREATE OR REPLACE FUNCTION dns.gen_dhcp (INTEGER)
    RETURNS INTEGER AS $$
    BEGIN
	UPDATE dns.view SET gendhcp = 1
	    FROM dns.rr
		WHERE rr.idrr = $1
		    AND rr.mac IS NOT NULL
		    AND view.idview = rr.idview ;
	RETURN 1 ;
    END ;
    $$ LANGUAGE 'plpgsql' ;

------------------------------------------------------------------------------
-- Trigger function called when an IP address is modified
--
-- History
--    200?/??/?? : pda/jean : design
--

CREATE OR REPLACE FUNCTION dns.mod_ip ()
    RETURNS trigger AS $$
    BEGIN
	IF TG_OP = 'INSERT'
	THEN
	    PERFORM sum (dns.gen_rev4 (NEW.adr, NEW.idrr)) ;
	    PERFORM sum (dns.gen_rev6 (NEW.adr, NEW.idrr)) ;
	    PERFORM sum (dns.gen_norm_idrr (NEW.idrr)) ;
	    PERFORM sum (dns.gen_dhcp (NEW.idrr)) ;

	END IF ;

	IF TG_OP = 'UPDATE'
	THEN
	    PERFORM sum (dns.gen_rev4 (NEW.adr, NEW.idrr)) ;
	    PERFORM sum (dns.gen_rev4 (OLD.adr, OLD.idrr)) ;
	    PERFORM sum (dns.gen_rev6 (NEW.adr, NEW.idrr)) ;
	    PERFORM sum (dns.gen_rev6 (OLD.adr, OLD.idrr)) ;
	    PERFORM sum (dns.gen_norm_idrr (NEW.idrr)) ;
	    PERFORM sum (dns.gen_norm_idrr (OLD.idrr)) ;
	    PERFORM sum (dns.gen_dhcp (NEW.idrr)) ;
	    PERFORM sum (dns.gen_dhcp (OLD.idrr)) ;
	END IF ;

	IF TG_OP = 'DELETE'
	THEN
	    PERFORM sum (dns.gen_rev4 (OLD.adr, OLD.idrr)) ;
	    PERFORM sum (dns.gen_rev6 (OLD.adr, OLD.idrr)) ;
	    PERFORM sum (dns.gen_norm_idrr (OLD.idrr)) ;
	    PERFORM sum (dns.gen_dhcp (OLD.idrr)) ;
	END IF ;

	RETURN NEW ;
    END ;
    $$ LANGUAGE 'plpgsql' ;

------------------------------------------------------------------------------
-- Trigger function called when a CNAME or a MX is modified
--
-- History
--    200?/??/?? : pda/jean : design
--

CREATE OR REPLACE FUNCTION dns.mod_mxcname ()
    RETURNS trigger AS $$
    BEGIN
	IF TG_OP = 'INSERT'
	THEN
	    PERFORM sum (dns.gen_norm_idrr (NEW.idrr)) ;
	END IF ;

	IF TG_OP = 'UPDATE'
	THEN
	    PERFORM sum (dns.gen_norm_idrr (NEW.idrr)) ;
	    PERFORM sum (dns.gen_norm_idrr (OLD.idrr)) ;
	END IF ;

	IF TG_OP = 'DELETE'
	THEN
	    PERFORM sum (dns.gen_norm_idrr (OLD.idrr)) ;
	END IF ;

	RETURN NEW ;
    END ;
    $$ LANGUAGE 'plpgsql' ;

------------------------------------------------------------------------------
-- Trigger function called when a RR is modified
--
-- History
--    200?/??/?? : pda/jean : design
--

-- modify RR and reverse zones for all IP addresses
CREATE OR REPLACE FUNCTION dns.mod_rr ()
    RETURNS trigger AS $$
    BEGIN
	-- IF TG_OP = 'INSERT'
	-- THEN
	    -- no need to regenerate anything since no rr_* has
	    -- been linked to this rr yet
	-- END IF ;

	IF TG_OP = 'UPDATE'
	THEN
	    PERFORM sum (dns.gen_norm_iddom (NEW.iddom, NEW.idview))
		    ;
	    PERFORM sum (dns.gen_norm_iddom (OLD.iddom, OLD.idview))
		    ;
	    PERFORM sum (dns.gen_rev4 (rr_ip.adr, NEW.idrr))
		    FROM dns.rr_ip WHERE rr_ip.idrr = NEW.idrr ;
	    PERFORM sum (dns.gen_rev6 (rr_ip.adr, NEW.idrr))
		    FROM dns.rr_ip WHERE rr_ip.idrr = NEW.idrr ;
	    PERFORM sum (dns.gen_dhcp (NEW.idrr))
		    ;
	    -- no need to regenerate reverse/dhcp for old rr since
	    -- IP addresses did not change
	END IF ;

	-- IF TG_OP = 'DELETE'
	-- THEN
	    -- no need to regenerate anything since all rr_* have
	    -- already been removed before
	-- END IF ;

	RETURN NEW ;
    END ;
    $$ LANGUAGE 'plpgsql' ;

------------------------------------------------------------------------------
-- Trigger function called when a mail relay is modified
--
-- History
--    200?/??/?? : pda/jean : design
--

CREATE OR REPLACE FUNCTION dns.mod_relay ()
    RETURNS trigger AS $$
    BEGIN
	IF TG_OP = 'INSERT'
	THEN
	    PERFORM sum (dns.gen_relay (NEW.iddom, NEW.mx)) ;
	END IF ;

	IF TG_OP = 'UPDATE'
	THEN
	    PERFORM sum (dns.gen_relay (NEW.iddom, NEW.mx)) ;
	    PERFORM sum (dns.gen_relay (OLD.iddom, OLD.mx)) ;
	END IF ;

	IF TG_OP = 'DELETE'
	THEN
	    PERFORM sum (dns.gen_relay (OLD.iddom, OLD.mx)) ;
	END IF ;

	RETURN NEW ;
    END ;
    $$ LANGUAGE 'plpgsql' ;

------------------------------------------------------------------------------
-- Trigger function called when a zone is modified
--
-- History
--    200?/??/?? : pda/jean : design
--

CREATE OR REPLACE FUNCTION dns.mod_zone ()
    RETURNS TRIGGER AS $$
    BEGIN
	IF NEW.prologue <> OLD.prologue
		OR NEW.rrsup <> OLD.rrsup
		OR NEW.selection <> OLD.selection
	THEN
	    NEW.gen := 1 ;
	END IF ;
	RETURN NEW ;
    END ;
    $$ LANGUAGE 'plpgsql' ;

------------------------------------------------------------------------------
-- Trigger function called when a DHCP parameter (network, range or profile)
-- is modified
--
-- History
--    200?/??/?? : pda/jean : design
--

CREATE OR REPLACE FUNCTION dns.mod_dhcp ()
    RETURNS TRIGGER AS $$
    BEGIN
	UPDATE dns.view SET gendhcp = 1 ;
	RETURN NEW ;
    END ;
    $$ LANGUAGE 'plpgsql' ;

------------------------------------------------------------------------------
-- Check access rights to an IP address
--
-- Input:
--   - $1: IPv4/v6 address to test
--   - $2: group id or user id
-- Output:
--   - true if access is allowed
--
-- History
--    2002/??/?? : pda/jean : design
--

CREATE OR REPLACE FUNCTION dns.check_ip_cor (INET, INTEGER)
    RETURNS BOOLEAN AS $$
    BEGIN
	RETURN dns.check_ip_grp ($1, idgrp) FROM global.corresp WHERE idcor = $2 ;
    END ;
    $$ LANGUAGE 'plpgsql' ;

CREATE OR REPLACE FUNCTION dns.check_ip_grp (INET, INTEGER)
    RETURNS BOOLEAN AS $$
    BEGIN
	RETURN ($1 <<= ANY (SELECT addr FROM dns.p_ip
				WHERE allow_deny = 1 AND idgrp = $2)
	    AND NOT $1 <<= ANY (SELECT addr FROM dns.p_ip
				WHERE allow_deny = 0 AND idgrp = $2)
	    ) ;
    END ;
    $$ LANGUAGE 'plpgsql' ;

------------------------------------------------------------------------------
-- Trigger function called when a vlan is modified
--
-- History
--    200?/??/?? : pda/jean : design
--

CREATE OR REPLACE FUNCTION topo.mod_vlan ()
    RETURNS trigger AS $$
    BEGIN
	INSERT INTO topo.modeq (eq) VALUES ('_vlan') ;
	RETURN NEW ;
    END ;
    $$ LANGUAGE 'plpgsql' ;

------------------------------------------------------------------------------
-- Trigger function called when an equipment is modified
--
-- History
--    200?/??/?? : pda/jean : design
--

CREATE OR REPLACE FUNCTION topo.mod_routerdb ()
    RETURNS trigger AS $$
    BEGIN
	INSERT INTO topo.modeq (eq) VALUES ('_routerdb') ;
	RETURN NEW ;
    END ;
    $$ LANGUAGE 'plpgsql' ;

------------------------------------------------------------------------------
-- Reduce a string to a soundex code in order to find approximate
-- names
-- 
-- Input:
--   - $1: string to reduce
-- Output:
--   - soundex
--
-- History
--    200?/??/?? : pda : design
--

CREATE FUNCTION pgauth.soundex (TEXT)
    RETURNS TEXT AS '
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
	if {$TempIn eq ""} then {
	    return Z000
	}
	set last [string index $TempIn 0]
	set key  [string toupper $last]
	set last $soundexFrenchCode($last)

	# Scan rest of string, stop at end of string or when the key is full

	set count    1
	set MaxIndex [string length $TempIn]

	for {set index 1} {(($count < 4) && ($index < $MaxIndex))} {incr index } {
	    set chcode $soundexFrenchCode([string index $TempIn $index])
	    # Fold together adjacent letters sharing the same code
	    if {$last ne $chcode} then {
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

------------------------------------------------------------------------------
-- Trigger function: computes soundex for name and first name
-- each time a name or first name is modified.
--
-- History
--    200?/??/?? : pda : design
--

CREATE FUNCTION pgauth.add_soundex ()
    RETURNS TRIGGER AS '
    BEGIN
	NEW.phnom    := pgauth.SOUNDEX (NEW.nom) ;
	NEW.phprenom := pgauth.SOUNDEX (NEW.prenom) ;
	RETURN NEW ;
    END ;
    ' LANGUAGE 'plpgsql' ;
