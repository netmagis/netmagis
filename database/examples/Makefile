DESTDIR		= /usr/local
TCLSH		= /usr/local/bin/tclsh
NINSTALL	= ../../ninstall
SUBST		= $(TCLSH) \
			$(DESTDIR)/lib/netmagis/libnetmagis.tcl \
			$(DESTDIR)/etc/netmagis.conf \
			$(DESTDIR)/bin/netmagis-config

SCRIPTS = \
	run-all.sh

FILES = *.txt \
	crontab.database

install:
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)/share/examples/netmagis
	$(NINSTALL) -m 0755 $(SUBST) $(SCRIPTS) $(DESTDIR)/share/examples/netmagis
	$(NINSTALL) -m 0644 -e "s|%DESTDIR%|$(DESTDIR)|" $(SUBST) \
			$(FILES) $(DESTDIR)/share/examples/netmagis
	mkdir -p $(DESTDIR)/share/examples/netmagis/zones
	install -m 0644 zones/* $(DESTDIR)/share/examples/netmagis/zones
