#
# $Id: Makefile,v 1.5 2007-01-10 19:17:59 pda Exp $
#
# Makefile pour lancer l'installation de l'application topo
# Ce Makefile n'est normalement jamais appelé lui-même, mais
# il est appelé
#

TCLSH	= /usr/local/bin/tclsh8.4

DEBUG  = 0
BASE    = {host=dbcrc.u-strasbg.fr dbname=dns user=dns password=pas-fou-non-?}
AUTH    = {ldap {host ldaposiris.u-strasbg.fr port 389 base o=osiris filter (\&(objectClass=osirisPerson)(uid=%s)) fields {login uid nom sn prenom givenName prenomnom cn mel mail tel telephoneNumber fax facsimileTelephoneNumber mobile mobile adr l password userPassword groupes webGroup phnom sn phprenom givenName} searchperson_ou ou=personnes,o=osiris createperson_ou ou=autres,ou=personnes,o=osiris group_ou ou=webGroups,o=osiris person_oc osirisPerson group_oc osirisWebGroup param_ou ou=auth,ou=osirisParam,o=osiris param_oc osirisParam}}
HOMEURL	= /applis/topo

#DEBUG   = 1
#BASE    = {host=dbcrc.u-strasbg.fr dbname=dns user=dns password=pas-fou-non-?}
#AUTH    = {ldap {host ldaposiris.u-strasbg.fr port 389 base o=osiris filter (\&(objectClass=osirisPerson)(uid=%s)) fields {login uid nom sn prenom givenName prenomnom cn mel mail tel telephoneNumber fax facsimileTelephoneNumber mobile mobile adr l password userPassword groupes webGroup phnom sn phprenom givenName} searchperson_ou ou=personnes,o=osiris createperson_ou ou=autres,ou=personnes,o=osiris group_ou ou=webGroups,o=osiris person_oc osirisPerson group_oc osirisWebGroup param_ou ou=auth,ou=osirisParam,o=osiris param_oc osirisParam}}
#HOMEURL	= /applis/devtopo

NOLOGIN	= /local/etc/nologin.dns

# utilisateur par défaut pour les scripts non web
DEFUSER	= crc

DESTDIR	= /local/services/www$(HOMEURL)
PKGTCL	= /local/services/www/pkgtcl

HTG	= /local/services/www/utils/htg

ROOT	= {pda jean}

LIBDNS	= /local/services/www/applis/dns/lib/libdns.tcl
#LIBDNS	= /local/services/www/applis/devdns/lib/libdns.tcl
TOPODIR	= /local/applis/topo
GRAPH	= $(TOPODIR)/osiris/osiris.graph

NEATO	= /usr/local/bin/neato
DOT	= /usr/local/bin/dot
# le problème avec ps2pdf, c'est qu'il appelle plein de scripts dans /usr/local
PS2PDF	= sh $(DESTDIR)/lib/ps2pdf

# Version de l'application
VERSION = 0.2

#
# Motif de substitution à appliquer à chaque fichier installé
#

SUBST	= \
	-e 's|%TCLSH%|$(TCLSH)|' \
	-e 's|%DEBUG%|$(DEBUG)|' \
	-e 's|%DESTDIR%|$(DESTDIR)|' \
	-e 's|%PKGTCL%|$(PKGTCL)|' \
	-e 's|%HOMEURL%|$(HOMEURL)|' \
	-e 's|%LIBDNS%|$(LIBDNS)|' \
	-e 's|%TOPODIR%|$(TOPODIR)|' \
	-e 's|%GRAPH%|$(GRAPH)|' \
	-e 's|%VERSION%|$(VERSION)|' \
	-e 's|%ROOT%|$(ROOT)|' \
	-e 's|%NOLOGIN%|$(NOLOGIN)|' \
	-e 's|%DEFUSER%|$(DEFUSER)|' \
	-e 's|%AUTH%|$(AUTH)|' \
	-e 's|%BASE%|$(BASE)|' \
	-e 's|%NEATO%|$(NEATO)|' \
	-e 's|%DOT%|$(DOT)|' \
	-e 's|%PS2PDF%|$(PS2PDF)|'

#
# La documentation (succinte) de l'application
#

#IMAGES	= dns.gif mcd-dns.gif

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
	    while read d ; do \
		if [ ! -d $(DESTDIR)/$$d ] ; then mkdir -p $(DESTDIR)/$$d ; fi ; \
	    done

autres:
	find . \( -type f -o -type l \) -print | \
	    grep -v '.htgt$$' | \
	    grep -v '.gif$$' | \
	    grep -v Makefile | \
	    while read f ; do \
		echo $$f ; \
		sed $(SUBST) $$f > $(DESTDIR)/$$f ; \
	    done

gif:	$(IMAGES)
	cp $(IMAGES) $(DESTDIR)

html:
	find . -name "*.htgt" -print | \
	    while read f ; do \
		h=`echo $$f | sed 's/.htgt$$//'` ; \
		echo $$f ; \
		$(HTG) $$f | sed $(SUBST) > $(DESTDIR)/$$h.html ; \
	    done

exec:
	chmod +x $(DESTDIR)/bin/*

divers:
