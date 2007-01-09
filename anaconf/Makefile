#
# Makefile principale pour l'analyseur de configurations
#
# $Id: Makefile,v 1.3 2007-01-09 18:41:52 pda Exp $
#

DESTDIR	= /local/applis/devtopo

all:
	cd lib ; make
	cd src ; make

install: all
	cd src ; make DESTDIR=$(DESTDIR) install

clean:
	cd lib ; make clean
	cd src ; make clean
