#
# $Id$
#

#
# Makefile pour installer le script de détection de modification de
# configuration
#

TOPODIR = /local/applis/topo
TCLSH	= /usr/local/bin/tclsh8.5
BASE    = {host=dbcrc.u-strasbg.fr dbname=dns user=detecteq password=pas-fou-non-?}
PKGTCL	= /local/services/www/pkgtcl
LIBDNS	= /local/services/www/applis/dns/lib/libdns.tcl

SCRIPTS = detectconfmod

#
# Motif de substitution à appliquer à chaque fichier installé
#

SUBST	= \
	-e 's|%TCLSH%|$(TCLSH)|' \
	-e 's|%BASE%|$(BASE)|' \
	-e 's|%PKGTCL%|$(PKGTCL)|' \
	-e 's|%LIBDNS%|$(LIBDNS)|'

install:
	test -d $(TOPODIR)/bin || mkdir $(TOPODIR)/bin
	chmod 775 $(TOPODIR)/bin
	for i in $(SCRIPTS) ; \
	do \
		sed $(SUBST) $$i > $(TOPODIR)/bin/$$i ; \
		chmod 0775 $(TOPODIR)/bin/$$i ; \
	done
