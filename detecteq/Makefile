DESTDIR	= /usr/local
TCLSH	= /usr/local/bin/tclsh
SUBST	= $(TCLSH) $(DESTDIR)/lib/webdns/libdns.tcl $(DESTDIR)/etc/webdns.conf

all:

install: all
	cd syslog ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) install

clean:
	cd syslog ; make clean
