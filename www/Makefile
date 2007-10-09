#
# Makefile pour lancer l'installation de l'application dns
#
# $Id: Makefile,v 1.3 2007-10-09 12:28:14 jean Exp $
#

TCLSH	= /usr/local/bin/tclsh8.4

#DEBUG   = 1
DEBUG  = 0

BASE    = {dbname=dns user=dns password=mot-de-passe-de-dns}
AUTH    = {postgresql {dbname=auth user=auth password=mot-de-passe-de-auth}}
HOMEURL	= /applis/dns
NOLOGIN	= /local/etc/nologin.dns

#BASE    = {dbname=devdns user=dns password=mot-de-passe-de-dns}
#AUTH    = {postgresql {dbname=auth user=auth password=mot-de-passe-de-auth}}
#HOMEURL	= /applis/devdns
#NOLOGIN	= /local/etc/nologin.devdns

# utilisateur par défaut pour les scripts non web
DEFUSER	= crc

DESTDIR	= /local/services/www$(HOMEURL)
PKGTCL	= /local/services/www/pkgtcl

HTG	= /local/services/www/utils/htg

ROOT	= {pda jean}


# Intervalle entre deux générations de zones
INTERVALLE = 10
# Page présentant les DNS Osiris
DOCDNS	= /osiris/services/dns.html

# Couleur de fond des boutons "valider"
COULEUR = "\#10C090"

# Version de l'application
VERSION = 1.3.9

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
	-e 's|%COULEUR%|$(COULEUR)|' \
	-e 's|%AUTH%|$(AUTH)|' \
	-e 's|%PASSWDURL%|$(PASSWDURL)|' \
	-e 's|%BASE%|$(BASE)|'

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

#dns.gif: dns.fig
#	fig2dev -Lgif dns.fig > dns.gif
#

mcd-dns.gif: mcd-dns.fig
	fig2dev -Lgif mcd-dns.fig > mcd-dns.gif

html:
	find . -name "*.htgt" -print | \
	    while read f ; do \
		h=`echo $$f | sed 's/.htgt$$//'` ; \
		echo $$f ; \
		$(HTG) $$f | sed $(SUBST) > $(DESTDIR)/$$h.html ; \
	    done

exec:
	chmod +x $(DESTDIR)/bin/*
	chmod +x $(DESTDIR)/lib/util/*

divers:
