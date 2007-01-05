#
# Makefile principale pour l'analyseur de configurations
#
# $Id: Makefile,v 1.1.1.1 2007-01-05 15:12:00 pda Exp $
#

#DESTDIR	= /local/applis/topo
DESTDIR	= /local/applis/T

all:
	cd lib ; make
	cd src ; make

install: all
	cd src ; make DESTDIR=$(DESTDIR) install

clean:
	cd lib ; make clean
	cd src ; make clean
