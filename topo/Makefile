#
# Makefile principale pour l'analyseur de configurations
#
#

TOPODIR	= /local/applis/topo

all:
	cd lib ; make
	cd src ; make

install: all
	cd src ; make \
		TOPODIR=$(TOPODIR) TCLSH=$(TCLSH) BASE="$(BASE)" \
		LIBDNS=$(LIBDNS) PKGTCL=$(PKGTCL) DELAY=$(DELAY) \
		RANCIDMODUSER=$(RANCIDMODUSER) RANCIDMODPASS="$(RANCIDMODPASS)" \
		FPING=$(FPING) RANCID=$(RANCID) \
		RANCIDDIR=$(RANCIDDIR) EQVIRT=$(EQVIRT) \
		LOGERR="$(LOGERR)" DEFUSER="$(DEFUSER)" \
		install

clean:
	cd lib ; make clean
	cd src ; make clean
