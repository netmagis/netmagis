-- virer les cas qui ne correspondent à rien
-- utiliser DHCP sur un RR n'a de sens que pour fournir une
-- association statique MAC <-> IP. S'il n'y a pas d'adresse
-- MAC, il n'y a donc pas besoin d'y avoir un profil DHCP

UPDATE rr
    SET iddhcpprofil = NULL
    WHERE mac IS NULL AND iddhcpprofil IS NOT NULL ;
