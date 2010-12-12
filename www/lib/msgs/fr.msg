
#
# WebDNS translation messages
#

###############################################################################
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
 {Mac} {Mac}
 {Admin} {Admin}

 {Equipments} {Équipements}
 {Vlans} {Vlans}
 {Networks} {Réseaux}
 {DNS/DHCP} {DNS/DHCP}

 {List MX} {Lister MX}
 {List networks} {Lister réseaux}
 {List users} {Lister correspondants}
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
 {Statistics by user} {Stats par correspondant}
 {Statistics by organization} {Stats par établissement}
 {Topod status} {Topod status}

 {MAC index} {Accueil MAC}
 {MAC search} {Recherche MAC}
 {Inactive addresses} {Adresses inactives}
 {MAC stats} {Stats MAC}

 {Unknown module '%s'} {Module '%s' inconnu}
}

###############################################################################
# Configuration parameters
::msgcat::mcmset fr {
 cfg:dns {Paramètres généraux}

 cfg:datefmt:desc {Format d'affichage des dates/heures}
 cfg:datefmt:help {Format d'affichage des dates et des heures, utilisé dans l'édition et l'affichage des données. Voir la page de manuel clock(n) de Tcl.}
 cfg:jourfmt:desc {Format d'affichage des jours}
 cfg:jourfmt:help {Format d'affichage des dates (sans l'heure). Voir la page de manuel clock(n) de Tcl.}

 cfg:dhcp {Paramètres DHCP}

 cfg:default_lease_time:desc {default_lease_time}
 cfg:default_lease_time:help {Valeur du parameter DHCP "default_lease_time" utilisé lors de la génération d'intervalles dynamiques, en secondes. Cette valeur est utilisée si le parameter spécifique de l'intervalle est nul.}
 cfg:max_lease_time:desc {max_lease_time}
 cfg:max_lease_time:help {Valeur du parameter DHCP "max_lease_time" utilisé lors de la génération d'intervalles dynamiques, en secondes.  Cette valeur est utilisée si le parameter spécifique de l'intervalle est nul.}
 cfg:min_lease_time:desc {min_lease_time}
 cfg:min_lease_time:help {Valeur minimale des parameters DHCP spécifiés dans les intervalles dynamiques. Cette valeur permet uniquement d'éviter qu'un correspondant réseau précise des parameters de bail trop petits et génère un trafic important.}

 cfg:topo {Paramètres du module "Topo"}

 cfg:topoactive:desc {Activation de Topo}
 cfg:topoactive:help {Cocher cette case pour activer l'accès à la fonctionnalité "Topo".}
 cfg:topofrom:desc {"From" des mails de topo}
 cfg:topofrom:help {Champ "From" des mails envoyés par le démon topod lors des détections de modification ou d'anomalie.}
 cfg:topoto:desc {Destinataire des mails de topo}
 cfg:topoto:help {Champ "To" des mails envoyés par le démon topod lors des détection de modification ou d'anomalie.}

 cfg:mac {Paramètres du module "MAC"}

 cfg:macactive:desc {Activation de Mac}
 cfg:macactive:help {Cocher cette case pour activer l'accès à la fonctionnalité "Mac"}

 cfg:auth {Paramètres d'authentification}

 cfg:authmailfrom:desc {Utiliser le "From" spécifié dans "auth"}
 cfg:authmailfrom:help {Utiliser l'information provenant de l'application "auth" plutôt que le champ suivant.}
 cfg:mailfrom:desc {"From" des mails de modification de passwd}
 cfg:mailfrom:help {Champ "From" des mails envoyés par l'application à un utilisateur lors des changements de mot de passe.}
 cfg:authmailreplyto:desc {Utiliser le "Reply-To" spécifié dans "auth"}
 cfg:authmailreplyto:help {Utiliser l'information provenant de l'application "auth" plutôt que le champ suivant.}
 cfg:mailreplyto:desc {"Reply-To" des mails de modification de passwd}
 cfg:mailreplyto:help {Champ "Reply-To" des mails envoyés par l'application à un utilisateur lors des changements de mot de passe.}
 cfg:authmailcc:desc {Utiliser le "Cc" spécifié dans "auth"}
 cfg:authmailcc:help {Utiliser l'information provenant de l'application "auth" plutôt que le champ suivant.}
 cfg:mailcc:desc {"Cc" des mails de modification de passwd}
 cfg:mailcc:help {Destinataire(s) auxiliaires des mail envoyés par l'application à un utilisateur lors des changements de mot de passe.  Cela peut éventuellement être une liste d'adresses, l'espace faisant office de séparateur.}
 cfg:authmailbcc:desc {Utiliser le "Bcc" spécifié dans "auth"}
 cfg:authmailbcc:help {Utiliser l'information provenant de l'application "auth" plutôt que le champ suivant.}
 cfg:mailbcc:desc {"Bcc" des mails de modification de passwd}
 cfg:mailbcc:help {Destinataire(s) caché(s) des mail envoyés par l'application à un utilisateur lors des changements de mot de passe.  Cela peut éventuellement être une liste d'adresses, l'espace faisant office de séparateur.}
 cfg:authmailsubject:desc {Utiliser le "Subject" spécifié dans "auth"}
 cfg:authmailsubject:help {Utiliser l'information provenant de l'application "auth" plutôt que le champ suivant.}
 cfg:mailsubject:desc {"Subject" des mails de moditication de passwd}
 cfg:mailsubject:help {Champ "Subject" des mails envoyés par l'application à un utilisateur lors des changements de mot de passe.}
 cfg:authmailbody:desc {Utiliser le corps spécifié dans "auth"}
 cfg:authmailbody:help {Utiliser l'information provenant de l'application "auth" plutôt que le champ suivant.}
 cfg:mailbody:desc {Corps du mail de modification de passwd}
 cfg:mailbody:help {Corps des mails envoyés par l'application à un utilisateur lors des changements de mot de passe. Les parameters suivants sont substitués: <ul><li>%1$s : login de l'utilisateur</li> <li>%2$s : mot de passe généré</li></ul>.}
 cfg:groupes:desc {Groupes Web autorisés}
 cfg:groupes:help {Liste de groupes (conformément à l'authentification Apache) autorisés pour la création d'un utilisateur.  Si la liste est vide, tous les groupes existants dans la base d'authentification sont autorisés.}
}

###############################################################################
# Library
::msgcat::mcmset fr {
 {Error accessing database (%s)} {Erreur d'accès à la base de données (%s)}
 {Connection refused (%s)} {Connexion refusée (%s)}
 {No login: authentication failed} {Pas de login : l'authentification a échoué}
 {User '%s' not authorized} {Utilisateur '%s' non autorisé}
 {Authentication base problem: %s} {Problème dans la base d'authentification : %s}
 {User '%s' is not in the authentication base} {L'utilisateur '%s' n'est pas dans la base d'authentification}
 {Found more than one entry for login '%s' in the authentication base} {Plus d'une entrée trouvée pour le login '%s' dans la base d'authentification}
 {User '%s' is not in the WebDNS base} {L'utilisateur '%s' n'est pas dans la base de WebDNS}
 {Invalid input} {Données invalides}

 {User}	{Utilisateur}
 {Login}	{Login}
 {Mail}	{Mél}
 {Phone}	{Tél fixe}
 {Mobile}	{Tél mobile}
 {Fax}	{Fax}
 {Address}	{Adresse}
 {Date}		{Date}
 {Interface}	{Interface}
 {Change}	{Modification}
 {Present}	{Présent}
 {Group}	{Groupe}
 {ERROR}	{ERREUR}

 {This host holds mail addresses} {Cette machine héberge des adresses de messagerie}
 {Internal error: '%s' inserted, but not found in database} {Erreur interne : '%s' inséré, mais non retrouvé dans la base}
 {RR addition impossible: %s} {Création du RR impossible : %s}
 {RR update impossible: %s} {Mise à jour du RR impossible : %s}

 {Name}		{Nom}
 {Domain}	{Domaine}
 {IP address}	{Adresse IP}
 {IP addresses}	{Adresses IP}
 {(none)}		{(aucune)}
 {MAC address}	{Adresse MAC}
 {DHCP profile}	{Profil DHCP}
 {Type}		{Type}
 {Yes}		{Oui}
 {No}		{Non}
 {Min}		{Min}
 {Max}		{Max}
 {IPv4}		{IPv4}
 {IPv6}		{IPv6}
 {SMTP emit right}	{Droit d'émission SMTP}
 {TTL}		{TTL}
 {Comment}		{Infos complémentaires}
 {Responsible (name)}	{Responsable (nom + prénom)}
 {Responsible (mail)}	{Responsable (mél)}
 {Aliases}		{Aliases}
 {Priority}	{Priorité}
 {MX}		{MX}
 {Submit} {Enregistrer}
 {Reset} {Réinitialiser}
 {Title}	{Intitulé}
 {Location}	{Localisation}
 {IPv4 address} {Adresse IPv4}
 {IPv4 gateway} {Passerelle IPv4}
 {IPv6 address} {Adresse IPv6}
 {IPv6 gateway} {Passerelle IPv6}
 {Organization} {Organisme}
 {DHCP enabled}	{DHCP activé}
 {Community}	{Commaunauté}
 {Prolog}	{Prologue}
 {Addtl RR}	{RR suppl.}
 {Criterium}	{Critère}
 {dhcpd.conf configuration}	{Directives dhcpd.conf}
 {Description}	{Description}
 {Vlan-Id}	{Vlan-id}
 {VoIP Vlan}	{Vlan VoIP}
 {Name and aliases} {Noms et aliases}
 {Host type}	{Type de machine}
 {Responsible}	{Responsable}
 {location} {localisation}
 {description} {description}
 {Declared addresses (IPv4+IPv6): %s} {Adresses déclarées (IPv4+IPv6) : %s}
 {List of declared addresses} {Liste des adresses déclarées}

 {Invalid FQDN '%s'}	{FQDN '%s' invalide}
 {Invalid domain '%s'}	{Domaine '%s' invalide}
 {Invalid name '%s'}	{Nom '%s' invalide}
 {'%1$s' is not a valid IPv%2$s address} {'%1$s' n'est pas une adresse IPv%2$s valide}
 {The '/' character is not valid in the address '%s'} {Le caractère '/' est interdit dans l'adresse '%s'}
 {Invalid syntax for '%s'} {Syntaxe invalide pour '%s'}
 {Invalid syntax for DHCP profile} {Syntaxe invalide pour le profil DHCP}
 {No profile} {Aucun profil}

 {Internal error: invalid context '%s'} {Erreur interne : contexte '%s' invalide}
 {'%1$s' is an alias of '%2$s'} {'%1$s' est un alias de '%2$s'}
 {You don't have rights on '%s'} {Vous n'avez pas les droits sur '%s'}
 {Internal error: invalid parameter '%1$s' for '%2$s'} {Erreur interne : paramètre invalide '%$1s' pour '%2$s'}
 {'%s' is a MX} {'%s' est un MX}
 {'%s' is a mail role} {'%s' est un rôle de messagerie}
 {Internal error: id '%s' doesn't exists for a mail host} {Erreur interne : hébergeur d'id '%s' inexistant}
 {You don't have rights on host holding mail for '%s'} {Vous n'avez pas les droits sur l'hébergeur de '%s'}
 {'%s' is a mail host for mail domains} {'%s' est un hébergeur pour des adresses de messagerie}
 {'%s' has IP addresses} {'%s' a des adresses IP}
 {Name '%s' is not a host} {Le nom '%s' ne correspond pas à une machine}
 {Name '%s' does not exist} {Le nom '%s' n'existe pas}
 {Domain '%s' not found} {Domaine '%s' non trouvé}
 {Domain-id '%s' not found} {Identificateur de domaine '%s' non trouvé}
 {MX '%1$s' points to a domain on which you don't have rights\n%2$s} {Le MX '%1$s' référence un domaine auquel vous n'avez pas accès\n%2$s}
 {Invalid MX priority '%1$s' for '%2$s'} {Priorité de MX non valide '%1$s' pour '%2$s'}
 {You don't have rights to some relays of domain '%1$s': %2$s} {Vous n'avez pas les droits sur certains relais du domaine '%1$s' : %2$s}
 {Internal error on '%1$s': id '%2$s' of mail host not found} {Erreur interne sur '%1$s' : id de l'hébergeur '%2$s' non trouvé}
 {Impossible to use MAC address '%1$s' because IP address '%2$s' is in DHCP dynamic range [%3$s..%4$s]} {Impossible d'affecter l'adresse MAC '%1$s' car l'adresse IP '%2$s' figure dans l'intervalle DHCP dynamique [%3$s..%4$s]}
 {Invalid TTL: must be a positive integer} {TTL invalide : doit être un nombre entier positif}
 {Invalid TTL: must be less than %s} {TTL invalide : doit être inférieur à %s}
 {Invalid group name '%s' (allowed chars: letters, digits and minus symbol)} {Nom de groupe '%s' invalide (caractères autorisés : lettres, chiffres et caractère moins)}
 {DHCP profile} {Profil DHCP}
 {Use SMTP} {Émettre en SMTP}
 {TTL} {TTL}
 { (in seconds)} { (en secondes)}
 {Sorry, but you do not have any active domain} {Désolé, mais vous n'avez aucun domaine actif}
 {No profile} {Aucun profil}
 {yes}		{oui}
 {no}		{non}
 {WebDNS administration} {Administration de WebDNS}
 {SMTP authorizations management} {Gestion des émetteurs SMTP}
 {TTL management} {Gestion du TTL}
 {MAC module access} {Accès au module MAC}
 {Error on group permissions} {Erreur sur les droits du groupe}
 {Range} {Plage}
 {Community} {Communauté}
 {Permissions} {Droits}
 {No allowed network} {Aucun réseau autorisé}
 {None (it's all right)} {Aucun (tout va bien)}
 {Mail role management} {Édition des rôles de messagerie}
 {Web role management} {Édition des rôles Web}
 {No allowed domain} {Aucun domaine autorisé}
 {No allowed DHCP profile} {Aucun profil DHCP autorisé}
 {Read} {Lecture}
 {Write} {Modification}
 {No permission} {Aucun droit}
 {Invalid network id '%s'} {Plage réseau '%s' invalide}
 {You cannot read this network} {Vous n'avez pas accès à ce réseau en consultation}
 {You do not have DHCP access to this network} {Vous n'avez pas accès à ce réseau pour DHCP}
 {You do not have ACL access to this network} {Vous n'avez pas accès à ce réseau pour définir des ACL}
 {Internal error: invalid tabular specification} {Erreur interne : spécification de tableau invalide}
 {Unable to lock table (%s)} {Verrouillage impossible (%s)}
 {Unable to lock database: %s)} {Verrouillage impossible : %s}
 {Error deleting '%1$s' (%2$s)} {Erreur dans la suppression de '%1$s' (%2$s)}
 {Error modifying '%1$s' (%2$s)} {Erreur dans la modification de '%1$s' (%2$s)}
 {Error adding '%1$s' (%2$s)} {Erreur dans l'ajout de '%1$s': %2$s}
 {Unable to commit, modification cancelled (%s)} {Déverrouillage impossible, modification annulée (%s)}

 {Unknown configuration key '%s'} {Clef de configuration '%s' inconnue}
 {Cannot set key '%1$s' to '%2$s: %3$s} {Impossible de modifier la clef '%1$s' à '%2$s' : %3$s}
 {Cannot fetch key '%1$s': %3$s} {Impossible de lire la clef '%1$s' : %2$s}

 {No message from anaconf} {Aucun message provenant d'anaconf}
 {(no date)} {(aucune date)}
 {Topod messages} {Messages de topod}
 {... since %s} {... depuis %s}
 {Cannot read sensor list: %s} {Impossible de lire les points de collecte : %s}
 {Divergent sensor types} {Types de points de collecte divergents}
 {Sensor '%s' not found} {Point de collecte '%s' non trouvé}
 {No sensor selected} {Aucun point de collecte sélectionné}
 {Traffic on vlan %1$s of interface %2$s of %3$s} {Trafic sur le vlan %1$s de l'interface %2$s de %3$s}
 {Traffic on interface %2$s of %3$s} {Trafic sur l'interface %2$s de %3$s}
 {Number of auhentified users on ssid %1$s of interface %2$s of %3$s} {Nombre d'utilisateurs authentifiés sur le ssid %1$s de l'interface %2$s de %3$s}
 {Number of associated hosts on ssid %1$s of interface %2$s of %3$s} {Nombre de machines associées sur le ssid %1$s de l'interface %2$s de %3$s}
 {Traffic on interfaces %s} {Trafic sur les interfaces %s}
 {Number of auhentified users on %s} {Nombre d'utilisateurs authentifiés sur %s}
 {Number of associated hosts on %s} {Nombre de machines associées sur %s}
 {Internal error: invalid extractcoll output format} {Erreur interne : format de sortie de extractcoll non valide}
 {No access: %s} {Accès impossible: %s}
 {Error during extraction of readable interfaces from '%1$s' (%2$s)} {Erreur lors de l'extraction des interfaces consultables de '%1$s' : %2$s}
 {Error during extraction of writable interfaces from '%1$s' (%2$s)} {Erreur lors de l'extraction des interfaces modifiables de '%1$s' : %2$s}
 {Equipment '%s' not found} {Équipement '%s' non trouvé}
 {description='%s'} {description='%s'}
 {vlan='%s'} {vlan='%s'}
 {voip='%s'} {voip='%s'}
 {deactivated interface} {interface désactivée}
 {Changes currently processed:} {Modification(s) en cours de traitement :}
 {Graph currenty re-builded. Informations presented here are not necessarily consistent with current equipement configuration.} {Reconstruction du graphe en cours. Les informations fournies ne sont pas forcément cohérentes avec la configuration actuelle des équipements.}
}

###############################################################################
# CGI Scripts
::msgcat::mcmset fr {
 {Error for zone '%1$s': %2$s} {Échec pour la zone '%1$s' : %2$s}
 {Operation failed (%s). Abort.} {L'opération a échoué (%s). Abandon.}
 {Insertion failed (%s). Abort.} {L'insertion a échoué (%s). Abandon.}

 {New group creation} {Création d'un nouveau groupe}
 {Type the name of group to create} {Entrez le nom du groupe à créer}
 {Edition of group '%s'} {Édition du groupe '%s'}
 {Modify group name or erase it to remove the group} {Modifiez le nom du groupe ou effacez-le pour supprimer le groupe}
 {Group '%s' not found} {Groupe '%s' non trouvé}
 {Group has access to domain '%s' which do not exists in database} {Le groupe a accès au domaine '%s' qui n'existe pas dans la base}
 {Group has access to network '%s' which do not exists in database} {Le groupe a accès au réseau '%s' qui n'existe pas dans la base}
 {yes} {oui}
 {no} {non}
 {Sort class} {Classe de tri}
 {DHCP management} {Gestion DHCP}
 {ACL management} {Gestion des ACL}
 {Group have access to DHCP profile '%s' which do not exist in the database} {Le groupe a accès au profil '%s' qui n'existe pas dans la base}
 {Group '%s' already exist} {Le groupe '%s' existe déjà}
 {You must type a name for the group} {Il faut saisir un nom pour ce groupe}
 {Creation of group %s} {Création du groupe %s}
 {Login '%s' does not exist} {Le login '%s' n'existe pas}
 {Login '%s' found more than once} {Le login '%s' est ambigu}
 {Modification of group %s} {Modification du groupe %s}
 {Mail role edition} {Édition des rôles de messagerie}
 {Web role edition} {Édition des rôles de Web}
 {Unable to remove group: %s} {Suppression du groupe impossible : %s}
 {Invalid value '%1$s' for form variable '%2$s'} {Valeur '%1$s' invalide pour le champ de formulaire '%2$s'}
 {Login '%1$s' already assigned to group '%2$s'} {Login '%1$s' déjà affecté au groupe '%2$s'}
 {Invalid domain sort class '%s'} {Classe de tri de domaine '%s' invalide}
 {Invalid mail role '%s'} {Role mail invalide '%s'}
 {Invalid web role '%s'} {Role web invalide '%s'}
 {Invalid network sort class '%s'} {Classe de tri de réseau '%s' invalide}
 {Invalid DHCP permission '%s'} {Droit DHCP invalide '%s'}
 {Invalid ACL permission '%s'} {Droit ACL invalide '%s'}
 {Invalid value '%s' for allow/deny} {Valeur '%s' incorrecte pour allow/deny}
 {Invalid CIDR '%s'} {CIDR '%s' incorrect}
 {Invalid value '%s' for read/write} {Valeur '%s' incorrecte pour read/write}
 {Invalid regular expression pattern '%s'} {Motif d'expression régulière '%s' invalide}
 {Invalid DHCP profile sort class '%s'} {Classe de tri de profil DHCP '%s' invalide}
 {Invalid DHCP profile '%s'} {Profil DHCP '%s' invalide}
 {No selected domain} {Aucun domaine sélectionné}
 {No selected network} {Aucun réseau sélectionné}
 {Network '%s' is not DHCP enabled} {Le réseau '%s' n'a pas la capacité DHCP}
 {No 'allow' permission found for network '%s'} {Aucun droit 'allow' trouvé pour le réseau '%s}
 {'Allow' permission '%s' is too large} {Le droit 'allow - %s' est trop grand}
 {Internal error: group '%s' not found} {Erreur interne : groupe '%s' non trouvé}
 {Create group...} {Créer un groupe...}
 {'%s' already has IP addresses} {'%s' a déjà des adresses IP}
 {'%s' is an alias} {'%s' est un alias}
 {Internal error: rr_mx table references RR '%s', not found in the rr table} {Erreur interne : table rr_mx référence le RR '%s', non trouvé dans la table rr}
 {MX insertion failed: %s} {Insertion du MX impossible : %s}
 {'%s' specified more than once} {'%s' spécifié plus d'une fois}
 {Invalid form values (%s)} {Valeurs de formulaire invalides (%s)}
 {Old MX deletion failed: %s} {Suppression des anciens MX impossible : %s}
 {Deletion of RR '%1$s' failed: %2$s} {Suppression du RR '%1$s' impossible : %2$s}
 {No MX creation for '%s'} {Pas de création de MX pour '%s'}
 {Addition or RR '%1$s' failed: %2$s} {Ajout du RR '%1$s' impossible : %2$s}
 {Unlock failed, modification failed: %s} {Déverrouillage impossible, modification annulée : %s}
 {RR deleted} {RR supprimé}
 {Internal error: invalid key type '%s'} {Erreur interne : type de clef invalide '%s'}
 {Store parameter '%1$s' failed: %2$s} {Enregistrement du paramètre '%1$s' impossible : %2$s}
 {return to application parameter modification} {revenir à la modification des paramètres de l'application}
 {Type '%s' not supported} {Type '%s' non supporté}
 {Organization management} {Gestion des organismes}
 {Community management} {Gestion des communautés}
 {Host type management} {Gestion des types de machines}
 {Network management} {Gestion des réseaux}
 {Domain management} {Gestion des domaines}
 {Zone management} {Gestion des zones}
 {DHCP profile management} {Gestion des profils DHCP}
 {Vlan management} {Gestion des Vlans}
 {return to organization modification} {revenir à la modification des organismes}
 {return to community modification} {revenir à la modification des communautés}
 {return to host information modification} {revenir à la modification des types de machines}
 {return to network modification} {revenir à la modification des réseaux}
 {return to domain modification} {revenir à la modification des domaines}
 {return to zone modification} {revenir à la modification des zones}
 {return to DHCP profile modification} {revenir à la modification des profils DHCP}
 {return to Vlan modification} {revenir à la modification des Vlans}
 {Relay insertion failed: %s} {Insertion du relais impossible : %s}
 {Old relay deletion failed: %s} {Suppression des anciens relais impossible : %s}
 {Mail relays deleted} {Relais de messagerie supprimés}
 {No authorized network} {Aucun réseau autorisé}
 {Host '%s' not found} {Machine '%s' non trouvée}
 {No default domain} {Pas de domaine par défaut}
 {Invalid search criterium '%s'} {Critère de recherche '%s' invalide}
 {Internal error: object pointed by alias is not found} {Erreur interne : l'objet pointé par l'alias n'est pas trouvé}
 {Internal error: mail host of role mail not found} {Erreur interne : hébergeur du rolemail non trouvé}
 {Internal error: no IP address} {Erreur interne : pas d'adresse IP}
 {Searched address: %s} {Adresse recherchée : %s}
 {You don't have access to any DHCP enabled network} {Vous n'avez accès à aucun réseau avec le droit DHCP}
 {Internal error: too many CIDR found} {Erreur interne : trop de CIDR trouvés}
 {Default lease duration} {Durée par défaut du bail}
 {Maximum lease duration} {Durée maximum du bail}
 {You don't have access to DHCP range id '%s'} {Vous n'avez pas accès à l'intervalle DHCP d'id '%s'}
 {Invalid default_lease_time value '%s'} {Valeur default_lease_time '%s' invalide}
 {Default_lease_time value less than '%s'} {Valeur default_lease_time inférieure à '%s'}
 {Invalid max_lease_time value '%s'} {Valeur max_lease_time '%s' invalide}
 {Max_lease_time value less than '%s'} {Valeur max_lease_time inférieure à '%s'}
 {Range [%s] not authorized} {Intervalle [%s] non autorisé}
 {Conflict between dynamic range [%1$s] and %2$s IP address(es) declared with a MAC address} {Conflit entre l'intervalle dynamique [%1$s] et %2$s adresse(s) IP déclée(s) avec une adresse MAC}
 {Range [%1$s] intersects with range [%2$s]} {L'intervalle [%1$s] a une intersection non nulle avec l'intervalle [%2$s]}
 {Permissions not associated with any network} {Droits non rattachés à des réseaux}
 {Address '%s' do not exists in database} {L'adresse '%s' n'existe pas dans la base}
 {sums} {cumuls}
 {detail/SSID} {détail/SSID}
 {detail/AP} {détail/AP}
 {Inconsistent permissions on interfaces: %s} {Droits d'accès incohérents pour les interfaces : %s}
 {Equipment} {Équipement}
 {Vlan} {Vlan}
 {location}	{localisation}
 {channel %1$s power %2$s mW}	{canal %1$s puissance %2$s mW}
 {to} {vers}
 {Edit} {Modifier}
 {no description} {pas de description}
 {native vlan} {vlan natif}
 {Traffic} {Trafic}
 {SSID %s } {SSID %s }
 {Sum assoc} {Cumul assoc}
 {Sum auth} {Cumul auth}
 {Detail assoc} {Détail assoc}
 {Detail auth} {Détail auth}
 {assoc} {assoc}
 {auth} {auth}
 {Edit interfaces} {Modifier les interfaces}
 {Error while reading equipments: %s} {Erreur lors de la lecture des équipements : %s}
 {Error while reading wifi sensors: %s} {Erreur lors de la lecture des sondes Wifi : %s}
 {Error while reading Vlans: %s} {Erreur lors de la lecture des Vlans : %s}
 {Error while reading networks: %s} {Erreur lors de la lecture des réseaux : %s}
 {No equipment found} {Aucun équipement trouvé}
 {equipments} {équipements}
 {develop} {tout dérouler}
 {envelop} {tout enrouler}
 {Invalid period '%s'} {Période '%s' invalide}
 {Invalid date '%s'} {Date '%s' invalide}
 {Invalid graph size '%s'} {Taille du graphe invalide '%s'}
 {Shutdown interface} {Désactiver le port}
 {Shutdown VoIP on this interface} {Désactiver la VoIP sur ce port}
 {Interface '%1$s' not found on %2$s} {L'interface '%1$s' n'est pas trouvée sur %2$s}
 {You can't modify interface %1$s on %2$s} {Vous ne pouvez pas modifier l'interface %1$s sur %2$s}
 {Edit interface %1$s on %2$s} {Modification de l'interface %1$s sur %2$s}
 {You can also <a href="%s">edit more than one interfaces</a> simultaneously} {Vous pouvez également <a href="%s">modifier plusieurs interfaces</a> simultanément}
 {authorized special characters: -+/()&.:#_} {caractères spéciaux autorisés : -+/()&.:#_}
 {VoIP} {VoIP}
 {Sensors} {Sondes}
 {Edit interfaces on %s} {Modification des interfaces de %s}
 {Interfaces} {Interfaces}
 {More than 6 months} {Plus de 6 mois}
 {More than 9 months} {Plus de 9 mois}
 {More than one year} {Plus d'un an}
 {Invalid occurrence '%s'} {Occurrence '%s' invalide}
 {Last occurrence} {Dernière occurrence}
 {Inactive hosts in network %1$s since more than %2$s months: } {Machines inactives dans le réseau %1$s depuis plus de %2$s mois : }
 {%s inactive hosts} {%s machines inactives}
 {no inactive host found} {aucune machine inactive trouvée}
 {Vlan %1$s: %2$s} {Vlan %1$s : %2$s}
 {Vlan '%s' not found on equipments} {Vlan '%s' non trouvé sur les équipements}
 {Invalid router instance '%s'} {Instance de routage '%s' invalide}
 {Invalid node type '%1$s' for %2$s} {Type de noeud '%1$s' invalide pour %2$s}
 {IP networks} {réseaux IP}
 {No valid CIDR: %s} {Aucun CIDR valide : %s}
 {Error in CIDR '%1$s': %2$s} {Erreur dans le CIDR '%1$s' : %2$s}
 {Internal error for '%1$s': avail=%2$s} {Erreur interne pour '%1$s' : avail=%2$s}
 {Network '%s'} {Réseau '%s'}
 {%1$s available addresses / %2$s total} {%1$s adresses disponibles / %2$s total}
 {Detail} {Détail}
 {address not allowed} {adresse non accessible}
 {available address} {adresse disponible}
 {declared address} {adresse déclarée}
 {non-declared address within a DHCP range} {adresse non déclarée, figurant dans un intervalle DHCP}
 {declared address, within a DHCP range} {adresse déclarée, figurant dans un intervalle DHCP}
 {IPv4 address map} {Carte des adresses IPv4}
 {You must choose a CIDR or at least one network} {Vous devez choisir un CIDR ou au moins une plage}
 {You can not choose both a CIDR and a network} {Vous ne pouvez pas choisir un CIDR et une plage}
 {List of users} {Liste des utilisateurs}
 {(no MX for this domain)} {(pas de MX pour ce domaine)}
 {CIDR matches '%s'} {CIDR correspond à '%s'}
 {Organization id '%s' not found} {L'organisme d'id '%s' n'est pas trouvé}
 {Community id '%s' not found} {La communauté d'id '%s' n'est pas trouvée}
 {organization = %s} {organisme = %s}
 { or } { ou }
 {community = %s} {communauté = %s}
 {List of networks filtered by: } {Liste des réseaux filtrés par : }
 { (no filter) } { (aucun filtre) }
 {and sorted by '%1$s' and by '%2$s'} {et triés par '%1$s' et par '%2$s'}
 {%s selected network(s).} {%s réseau(x) sélectionné(s).}
 {networks} {réseaux}
}
