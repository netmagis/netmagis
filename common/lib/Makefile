DESTDIR = /usr/local
TCLSH	= /usr/local/bin/tclsh
SINSTALL = ../../inst/install-script
SUBST	= $(TCLSH) $(DESTDIR)/lib/webdns/libdns.tcl $(DESTDIR)/etc/webdns.conf

install:
	mkdir -p $(DESTDIR)/lib/webdns
	$(SINSTALL) -m 0644 $(SUBST) libdns.tcl $(DESTDIR)/lib/webdns
	mkdir -p $(DESTDIR)/lib/webdns/pkgtcl
	cd pkgtcl && make DESTDIR=$(DESTDIR)/lib/webdns/pkgtcl clean install
	mkdir -p $(DESTDIR)/lib/webdns/msgs 
	tar cf - msgs | tar xvf - -C $(DESTDIR)/lib/webdns

