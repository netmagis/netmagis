------------------------------------------------------------------------------
-- création de la table log
--
-- Méthode :
--    - modifier ce fichier pour indiquer les utilisateurs (lignes GRANT)
--    - psql dns < upgrade.sql 
--
-- $Id: upgrade.sql,v 1.2 2008-07-12 23:39:53 jean Exp $
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

ALTER TABLE dhcprange ADD COLUMN iddhcpprofil  integer ;
ALTER TABLE dhcprange ADD CONSTRAINT iddhcpprofilfk FOREIGN KEY(iddhcpprofil) REFERENCES dhcpprofil(iddhcpprofil);

