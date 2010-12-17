DESTDIR = /usr/local
TCLSH	= /usr/local/bin/tclsh
SINSTALL = ../../inst/install-script
SUBST	= $(TCLSH) $(DESTDIR)/lib/webdns/libdns.tcl $(DESTDIR)/etc/webdns.conf

install:
	mkdir -p $(DESTDIR)/etc
	install -m 0644 webdns.conf $(DESTDIR)/etc/webdns.conf.sample
