DESTDIR = /usr/local
TCLSH	= /usr/local/bin/tclsh
SUBST	= $(TCLSH) \
	$(DESTDIR)/lib/webdns/libdns.tcl \
	$(DESTDIR)/etc/webdns.conf \
	$(DESTDIR)/bin/webdns-config

all:

install:
	cd etc ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) install
	cd bin ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) install
	cd lib ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) install
