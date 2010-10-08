#
# Makefile principale pour l'analyseur de configurations
#
# $Id$
#

TOPODIR	= /local/applis/topo

all:
	cd lib ; make
	cd src ; make

install: all
	cd src ; make TOPODIR=$(TOPODIR) TCLSH=$(TCLSH) FPING=$(FPING) install

clean:
	cd lib ; make clean
	cd src ; make clean
