#
# $Id: Makefile,v 1.7 2008-06-13 10:16:50 pda Exp $
#
# Le Makefile pour installer tous les constituants du serveur
# de métrologie.
#
# Historique
#   2008/05/06 : boggia/pda : conception
#   2008/06/13 : boggia/pda : debut de la rédaction effective
#   2010/12/21 : suppression de l'installation Idris
#

DESTDIR = /usr/local
CRONDIR = /etc/cron.d
CONF    = $(DESTDIR)/etc/netmagis.conf
BINDIR  = $(DESTDIR)/bin/netmagis/metro
CGIDIR  = $(DESTDIR)/www/netmagis
LIBDIR  = $(DESTDIR)/lib/netmagis/metro
DATADIR = $(DESTDIR)/var/netmagis/metro
LIBMETRO  = $(DESTDIR)/lib/netmagis/metro/libmetro.pl

SUBST	= \
	-e "s|%DESTDIR%|$(DESTDIR)|" \
	-e "s|%BINDIR%|$(BINDIR)|" \
	-e "s|%CONF%|$(CONF)|" \
	-e "s|%LIBMETRO%|$(LIBMETRO)|"

install:
	for d in $(DATADIR) $(LIBDIR) $(CGIDIR) $(BINDIR); do \
	    mkdir -p $$d ; \
	done
	for d in poller cache lock log db spool graph wifi; do \
	    mkdir -p $(DATADIR)/$$d ; \
	done
	(cd bin ; for i in * ; do \
		sed $(SUBST) $$i > $(BINDIR)/$$i ; \
		chmod +x $(BINDIR)/$$i ; \
	done )
	(cd lib ; for i in * ; do \
		sed $(SUBST) $$i > $(LIBDIR)/$$i ; \
	done )
	(cd www/bin ; for i in * ; do \
		sed $(SUBST) $$i > $(CGIDIR)/$$i ; \
	done )
