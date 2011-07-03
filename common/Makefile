DESTDIR		= /usr/local
TCLSH		= /usr/local/bin/tclsh
SINSTALL	= ../inst/install-script
SUBST		= $(TCLSH) \
			$(DESTDIR)/lib/netmagis/libdns.tcl \
			$(DESTDIR)/etc/netmagis.conf \
			$(DESTDIR)/bin/netmagis-config

all:
	@echo ">>> Making all in `pwd`"

install:
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)/etc
	install -m 0644 netmagis.conf $(DESTDIR)/etc/netmagis.conf.sample
	mkdir -p $(DESTDIR)/bin
	$(SINSTALL) -m 0755 $(SUBST) netmagis-config $(DESTDIR)/bin
	mkdir -p $(DESTDIR)/lib/netmagis
	$(SINSTALL) -m 0644 $(SUBST) libdns.tcl $(DESTDIR)/lib/netmagis
	mkdir -p $(DESTDIR)/lib/netmagis/pkgtcl
	cd pkgtcl && make DESTDIR=$(DESTDIR)/lib/netmagis/pkgtcl clean install
	mkdir -p $(DESTDIR)/lib/netmagis/msgs 
	tar cf - msgs | tar xvf - -C $(DESTDIR)/lib/netmagis

clean:
