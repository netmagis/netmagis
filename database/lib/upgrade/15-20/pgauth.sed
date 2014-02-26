s/COPY utilisateurs/COPY pgauth.user/
s/COPY membres (login, groupe)/COPY pgauth.member (login, realm)/
s/COPY groupes (groupe, descr)/COPY pgauth.realm (realm, descr)/
s/COPY config/COPY global.config/
s/^mailfrom/authpgmailfrom/
s/^mailreplyto/authpgmailreplyto/
s/^mailcc/authpgmailcc/
s/^mailbcc/authpgmailbcc/
s/^mailsubject/authpgmailsubject/
s/^mailbody/authpgmailbody/
