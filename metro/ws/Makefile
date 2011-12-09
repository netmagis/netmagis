DESTDIR		= /usr/local
TCLSH		= /usr/local/bin/tclsh
NINSTALL	= ../../ninstall
SUBST		= $(TCLSH) \
			$(DESTDIR)/lib/netmagis/libnetmagis.tcl \
			$(DESTDIR)/etc/netmagis.conf \
			$(DESTDIR)/bin/netmagis-config

install:
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)/www/metro
	$(NINSTALL) -m 0755 $(SUBST) gengraph $(DESTDIR)/www/metro
