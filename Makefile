#
# $Id: Makefile,v 1.1.1.1 2007-01-05 15:12:00 pda Exp $
#
# Makefile pour installer les deux constituants de l'application
# de topologie
#


#
# Analyse des fichiers de configuration
#

install-anaconf:
	cd anaconf && make DESTDIR=/local/applis/topo install

#
# Visualisation Web
#

export DEBUG BASE AUTH HOMEURL

install-www:
	cd www && $(MAKE) install
