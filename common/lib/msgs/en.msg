#
# WebDNS translation messages
#

###############################################################################
# Configuration parameters
::msgcat::mcmset en {
 cfg:dns {General parameters}

 cfg:datefmt:desc {Date/hour display format}
 cfg:datefmt:help {Date and time display format, used in data display and data editing. See Tcl clock(n) manual page for format specification.}
 cfg:jourfmt:desc {Date display format}
 cfg:jourfmt:help {Date display format (without hours). See Tcl clock(n) manual page for format specification.}
 cfg:defuser:desc {Default user}}
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
 cfg:topofrom:desc {Topo mail sender}
 cfg:topofrom:help {"From" header of mails sent by the topod daemon when it detects modifications or abnormalities.}
 cfg:topoto:desc {Topo mail receiver}
 cfg:topoto:help {"To" header of mails sent by the topod daemon when it detects modifications or abnormalities.}

 cfg:mac {"MAC" module parameters}

 cfg:macactive:desc {MAC module activation}
 cfg:macactive:help {Check this box to activate the "MAC" module.}

 cfg:auth {Authentication parameters}

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
