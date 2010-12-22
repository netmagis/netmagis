DESTDIR		= /usr/local
TCLSH		= /usr/local/bin/tclsh
SINSTALL	= ../../inst/install-script
SUBST		= $(TCLSH) \
			$(DESTDIR)/lib/webdns/libdns.tcl \
			$(DESTDIR)/etc/webdns.conf \
			$(DESTDIR)/bin/webdns-config

all:
	@echo ">>> Making all in `pwd`"

install:
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)/sbin
	$(SINSTALL) -m 0755 $(SUBST) detectconfmod $(DESTDIR)/sbin

clean:
