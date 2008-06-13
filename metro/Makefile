#
# $Id: Makefile,v 1.6 2008-06-13 10:01:06 pda Exp $
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
DESTBIN   = /local/obj999/bin
CONF      = /local/obj999/etc/obj999.conf
LIBMETRO  = /local/obj999/lib/libmetro.pl
PASSWDMAC = pas-fou-non-?
PASSWDDNS = pas-fou-non-?

WWWUSER	  = www:obj999
BINUSER   = obj999:obj999

SUBST	= \
	-e 's|%CONF%|$(CONF)|' \
	-e 's|%PASSWDMAC%|$(PASSWDMAC)|' \
	-e 's|%PASSWDDNS%|$(PASSWDDNS)|'

install: install-idris install-metro install-bin

install-idris:
	for d in $(DESTIDRIS) $(DESTIDRIS)/bin $(DESTIDRIS)/images ; do \
	    [ -d $$d ] || mkdir $$d ; \
	done
	(cd www ; for i in bin/[a-z]* ; do \
	    sed \
		-e "s:%CONF%:$(CONF):" \
		-e "s:%LIBMETRO%:$(LIBMETRO):" \
		$$i > $(DESTIDRIS)/$$i ; \
	done )
	chmod +x $(DESTIDRIS)/bin/*
	cp www/images/*.* $(DESTIDRIS)/images
	chown -R $(WWWUSER) $(DESTIDRIS)


install-metro:
	for d in $(DESTMETRO) $(DESTMETRO)/bin ; do \
	    [ -d $$d ] || mkdir $$d ; \
	done
	(cd metro ; for i in bin/[a-z]* ; do \
	    sed \
		-e "s:%CONF%:$(CONF):" \
		-e "s:%LIBMETRO%:$(LIBMETRO):" \
		$$i > $(DESTMETRO)/$$i ; \
	done )
	chmod +x $(DESTMETRO)/bin/*
	chown $(WWWUSER) $(DESTMETRO) $(DESTMETRO)/bin $(DESTMETRO)/bin/*

install-bin:
