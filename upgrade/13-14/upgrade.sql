------------------------------------------------------------------------------
-- création de la table log
--
-- Méthode :
--    - modifier ce fichier pour indiquer les utilisateurs (lignes GRANT)
--    - psql dns < upgrade.sql 
--
-- $Id: upgrade.sql,v 1.3 2008-07-23 08:50:43 pda Exp $
------------------------------------------------------------------------------

CREATE TABLE log (
    date		TIMESTAMP WITHOUT TIME ZONE
				DEFAULT CURRENT_TIMESTAMP
				NOT NULL,
    subsys		TEXT NOT NULL,
    event		TEXT NOT NULL,
    login		TEXT,
    ip			INET,
    msg			TEXT
) ;

GRANT ALL ON log TO dns ;
GRANT ALL ON log TO jean ;
GRANT ALL ON log TO pda ;
