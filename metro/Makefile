#
# $Id: Makefile,v 1.7 2008-06-13 10:16:50 pda Exp $
#
# Le Makefile pour installer tous les constituants du serveur
# de métrologie.
#
# Historique
#   2008/05/06 : boggia/pda : conception
#   2008/06/13 : boggia/pda : debut de la rédaction effective
#

DESTIDRIS = /local/services/www-idris
DESTMETRO = /local/services/www-metro
DESTEXPL  = /local/obj999
CONF      = /local/obj999/etc/obj999.conf
LIBMETRO  = $(DESTEXPL)/lib/libmetro.pl
PASSWDMAC = pas-fou-non-?
PASSWDDNS = pas-fou-non-?

WWWUSER	  = www-data:obj999
BINUSER   = obj999:obj999

SUBST	= \
	-e "s|%CONF%|$(CONF)|" \
	-e "s|%LIBMETRO%|$(LIBMETRO)|"

install: install-idris install-metro install-binlib

install-idris:
	for d in $(DESTIDRIS) $(DESTIDRIS)/bin $(DESTIDRIS)/images ; do \
	    [ -d $$d ] || mkdir $$d ; \
	done
	(cd www ; for i in bin/[a-z]* ; do \
	    sed $(SUBST) $$i > $(DESTIDRIS)/$$i ; \
	done )
	chmod +x $(DESTIDRIS)/bin/*
	cp www/images/*.* $(DESTIDRIS)/images
	chown -R $(WWWUSER) $(DESTIDRIS)


install-metro:
	for d in $(DESTMETRO) $(DESTMETRO)/bin ; do \
	    [ -d $$d ] || mkdir $$d ; \
	done
	(cd metro ; for i in bin/[a-z]* ; do \
	    sed $(SUBST) $$i > $(DESTMETRO)/$$i ; \
	done )
	chmod +x $(DESTMETRO)/bin/*
	chown $(WWWUSER) $(DESTMETRO) $(DESTMETRO)/bin $(DESTMETRO)/bin/*

install-binlib:
	for d in $(DESTEXPL) $(DESTEXPL)/bin $(DESTEXPL)/lib ; do \
	    [ -d $$d ] || mkdir $$d ; \
	done
	for i in bin/[a-z]* lib/[a-z]* ; do \
	    sed $(SUBST) $$i > $(DESTEXPL)/$$i ; \
	done
	chmod +x $(DESTEXPL)/bin/*
	chown -R $(BINUSER) $(DESTEXPL)/bin $(DESTEXPL)/lib
