#
# Makefile principale pour l'analyseur de configurations
#
# $Id: Makefile,v 1.2 2007-01-07 21:20:46 pda Exp $
#

DESTDIR	= /local/applis/topo

all:
	cd lib ; make
	cd src ; make

install: all
	cd src ; make DESTDIR=$(DESTDIR) install

clean:
	cd lib ; make clean
	cd src ; make clean
