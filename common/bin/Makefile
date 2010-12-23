DESTDIR		= /usr/local
TCLSH		= /usr/local/bin/tclsh
SINSTALL	= ../../inst/install-script
SUBST		= $(TCLSH) \
			$(DESTDIR)/lib/netmagis/libdns.tcl \
			$(DESTDIR)/etc/netmagis.conf \
			$(DESTDIR)/bin/netmagis-config

install:
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)/bin
	$(SINSTALL) -m 0755 $(SUBST) netmagis-config $(DESTDIR)/bin
