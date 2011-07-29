DESTDIR		= /usr/local
TCLSH		= /usr/local/bin/tclsh
NINSTALL	= ../ninstall
SUBST		= $(TCLSH) \
			$(DESTDIR)/lib/netmagis/libnetmagis.tcl \
			$(DESTDIR)/etc/netmagis.conf \
			$(DESTDIR)/bin/netmagis-config

SCRIPTS = \
	dnsaddalias \
	dnsaddhost \
	dnsdelhost \
	dnsdelip \
	dnsmodattr \
	dnsreadprol \
	dnswriteprol

install:
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)/bin
	$(NINSTALL) -m 0755 $(SUBST) $(SCRIPTS) $(DESTDIR)/bin

clean:
