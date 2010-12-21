DESTDIR = /usr/local
TCLSH	= /usr/local/bin/tclsh
SUBST	= $(TCLSH) \
	$(DESTDIR)/lib/webdns/libdns.tcl \
	$(DESTDIR)/etc/webdns.conf \
	$(DESTDIR)/bin/webdns-config

usage:
	@echo "available targets:"
	@echo "	all"
	@echo "	install-common
	@echo "	install-database
	@echo "	install-www
	@echo "	install-utils
	@echo "	install-topo"

all:
	cd topo ; make

install-common:
	cd common ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) install

install-database:
	cd database ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) install

install-www:
	cd www ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) install

install-utils:
	cd utils ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) install

install-topo:
	cd topo ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) install
