DESTDIR		= /usr/local
TCLSH		= /usr/local/bin/tclsh
SINSTALL	= ../../inst/install-script
SUBST		= $(TCLSH) \
			$(DESTDIR)/lib/netmagis/libdns.tcl \
			$(DESTDIR)/etc/netmagis.conf \
			$(DESTDIR)/bin/netmagis-config

SCRIPTS = \
	run-all.sh

install:
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)/share/examples
	$(SINSTALL) -m 0755 $(SUBST) $(SCRIPTS) $(DESTDIR)/share/examples
	cp *.txt $(DESTDIR)/share/examples
