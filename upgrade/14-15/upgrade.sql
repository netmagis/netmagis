------------------------------------------------------------------------------
-- Mise à jour de la base vers la version 1.5
--
-- Méthode :
--	- psql dns < upgrade.sql
--		(attention : la mise à jour est lente)
--
-- $Id: upgrade.sql,v 1.5 2008-07-25 10:33:52 pda Exp $
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
-- ajout du champ "droitsmtp" dans la table groupe
------------------------------------------------------------------------------

ALTER TABLE groupe
	ADD COLUMN droitsmtp INT ;

ALTER TABLE groupe
	ALTER COLUMN droitsmtp
	SET DEFAULT 0 ;

UPDATE groupe
	SET droitsmtp = 0
	WHERE droitsmtp IS NULL ;

------------------------------------------------------------------------------
-- ajout du champ "droitsmtp" dans la table RR
------------------------------------------------------------------------------

ALTER TABLE rr
	ADD COLUMN droitsmtp INT ;

ALTER TABLE rr
	ALTER COLUMN droitsmtp
	SET DEFAULT 0 ;

UPDATE rr
	SET droitsmtp = 0
	WHERE droitsmtp IS NULL ;

------------------------------------------------------------------------------
-- divers
------------------------------------------------------------------------------

ALTER TABLE groupe
	ALTER COLUMN admin
	SET DEFAULT 0 ;
