DESTDIR	= /usr/local
TCLSH	= /usr/local/bin/tclsh
SUBST	= $(TCLSH) $(DESTDIR)/lib/webdns/libdns.tcl $(DESTDIR)/etc/webdns.conf

all:
	cd lib ; make
	cd src ; make

install: all
	cd src ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) install
	cd etc ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) install
	mkdir -p $(DESTDIR)/var/webdns
	mkdir -p $(DESTDIR)/var/webdns/eqvirt
	mkdir -p $(DESTDIR)/var/webdns/eqgen

clean:
	cd lib ; make clean
	cd src ; make clean
