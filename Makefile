DESTDIR = /usr/local
TCLSH	= /usr/local/bin/tclsh
SUBST	= $(TCLSH) $(DESTDIR)/lib/webdns/libdns.tcl $(DESTDIR)/etc/webdns.conf

usage:
	@echo "available targets: common database utils www topo"

install-common:
	cd common ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) install

install-utils:
	cd utils ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) install
