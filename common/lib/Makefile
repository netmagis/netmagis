DESTDIR		= /usr/local
TCLSH		= /usr/local/bin/tclsh
SINSTALL	= ../../inst/install-script
SUBST		= $(TCLSH) \
			$(DESTDIR)/lib/netmagis/libdns.tcl \
			$(DESTDIR)/etc/netmagis.conf \
			$(DESTDIR)/bin/netmagis-config

install:
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)/lib/netmagis
	$(SINSTALL) -m 0644 $(SUBST) libdns.tcl $(DESTDIR)/lib/netmagis
	mkdir -p $(DESTDIR)/lib/netmagis/pkgtcl
	cd pkgtcl && make DESTDIR=$(DESTDIR)/lib/netmagis/pkgtcl clean install
	mkdir -p $(DESTDIR)/lib/netmagis/msgs 
	tar cf - msgs | tar xvf - -C $(DESTDIR)/lib/netmagis

