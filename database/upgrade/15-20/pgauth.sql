CREATE SCHEMA pgauth ;

GRANT USAGE  ON SCHEMA pgauth TO pda, jean, dns ;
GRANT CREATE ON SCHEMA pgauth TO pda, jean ;

CREATE TABLE pgauth.user (
    login	TEXT,		-- nom de login
    password	TEXT,		-- mot de passe (crypté)
    nom		TEXT,		-- nom
    prenom	TEXT,		-- prénom
    mel		TEXT,		-- adresse électronique
    tel		TEXT,		-- numéro de téléphone fixe
    mobile	TEXT,		-- numéro de téléphone mobile
    fax		TEXT,		-- numéro de fax
    adr		TEXT,		-- adresse

    -- champs gérés automatiquement par trigger
    phnom	TEXT,		-- nom phonétique
    phprenom	TEXT,		-- prénom phonétique

    PRIMARY KEY (login)
) ;

CREATE TABLE pgauth.realm (
    realm	TEXT,		-- realm name
    descr	TEXT,		-- texte en clair
    admin	INT,		-- 1 if admin

    PRIMARY KEY (realm)
) ;

CREATE TABLE pgauth.member (
    login	TEXT,		-- nom de login
    realm	TEXT,		-- realm auquel appartient ce login

    FOREIGN KEY (login) REFERENCES pgauth.user (login),
    FOREIGN KEY (realm) REFERENCES pgauth.realm (realm),
    PRIMARY KEY (login, realm)
) ;

GRANT ALL
    ON pgauth.user, pgauth.realm, pgauth.member
    TO dns, pda, jean ;

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

INSERT INTO pgauth.realm (realm, descr, admin)
	    VALUES ('authadmin','Administrators of internal PostgreSQL auth',1);

INSERT INTO pgauth.user (login, password, nom, prenom)
	    VALUES ('pda', 'qN.mLR7i6WogM', 'DAVID', 'Pierre') ;

INSERT INTO pgauth.member (login, realm)
	    VALUES ('pda', 'authadmin') ;
