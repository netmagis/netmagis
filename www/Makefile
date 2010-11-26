#
# Makefile pour lancer l'installation de l'application dns
#
#

TCLSH	= /usr/local/bin/tclsh8.5

#DEBUG   = 1
DEBUG  = 0

BASE    = {host=dbcrc.u-strasbg.fr dbname=dns user=dns password=mot-de-passe-de-dns}
AUTH    = {-method postgresql -db {host=dbcrc.u-strasbg.fr dbname=auth user=auth password=mot-de-passe-de-auth}}
LOG     = {dns postgresql {table log host dbcrc dbname dns user dns password mot-de-passe-de-dns}}
# AUTH	= {-method ldap -db {url ldap://ldap.domaine.fr binddn cn=admin,dc=domaine,dc=fr bindpw mot-de-passe-ldap base ou=people,dc=domaine,dc=fr searchuid (\&(objectClass=inetOrgPerson)(uid=%s))} -attrmap {login uid password userPassword nom sn prenom givenName mel mail tel telephoneNumber mobile {} fax facsimileTelephoneNumber adr {postalAddress postalCode l}}}
HOMEURL	= /applis/dns
NOLOGIN	= /local/etc/nologin.dns
MODLHTG	= webdns

#BASE     = {dbname=devdns user=dns password=mot-de-passe-de-dns}
#AUTH     = {postgresql {dbname=auth user=auth password=mot-de-passe-de-auth}}
#LOG      = {devdns postgresql {table log host dbcrc dbname devdns user dns password mot-de-passe-de-dns}}
#HOMEURL  = /applis/devdns
#NOLOGIN  = /local/etc/nologin.devdns

# utilisateur par défaut pour les scripts non web
DEFUSER	= crc

DESTDIR	= /local/services/www$(HOMEURL)
PKGTCL	= /local/services/www/pkgtcl

HTG	= /local/services/www/htg/bin/htg
MODLHTG = default

ROOT	= {pda jean}


# Intervalle entre deux générations de zones
INTERVALLE = 10
# Page présentant les DNS Osiris
DOCDNS	= /osiris/services/dns.html

# Couleur de fond des boutons "valider"
COULEUR = "\#10C090"

DEFDOM  = u-strasbg.fr

TOPODIR	= /local/applis/topo
GRAPH	= $(TOPODIR)/osiris/osiris.graph
STATUS	= $(TOPODIR)/osiris/osiris.status
IDRHOST	= metro.u-strasbg.fr

NEATO	= /usr/local/bin/neato
DOT	= /usr/local/bin/dot
# le problème avec ps2pdf, c'est qu'il appelle plein de scripts dans /usr/local
PS2PDF	= sh $(DESTDIR)/lib/ps2pdf

# Version de l'application
VERSION = 1.5

# URL pour modifier le mot de passe
PASSWDURL = https://www-crc.u-strasbg.fr/applis/passwd/bin/passwd

#
# Motif de substitution à appliquer à chaque fichier installé
#

SUBST	= \
	-e 's|%TCLSH%|$(TCLSH)|' \
	-e 's|%DEBUG%|$(DEBUG)|' \
	-e 's|%DESTDIR%|$(DESTDIR)|' \
	-e 's|%PKGTCL%|$(PKGTCL)|' \
	-e 's|%HOMEURL%|$(HOMEURL)|' \
	-e 's|%INTERVALLE%|$(INTERVALLE)|' \
	-e 's|%DOCDNS%|$(DOCDNS)|' \
	-e 's|%VERSION%|$(VERSION)|' \
	-e 's|%ROOT%|$(ROOT)|' \
	-e 's|%NOLOGIN%|$(NOLOGIN)|' \
	-e 's|%DEFUSER%|$(DEFUSER)|' \
	-e 's|%DEFDOM%|$(DEFDOM)|' \
	-e 's|%COULEUR%|$(COULEUR)|' \
	-e 's|%AUTH%|$(AUTH)|' \
	-e 's|%PASSWDURL%|$(PASSWDURL)|' \
	-e 's|%BASE%|$(BASE)|' \
	-e 's|%TOPODIR%|$(TOPODIR)|' \
	-e 's|%GRAPH%|$(GRAPH)|' \
	-e 's|%STATUS%|$(STATUS)|' \
	-e 's|%DEFUSER%|$(DEFUSER)|' \
	-e 's|%NEATO%|$(NEATO)|' \
	-e 's|%DOT%|$(DOT)|' \
	-e 's|%PS2PDF%|$(PS2PDF)|' \
	-e 's|%IDRHOST%|$(IDRHOST)|'

EXCL = \./doc|\.svn

#
# La documentation (succinte) de l'application
#

#IMAGES	= dns.gif mcd-dns.gif
IMAGES	= mcd-dns.gif

#
# Les cibles
#

#all: pre dirs autres gif html exec divers
all: pre dirs autres html exec divers

pre:
	rm -rf $(DESTDIR)/*

dirs:
	if [ ! -d $(DESTDIR) ] ; then mkdir $(DESTDIR) ; fi
	find . -type d -print | \
	    egrep -v "$(EXCL)" | \
	    while read d ; do \
		if [ ! -d $(DESTDIR)/$$d ] ; then mkdir -p $(DESTDIR)/$$d ; fi ; \
	    done

autres:
	find . \( -type f -o -type l \) -print | \
	    egrep -v "$(EXCL)" | \
	    grep -v '.htgt$$' | \
	    grep -v '.gif$$' | \
	    grep -v '.svn' | \
	    grep -v Makefile | \
	    while read f ; do \
		echo $$f ; \
		sed $(SUBST) $$f > $(DESTDIR)/$$f ; \
	    done

gif:	$(IMAGES)
	cp $(IMAGES) $(DESTDIR)

#dns.gif: dns.fig
#	fig2dev -Lgif dns.fig > dns.gif
#

mcd-dns.gif: mcd-dns.fig
	fig2dev -Lgif mcd-dns.fig > mcd-dns.gif

html:
	find . -name "*.htgt" -print | \
	    grep -v '/\.svn/' | \
	    while read f ; do \
		h=`echo $$f | sed 's/.htgt$$//'` ; \
		echo $$f ; \
		$(HTG) -m $(MODLHTG) $$f | \
		    sed $(SUBST) > $(DESTDIR)/$$h.html ; \
	    done

exec:
	chmod +x $(DESTDIR)/bin/*
	chmod +x $(DESTDIR)/lib/util/*

divers:
