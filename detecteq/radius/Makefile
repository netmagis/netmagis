DESTDIR		= /usr/local
TCLSH		= /usr/local/bin/tclsh
NINSTALL	= ../../ninstall
SUBST		= $(TCLSH) \
			$(DESTDIR)/lib/netmagis/libnetmagis.tcl \
			$(DESTDIR)/etc/netmagis.conf \
			$(DESTDIR)/bin/netmagis-config

FILES = *.conf

install:
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)/share/examples/netmagis/radius
	$(NINSTALL) -m 0644 -e "s|%DESTDIR%|$(DESTDIR)|" $(SUBST) \
			$(FILES) $(DESTDIR)/share/examples/netmagis/radius
