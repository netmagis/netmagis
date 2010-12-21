DESTDIR		= /usr/local
TCLSH		= /usr/local/bin/tclsh
SINSTALL	= ../../inst/install-script
SUBST		= $(TCLSH) \
			$(DESTDIR)/lib/webdns/libdns.tcl \
			$(DESTDIR)/etc/webdns.conf \
			$(DESTDIR)/bin/webdns-config

install:
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)/bin
	$(SINSTALL) -m 0755 $(SUBST) webdns-config $(DESTDIR)/bin
