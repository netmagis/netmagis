DESTDIR		= /usr/local
TCLSH		= /usr/local/bin/tclsh
NINSTALL	= ../../ninstall
SUBST		= $(TCLSH) \
			$(DESTDIR)/lib/netmagis/libnetmagis.tcl \
			$(DESTDIR)/etc/netmagis.conf \
			$(DESTDIR)/bin/netmagis-config

install:
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)/lib/netmagis
	$(NINSTALL) -m 0755 -e 's|%DESTDIR%|$(DESTDIR)|' $(SUBST) *.pl $(DESTDIR)/lib/netmagis
	mkdir -p $(DESTDIR)/lib/netmagis/probes
	$(NINSTALL) -m 0755 -e 's|%DESTDIR%|$(DESTDIR)|' $(SUBST) probes/*.pl $(DESTDIR)/lib/netmagis/probes
