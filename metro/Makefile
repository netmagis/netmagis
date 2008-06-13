#
# $Id: Makefile,v 1.3 2008-06-13 09:28:15 pda Exp $
#
# Le Makefile pour installer tous les constituants du serveur
# de métrologie.
#
# Historique
#   2008/05/06 : boggia/pda : conception
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
	<scripts pour remplacer %CONF% par $(CONF)
	    dans les binaires
	    et copier tout ca dans DESTIDRIS>
	<etc>


install-metro:
	[ -d $(DESTMETRO) ] || mkdir $(DESTMETRO)
	[ -d $(DESTMETRO)/bin ] || mkdir $(DESTMETRO)/bin
	(cd metro ; for i in bin/[a-z]* ; do \
	    sed \
		-e "s:%CONF%:$(CONF):" \
		-e "s:%LIBMETRO%:$(LIBMETRO):" \
		$$i > $(DESTMETRO)/$$i \
	    && chmod +x $(DESTMETRO)/$$i ; \
	done )
	chown -R $(WWWUSER) $(DESTMETRO)

install-bin:
