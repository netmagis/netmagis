DESTDIR		= 

PREFIX		= /local/netmagis

# Debian repository path
REPODIR		= /local/repo

# Standard OS directories
BINDIR		= $(PREFIX)/bin
SBINDIR		= $(PREFIX)/sbin
ETCDIR		= $(PREFIX)/etc
MANDIR		= $(PREFIX)/man
RCDIR		= $(PREFIX)/etc/rc.d
CAFILE		= /usr/local/share/certs/ca-root-nss.crt

# Netmagis specific directories
NMDOCDIR	= $(PREFIX)/share/doc/netmagis
NMXMPDIR	= $(PREFIX)/share/examples/netmagis
NMLIBDIR	= $(PREFIX)/lib/netmagis
NMVARDIR	= $(PREFIX)/var/netmagis
NMCGIDIR	= $(PREFIX)/www/netmagis
NMWSDIR		= $(PREFIX)/www/metro

TCLSH		= /usr/local/bin/tclsh
NINSTALL	= ./ninstall
SUBST		= $(TCLSH) \
			$(NMLIBDIR)/libnetmagis.tcl \
			$(ETCDIR)/netmagis.conf \
			$(BINDIR)/netmagis-config

DIRS		= \
			BINDIR=$(BINDIR) \
			SBINDIR=$(SBINDIR) \
			ETCDIR=$(ETCDIR) \
			MANDIR=$(MANDIR) \
			RCDIR=$(RCDIR) \
			CAFILE=$(CAFILE) \
			NMDOCDIR=$(NMDOCDIR) \
			NMXMPDIR=$(NMXMPDIR) \
			NMLIBDIR=$(NMLIBDIR) \
			NMVARDIR=$(NMVARDIR) \
			NMCGIDIR=$(NMCGIDIR) \
			NMWSDIR=$(NMWSDIR) \
			DESTDIR=$(DESTDIR)

# for www/htg/src
TCLCONF		= /usr/local/lib/tcl8.6/tclConfig.sh
TCLCFLAGS	= `(cat $(TCLCONF) ; echo 'echo "$$TCL_INCLUDE_SPEC"')|sh`
TCLLFLAGS	= `(cat $(TCLCONF) ; echo 'echo "$$TCL_LIB_SPEC $$TCL_LIBS"')|sh`

# for packaging and libnetmagis.tcl
VERSION		= 2.3.5

# build debian package for the following architectures
DEBIAN_PKG_ARCH = i386
# default debian distribution
DEBIAN_DISTRIB		= dev

usage:
	@echo "available targets:"
	@echo "	version"
	@echo "	build"
	@echo "	build-topo"
	@echo "	build-www"
	@echo "	install"
	@echo "	install-common"
	@echo "	install-database"
	@echo "	install-servers"
	@echo "	install-www"
	@echo "	install-utils"
	@echo "	install-detecteq"
	@echo "	install-topo"
	@echo "	install-metro"
	@echo "	install-netmagis.org"
	@echo "	install-devtools"
	@echo "	distrib"
	@echo "	freebsd-ports"
	@echo "	debian-packages"
	@echo "	debian-packages-other-arch"
	@echo "	debian-repo"
	@echo "	  (with optional variable DEBIAN_DISTRIB=stable)"
	@echo "	clean"
	@echo "	nothing"

version:
	@echo "$(VERSION)"

build: build-www build-topo

build-www:
	cd www ; make $(DIRS) SUBST="$(SUBST)" TCLSH=$(TCLSH) \
		TCLCFLAGS="$(TCLCFLAGS)" TCLLFLAGS="$(TCLLFLAGS)" build

build-topo:
	cd topo ; make build

install: install-common install-database install-servers install-utils \
	    install-detecteq install-topo install-metro install-www
	
install-common:
	cd common ; \
	    make $(DIRS) SUBST="$(SUBST)" TCLSH=$(TCLSH) VERSION=$(VERSION) install

install-database:
	cd database ; make $(DIRS) SUBST="$(SUBST)" TCLSH=$(TCLSH) install

install-servers:
	cd servers ; make $(DIRS) SUBST="$(SUBST)" TCLSH=$(TCLSH) install

install-www: build-www
	cd www ; make $(DIRS) SUBST="$(SUBST)" TCLSH=$(TCLSH) \
		TCLCFLAGS="$(TCLCFLAGS)" TCLLFLAGS="$(TCLLFLAGS)" install

install-utils:
	cd utils ; make $(DIRS) SUBST="$(SUBST)" TCLSH=$(TCLSH) install

install-topo: build-topo
	cd topo ; make $(DIRS) SUBST="$(SUBST)" TCLSH=$(TCLSH) install

install-detecteq:
	cd detecteq ; make $(DIRS) SUBST="$(SUBST)" TCLSH=$(TCLSH) install

install-metro:
	cd metro ; make $(DIRS) SUBST="$(SUBST)" TCLSH=$(TCLSH) install

install-netmagis.org: build-www
	cd doc/netmagis.org ; make $(DIRS) SUBST="$(SUBST)" TCLSH=$(TCLSH) install

install-devtools:
	cd devtools ; make $(DIRS) SUBST="$(SUBST)" TCLSH=$(TCLSH) install

distrib: clean
	rm -rf /tmp/netmagis-$(VERSION)
	mkdir /tmp/netmagis-$(VERSION)
	tar cf - \
		--exclude "doc/jres/*" \
		--exclude "doc/pres/*" \
		--exclude "doc/old/*" \
		--exclude "doc/netmagis.org" \
		* \
	    | tar xf - -C /tmp/netmagis-$(VERSION)
	tar -czf netmagis-$(VERSION).tar.gz -C /tmp netmagis-$(VERSION)
	rm -rf /tmp/netmagis-$(VERSION)

clean:
	cd common ; make clean
	cd database ; make clean
	cd servers ; make clean
	cd www ; make clean
	cd utils ; make clean
	cd detecteq ; make clean
	cd topo ; make clean
	cd metro ; make clean
	rm -f netmagis-*.tar.gz

nothing:
