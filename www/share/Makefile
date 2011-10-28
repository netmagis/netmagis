DESTDIR		= /usr/local
TCLSH		= /usr/local/bin/tclsh
NINSTALL	= ../../ninstall
SUBST		= $(TCLSH) \
			$(DESTDIR)/lib/netmagis/libnetmagis.tcl \
			$(DESTDIR)/etc/netmagis.conf \
			$(DESTDIR)/bin/netmagis-config

all:
	@echo ">>> Making all in `pwd`"

install:
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)/share/examples/netmagis
	$(NINSTALL) -m 0644 -e "s|%DESTDIR%|$(DESTDIR)|" $(SUBST) \
		*.conf $(DESTDIR)/share/examples/netmagis

clean:
