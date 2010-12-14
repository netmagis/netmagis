#
# Makefile principale pour l'analyseur de configurations
#
#

TOPODIR	= /local/applis/topo
RCDIR	= /local/etc/rc.d

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
		TOPOGRAPH="$(TOPOGRAPH)" \
		install
	cd etc ; make \
		TOPODIR=$(TOPODIR) DESTDIR=$(RCDIR) \
		install

clean:
	cd lib ; make clean
	cd src ; make clean
