#
# $Id: Makefile,v 1.1.1.1 2008-06-13 08:55:50 pda Exp $
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
PASSWDMAC = pas-fou-non-?
PASSWDDNS = pas-fou-non-?

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

install-bin:
