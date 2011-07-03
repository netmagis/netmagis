DESTDIR		= /usr/local
TCLSH		= /usr/local/bin/tclsh
NINSTALL	= ../../ninstall
SUBST		= $(TCLSH) \
			$(DESTDIR)/lib/netmagis/libdns.tcl \
			$(DESTDIR)/etc/netmagis.conf \
			$(DESTDIR)/bin/netmagis-config

SCRIPTS = \
	run-all.sh

FILES = *.txt \
	crontab.database

install:
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)/share/examples
	$(NINSTALL) -m 0755 $(SUBST) $(SCRIPTS) $(DESTDIR)/share/examples
	install -m 0644 $(FILES) $(DESTDIR)/share/examples
	mkdir -p $(DESTDIR)/share/examples/zones
	install -m 0644 zones/* $(DESTDIR)/share/examples/zones
