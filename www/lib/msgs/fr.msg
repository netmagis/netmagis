
#
# WebDNS translation messages
#

# Links menu
::msgcat::mcmset fr {
    {Welcome} {Accueil}
    {Consult} {Consulter}
    {Add} {Ajouter}
    {Delete} {Supprimer}
    {Modify} {Modifier}
    {Mail roles} {Rôles mail}
    {DHCP ranges} {Plages DHCP}
    {Password} {Mot de passe}
    {Search} {Rechercher}
    {Where am I?} {Où suis-je ?}
    {Topology} {Topo}
    {Admin} {Admin}

    {Equipments} {Équipements}
    {Vlans} {Vlans}
    {Networks} {Réseaux}
    {DNS/DHCP} {DNS/DHCP}

    {Consult MX} {MX}
    {Statistics by user} {Stats par correspondant}
    {Statistics by organization} {Stats par établissement}
    {Consult networks} {Réseaux}
    {List users} {Correspondants}
    {Search} {Chercher}
    {Modify organizations} {Modif établissements}
    {Modify communities} {Modif communautés}
    {Modify machine types} {Modif types de machines}
    {Modify networks} {Modif réseaux}
    {Modify domains} {Modif domaines}
    {Modify mailhost} {Modif relais de messagerie}
    {Modify zones} {Modif zones normales}
    {Modify reverse IPv4 zones} {Modif zones IPv4}
    {Modify reverse IPv6 zones} {Modif zones IPv6}
    {Modify DHCP profiles} {Modif profils DHCP}
    {Modify Vlans} {Modif Vlans}
    {Modify users and groups} {Modif groupes}
    {Force zone generation} {Forcer zones}
    {Application parameters} {Modif paramètres}
    {Topod status} {Topod status}

    {Unknown module '%s'} {Module '%s' inconnu}
}

# Library
::msgcat::mcmset fr {
    {Error accessing database (%s)} {Erreur d'accès à la base de données (%s)}
    {Connection refused (%s)} {Connexion refusée (%s)}
    {No login: authentication failed} {Pas de login : l'authentification a échoué}
    {Error accessing database: %s} {Erreur d'accès à la base: %s}
    {User '%s' not authorized} {Utilisateur '%s' non autorisé}
    {Authentication base problem (%s)} {Problème de base d'authentification (%s)}
    {User '%s' is not in the authentication base} {L'utilisateur '%s' n'est pas dans la base d'authentification}
    {Found too many users} {Trop d'utilisateurs trouvés}
    {User '%s' is not in the WebDNS base} {L'utilisateur '%s' n'est pas dans la base d'authentification}
    {Invalid input} {Données invalides}

    {User}	{Utilisateur}
    {Login}	{Login}
    {Mail}	{Mél}
    {Phone}	{Tél fixe}
    {Mobile}	{Tél mobile}
    {Fax}	{Fax}
    {Address}	{Adresse}

    {Authentication base problem: %s} {Problème dans la base d'authentification : %s}
    {User '%s' is not in the authentication base} {'%s' n'est pas dans la base d'authentification}
    {Too many users found} {Trop d'utilisateurs trouvés}
    {User '%s' is not in the WebDNS base} {'%s' n'est pas dans la base de WebDNS}
    {This host holds mail addresses} {Cette machine héberge des adresses de messagerie}
    {Internal error: '%s' inserted, but not found in database} {Erreur interne : '%s' inséré, mais non retrouvé dans la base}
    {RR addition impossible: %s} {Création du RR impossible : %s}
    {RR update impossible: %s} {Mise à jour du RR impossible : %s}

    {Name}		{Nom}
    {IP address}	{Adresse IP}
    {IP addresses}	{Adresses IP}
    {(none)}		{(aucune)}
    {MAC address}	{Adresse MAC}
    {DHCP profile}	{Profil DHCP}
    {Type}		{Type}
    {Yes}		{Oui}
    {No}		{Non}
    {SMTP emit right}	{Droit d'émission SMTP}
    {TTL}		{TTL}
    {Comment}		{Infos complémentaires}
    {Responsible (name)}	{Responsable (nom + prénom)}
    {Responsible (mail)}	{Responsable (mél)}
    {Aliases}		{Aliases}

    {Invalid FQDN '%s'}	{FQDN '%s' invalide}
    {Invalid domain '%s'}	{Domaine '%s' invalide}
    {Invalid name '%s'}	{Nom '%s' invalide}
    {'%1$s' is not a valid IPv%2$s address} {'%1$s' n'est pas une adresse IPv%2$s valide}
    {The '/' character is not valid in the address} {Le caractère '/' est interdit dans l'adresse}
    {Invalid syntax for '%s'} {Syntaxe invalide pour '%s'}
    {Invalid syntax for DHCP profile} {Syntaxe invalide pour le profil DHCP}
    {No profile} {Aucun profil}

    {Internal error: invalid context '%s'} {Erreur interne : contexte '%s' invalide}
    {'%1$s' is an alias of '%2$s'} {'%1$s' est un alias de '%2$s'}
    {You don't have rights on '%s'} {Vous n'avez pas les droits sur '%s'}
    {Internal error: invalid parameter '%1$s' for '%2$s'} {Erreur interne : paramètre invalide '%$1s' pour '%2$s'}
    {'%s' is a MX} {'%s' est un MX}
    {'%s' is a mail role} {'%s' est un rôle de messagerie}
    {Internal error: id '%s' doesn't exists for a mailhost} {Erreur interne : hébergeur d'id '%s' inexistant}
    {You don't have rights on host holding mail for '%s'} {Vous n'avez pas les droits sur l'hébergeur de '%s'}
    {'%s' is a mail host for mail domains} {'%s' est un hébergeur pour des adresses de messagerie}
    {'%s' has IP addresses} {'%s' a des adresses IP}
    {Name '%s' is not a host} {Le nom '%s' ne correspond pas à une machine}
    {Name '%s' does not exist} {Le nom '%s' n'existe pas}
    {Domain '%s' not found} {Domaine '%s' non trouvé}
    {Domain-id '%s' not found} {Identificateur de domaine '%s' non trouvé}
    {MX '%1$s' points to a domain on which you don't have rights\n%2$s} {Le MX '%1$s' référence un domaine auquel vous n'avez pas accès\n%2$s}
    {Invalid MX priority '%s'} {Priorité de MX non valide '%s'}
    {You don't have rights to some relays of domain '%1$s'\n%2$s} {Vous n'avez pas les droits sur certains relais du domaine '%1$s'\n%2$s}
    {Internal error on '%1$s': id '%2$s' of mail host not found} {Erreur interne sur '%1$s' : id de l'hébergeur '%2$s' non trouvé}
    {Impossible to use MAC address '%1$s' because IP address '�%2$s' is in DHCP dynamic range [%3$s..%4$s]} {Impossible d'affecter l'adresse MAC '%1$s' car l'adresse IP '%2$s' figure dans l'intervalle DHCP dynamique [%3$s..%4$s]}
    {Invalid TTL: must be a positive integer} {TTL invalide : doit être un nombre entier positif}
    {Invalid TTL: must be less than %s} {TTL invalide : doit être inférieur à %s}
    {Invalid group name '%s' (allowed chars: letters, digits and minus symbol)} {Nom de groupe '%s' invalide (caractères autorisés : lettres, chiffres et caractère moins)}
}
