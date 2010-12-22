#
# WebDNS translation messages
#

###############################################################################
# Configuration parameters
::msgcat::mcmset en {
 cfg:general {General parameters}

 cfg:datefmt:desc {Date/hour display format}
 cfg:datefmt:help {Date and time display format, used in data display and data editing. See Tcl clock(n) manual page for format specification.}
 cfg:jourfmt:desc {Date display format}
 cfg:jourfmt:help {Date display format (without hours). See Tcl clock(n) manual page for format specification.}
 cfg:authmethod:desc {Authentication method}
 cfg:authmethod:help {Authentication method is based on a directory where to find people information (name, address, etc.)}

 cfg:dns {DNS parameters}

 cfg:dnsupdateperiod:desc {DNS update period}
 cfg:dnsupdateperiod:help {Duration between DNS zone generations on the DNS server (should be kept in sync with the associated CRON period)}
 cfg:defuser:desc {Default user}
 cfg:defuser:help {Default user is used in WebDNS command line programs, when the user's login is not found in the WebDNS database}

 cfg:dhcp {DHCP parameters}

 cfg:default_lease_time:desc {default_lease_time}
 cfg:default_lease_time:help {Value in seconds, for DHCP parameter "default_lease_time" used in the dynamic range generation. This value is used if the range specific parameter is null.}
 cfg:max_lease_time:desc {max_lease_time}
 cfg:max_lease_time:help {Value in seconds, for DHCP parameter "max_lease_time" used in the dynamic range generation. This value is used if the range specific parameter is null.}
 cfg:min_lease_time:desc {min_lease_time}
 cfg:min_lease_time:help {Minimum value for DHCP parameters in dynamic ranges. The goal of this value is to avoid that a user specifies a too short lease duration and thus generates an important DHCP traffic.}

 cfg:topo {"Topo" module parameters}

 cfg:topoactive:desc {Topo module activation}
 cfg:topoactive:help {Check this box to activate the "Topo" module.}
 cfg:defdomain:desc {Default domain}
 cfg:defdomain:help {Default domain name, since some equipments do not report FQDNs}
 cfg:topofrom:desc {Topo mail sender}
 cfg:topofrom:help {"From" header of mails sent by the topod daemon when it detects modifications or abnormalities.}
 cfg:topoto:desc {Topo mail receiver}
 cfg:topoto:help {"To" header of mails sent by the topod daemon when it detects modifications or abnormalities.}
 cfg:topographddelay:desc {Topographd loop delay}
 cfg:topographddelay:help {Time (in seconds) between each main loop iteration in topographd daemon. Example: 5}
 cfg:toposendddelay:desc {Toposendd loop delay}
 cfg:toposendddelay:help {Time (in seconds) between each main loop iteration in toposendd daemon. Example: 5}
 cfg:topomaxstatus:desc {Max status lines}
 cfg:topomaxstatus:help {Maximum number of status lines kept in database. Example: 100}
 cfg:sensorexpire:desc {Sensor expiration time}
 cfg:sensorexpire:help {Delay (in days) before sensor expiration. Example: 30}
 cfg:modeqexpire:desc {Equipment modifications expiration time}
 cfg:modeqexpire:help {Delay (in days) before expiring "detected equipment modifications" in database. Example: 30}
 cfg:ifchangeexpire:desc {Interface changes expiration time}
 cfg:ifchangeexpire:help {Delay (in days) before expiring "interface changes" in database. Example: 30}
 cfg:fullrancidmin:desc {Min fullrancid start hour}
 cfg:fullrancidmin:help {Minimum start hour (0..24) for the daily full-rancid operations. Example: 2}
 cfg:fullrancidmax:desc {Max fullrancid start hour}
 cfg:fullrancidmax:help {Maximum start hour (0..24) for the daily full-rancid operations. Example: 4}

 cfg:mac {"MAC" module parameters}

 cfg:macactive:desc {MAC module activation}
 cfg:macactive:help {Check this box to activate the "MAC" module.}

 cfg:authldap {LDAP authentication parameters}

 cfg:ldapurl:desc {LDAP server}
 cfg:ldapurl:help {URL to access LDAP server. Example: ldaps://ldap.domaine.fr:636/}
 cfg:ldapbinddn:desc {Bind DN}
 cfg:ldapbinddn:help {Bind DN to authenticate against LDAP server. Example : cn=admin,dc=mycompany,dc=com}
 cfg:ldapbindpw:desc {Bind password}
 cfg:ldapbindpw:help {Password to authenticate against LDAP server}
 cfg:ldapbasedn:desc {Base DN}
 cfg:ldapbasedn:help {Base DN for people searches. Example: ou=people,dc=domaine,dc=fr}
 cfg:ldapsearchlogin:desc {User search request}
 cfg:ldapsearchlogin:help {LDAP request to search for an user using the login name. Example: "(&(objectClass=inetOrgPerson)(uid=%s))"}
 cfg:ldapattrlogin:desc {Attribute "login"}
 cfg:ldapattrlogin:help {LDAP attribute to get login name. Example: "uid"}
 cfg:ldapattrpassword:desc {Attribute "password"}
 cfg:ldapattrpassword:help {LDAP attribute to get encrypted password. Example: "userPassword"}
 cfg:ldapattrname:desc {Attribute "nom"}
 cfg:ldapattrname:help {LDAP attribute to get user's name. Example: "sn"}
 cfg:ldapattrgivenname:desc {Attribute "first name"}
 cfg:ldapattrgivenname:help {LDAP attribute to get user's first name. Attributes may be empty or made from one or more LDAP attributes which will be joined together}
 cfg:ldapattrmail:desc {Attribute "mail addresse"}
 cfg:ldapattrmail:help {LDAP attribute to get user's mail address. Example: "mail". Attributes may be empty or made from one or more LDAP attributes which will be joined together}
 cfg:ldapattrphone:desc {Attribute "telephone number"}
 cfg:ldapattrphone:help {LDAP attribute to get user's telephone number. Example: "telephoneNumber". Attributes may be empty or made from one or more LDAP attributes which will be joined together}
 cfg:ldapattrmobile:desc {Attribute "mobile phone"}
 cfg:ldapattrmobile:help {LDAP attribute to get user's mobile phone number. Example: "". Attributes may be empty or made from one or more LDAP attributes which will be joined together}
 cfg:ldapattrfax:desc {Attribute "facsimile"}
 cfg:ldapattrfax:help {LDAP attribute to get user's facsimile number. Example: "facsimileTelephoneNumber". Attributes may be empty or made from one or more LDAP attributes which will be joined together}
 cfg:ldapattraddr:desc {Attribute "address"}
 cfg:ldapattraddr:help {LDAP attribute to get user's postal address. Example: "postalAddress postalCode l". Attributes may be empty or made from one or more LDAP attributes which will be joined together}

 cfg:authpgsql {Internal authentication parameters}

 cfg:authmailfrom:desc {Use the "From" specified in "auth"}
 cfg:authmailfrom:help {Use the information from the "auth" application, rather than the next parameter in this list.}
 cfg:mailfrom:desc {Sender of mails when a password change}
 cfg:mailfrom:help {"From" header of mails sent by the application to an user when a password change occurs.}

 cfg:authmailreplyto:desc {Use the "Reply-To" specified in "auth"}
 cfg:authmailreplyto:help {Use the information from the "auth" application, rather than the next parameter in this list.}
 cfg:mailreplyto:desc {"Reply-To" of mails when a password change}
 cfg:mailreplyto:help {"Reply-To" header of mails sent by the application to an user when a password change occurs.}

 cfg:authmailcc:desc {Use the "Cc" specified in "auth"}
 cfg:authmailcc:help {Use the information from the "auth" application, rather than the next parameter in this list.}
 cfg:mailcc:desc {"Cc" of mails when a password change}
 cfg:mailcc:help {"Cc" header of mails sent by the application to an user when a password change occurs.. This may be an address list, separated by spaces.}

 cfg:authmailbcc:desc {Use the "Bcc" specified in "auth"}
 cfg:authmailbcc:help {Use the information from the "auth" application, rather than the next parameter in this list.}
 cfg:mailbcc:desc {"Bcc" of mails when a password change}
 cfg:mailbcc:help {"Bcc" header of mails sent by the application to an user when a password change occurs.. This may be an address list, separated by spaces.}

 cfg:authmailsubject:desc {Use the "Subject" specified in "auth"}
 cfg:authmailsubject:help {Use the information from the "auth" application, rather than the next parameter in this list.}
 cfg:mailsubject:desc {"Subject" of mails when a password change}
 cfg:mailsubject:help {"Subject" header of mails sent by the application to an user when a password change occurs.}

 cfg:authmailbody:desc {Use the body specified in "auth"}
 cfg:authmailbody:help {Use the information from the "auth" application, rather than the next parameter in this list.}
 cfg:mailbody:desc {Body of mails when a password change}
 cfg:mailbody:help {Body of mails sent by the application to an user when a password change occurs. Following parameters are substitued: '%1$s'=login, '%2$s'=generated password.}

 cfg:groupes:desc {Authorized Web groups}
 cfg:groupes:help {List of groups (according to Apache daemon authentication) authorized to create an user. If the list is empty, all existing groups are authorized.}
}
