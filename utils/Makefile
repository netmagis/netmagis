DESTDIR = /usr/local
TCLSH	= /usr/local/bin/tclsh
SINSTALL = ../inst/install-script
SUBST	= $(TCLSH) $(DESTDIR)/lib/webdns/libdns.tcl $(DESTDIR)/etc/webdns.conf

SCRIPTS = \
	dnsaddalias \
	dnsaddhost \
	dnsdelhost \
	dnsdelip \
	dnsmodattr \
	dnsreadprol \
	dnswriteprol

install:
	mkdir -p $(DESTDIR)/bin
	$(SINSTALL) -m 0755 $(SUBST) $(SCRIPTS) $(DESTDIR)/bin
