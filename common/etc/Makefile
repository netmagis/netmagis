DESTDIR		= /usr/local
TCLSH		= /usr/local/bin/tclsh
SINSTALL	= ../../inst/install-script
SUBST		= $(TCLSH) \
			$(DESTDIR)/lib/webdns/libdns.tcl \
			$(DESTDIR)/etc/webdns.conf \
			$(DESTDIR)/bin/webdns-config

install:
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)/etc
	install -m 0644 webdns.conf $(DESTDIR)/etc/webdns.conf.sample
