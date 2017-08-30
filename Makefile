# for packaging and libnetmagis.tcl
VERSION		= 3.0.0alpha

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
RANDOM		= /dev/random

# Netmagis specific directories
NMDOCDIR	= $(PREFIX)/share/doc/netmagis
NMXMPDIR	= $(PREFIX)/share/examples/netmagis
NMLIBDIR	= $(PREFIX)/lib/netmagis
NMVARDIR	= $(PREFIX)/var/netmagis
NMWWWDIR	= $(PREFIX)/www/netmagis
###NMCGIDIR	= $(PREFIX)/www/netmagis
NMWSDIR		= $(PREFIX)/www/metro

TCLSH		= /usr/local/bin/tclsh
NINSTALL	= ./ninstall
SUBST		= $(TCLSH) \
			$(NMLIBDIR)/libnetmagis.tcl \
			$(ETCDIR)/netmagis.conf

VARS		= \
			VERSION=$(VERSION) \
			BINDIR=$(BINDIR) \
			SBINDIR=$(SBINDIR) \
			ETCDIR=$(ETCDIR) \
			MANDIR=$(MANDIR) \
			RCDIR=$(RCDIR) \
			CAFILE=$(CAFILE) \
			RANDOM=$(RANDOM) \
			NMDOCDIR=$(NMDOCDIR) \
			NMXMPDIR=$(NMXMPDIR) \
			NMLIBDIR=$(NMLIBDIR) \
			NMVARDIR=$(NMVARDIR) \
			NMWWWDIR=$(NMWWWDIR) \
			NMCGIDIR=$(NMCGIDIR) \
			NMWSDIR=$(NMWSDIR) \
			DESTDIR=$(DESTDIR)

# for www/htg/src
TCLCONF		= /usr/local/lib/tcl8.6/tclConfig.sh
TCLCFLAGS	= `(cat $(TCLCONF) ; echo 'echo "$$TCL_INCLUDE_SPEC"')|sh`
TCLLFLAGS	= `(cat $(TCLCONF) ; echo 'echo "$$TCL_LIB_SPEC $$TCL_LIBS"')|sh`

# build debian package for the following architectures
DEBIAN_PKG_ARCH = i386
# default debian distribution
DEBIAN_DISTRIB		= dev

usage:
	@echo "available targets:"
	@echo "	build"
	@echo "	build-topo"
	@echo "	build-www"
	@echo "	build-server"
	@echo "	test"
	@echo "	install"
	@echo "	install-common"
	@echo "	install-server"
	@echo "	install-servers"
	@echo "	install-client"
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

build: build-www build-topo

# NEARLY OBSOLETE
build-www:
	cd www ; $(MAKE) $(VARS) SUBST="$(SUBST)" TCLSH=$(TCLSH) \
		TCLCFLAGS="$(TCLCFLAGS)" TCLLFLAGS="$(TCLLFLAGS)" build

build-server:
	cd server ; $(MAKE) $(VARS) SUBST="$(SUBST)" TCLSH=$(TCLSH) build

build-topo:
	cd topo ; $(MAKE) build

test:	test-server

test-server:
	cd server ; $(MAKE) $(VARS) SUBST="$(SUBST)" TCLSH=$(TCLSH) test

install: install-common install-server install-servers install-client \
	    install-detecteq install-topo install-metro install-www
	
install-common:
	cd common ; \
	    $(MAKE) $(VARS) SUBST="$(SUBST)" TCLSH=$(TCLSH) VERSION=$(VERSION) install

install-server:
	cd server ; $(MAKE) $(VARS) SUBST="$(SUBST)" TCLSH=$(TCLSH) VERSION=$(VERSION) install

install-servers:
	cd servers ; $(MAKE) $(VARS) SUBST="$(SUBST)" TCLSH=$(TCLSH) install

# NEARLY OBSOLETE
install-www: build-www
	cd www ; $(MAKE) $(VARS) SUBST="$(SUBST)" TCLSH=$(TCLSH) \
		TCLCFLAGS="$(TCLCFLAGS)" TCLLFLAGS="$(TCLLFLAGS)" install

install-client:
	cd client ; $(MAKE) $(VARS) SUBST="$(SUBST)" TCLSH=$(TCLSH) install

install-topo: build-topo
	cd topo ; $(MAKE) $(VARS) SUBST="$(SUBST)" TCLSH=$(TCLSH) install

install-detecteq:
	cd detecteq ; $(MAKE) $(VARS) SUBST="$(SUBST)" TCLSH=$(TCLSH) install

install-metro:
	cd metro ; $(MAKE) $(VARS) SUBST="$(SUBST)" TCLSH=$(TCLSH) install

# PROBLEM
install-netmagis.org: build-www
	cd doc/netmagis.org ; $(MAKE) $(VARS) SUBST="$(SUBST)" TCLSH=$(TCLSH) install

install-devtools:
	cd devtools ; $(MAKE) $(VARS) SUBST="$(SUBST)" TCLSH=$(TCLSH) install

distrib: clean
	rm -rf /tmp/netmagis-$(VERSION)
	mkdir /tmp/netmagis-$(VERSION)
	tar cf - --exclude "pkg/*" \
		--exclude "doc/jres/*" \
		--exclude "doc/pres/*" \
		--exclude "doc/old/*" \
		--exclude "doc/netmagis.org" \
		* \
	    | tar xf - -C /tmp/netmagis-$(VERSION)
	tar -czf netmagis-$(VERSION).tar.gz -C /tmp netmagis-$(VERSION)
	rm -rf /tmp/netmagis-$(VERSION)

freebsd-ports:
	@if [ `uname -s` != FreeBSD ] ; then \
	    echo "Please, make this target on a FreeBSD host" ; \
	    echo "once netmagis-$(VERSION).tar.gz is on the master site" ; \
	    exit 1 ; \
	fi
	for i in pkg/freebsd/netmagis-* ; do (cd $$i ; $(MAKE) clean) ; done
	cd pkg/freebsd/netmagis-common ; $(MAKE) makesum
	tar -czf netmagis-freebsd-ports-$(VERSION).tar.gz -C pkg/freebsd .

debian-packages:
	@if [ `uname -s` != Linux ] ; then \
	    echo "Please, make this target on a Debian/Ubuntu host" ; \
	    echo "once netmagis-$(VERSION).tar.gz is on the master site" ; \
	    exit 1 ; \
	fi
	cd pkg/debian ; $(MAKE) VERSION=$(VERSION) release

debian-packages-other-arch:
	cd pkg/debian ; \
	for arch in $(DEBIAN_PKG_ARCH) ; do \
	     $(MAKE) VERSION=$(VERSION) ARCH=$$arch release-arch ; \
	done

debian-repo:
	pkg/debian/update-repo $(VERSION) pkg/debian $(DEBIAN_DISTRIB) $(REPODIR)

clean:
	cd common ; $(MAKE) clean
	cd server ; $(MAKE) clean
	cd servers ; $(MAKE) clean
	cd www ; $(MAKE) clean
	cd client ; $(MAKE) clean
	cd detecteq ; $(MAKE) clean
	cd topo ; $(MAKE) clean
	cd metro ; $(MAKE) clean
	rm -f netmagis-*.tar.gz

nothing:
