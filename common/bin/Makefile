DESTDIR = /usr/local
TCLSH	= /usr/local/bin/tclsh
SINSTALL = ../../inst/install-script
SUBST	= $(TCLSH) $(DESTDIR)/lib/webdns/libdns.tcl $(DESTDIR)/etc/webdns.conf

install:
	mkdir -p $(DESTDIR)/bin
	$(SINSTALL) -m 0755 $(SUBST) webdns-config $(DESTDIR)/bin
