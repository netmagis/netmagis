DESTDIR		= /usr/local
TCLSH		= /usr/local/bin/tclsh
NINSTALL	= ../ninstall
SUBST		= $(TCLSH) \
			$(DESTDIR)/lib/netmagis/libnetmagis.tcl \
			$(DESTDIR)/etc/netmagis.conf \
			$(DESTDIR)/bin/netmagis-config

all:
	@echo ">>> Making all in `pwd`"

install:
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)/etc
	install -m 0644 netmagis.conf $(DESTDIR)/etc/netmagis.conf.sample
	mkdir -p $(DESTDIR)/bin
	$(NINSTALL) -m 0755 $(SUBST) netmagis-config $(DESTDIR)/bin
	mkdir -p $(DESTDIR)/lib/netmagis
	$(NINSTALL) -m 0644 -e "s/%NMVERSION%/$(VERSION)/" \
		$(SUBST) libnetmagis.tcl $(DESTDIR)/lib/netmagis
	mkdir -p $(DESTDIR)/lib/netmagis/pkgtcl
	cd pkgtcl && make DESTDIR=$(DESTDIR)/lib/netmagis/pkgtcl clean install
	mkdir -p $(DESTDIR)/lib/netmagis/msgs 
	tar cf - msgs | tar xvf - -C $(DESTDIR)/lib/netmagis

clean:
