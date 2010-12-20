DESTDIR	= /usr/local
TCLSH	= /usr/local/bin/tclsh
SINSTALL = ../../inst/install-script
SUBST	= $(TCLSH) $(DESTDIR)/lib/webdns/libdns.tcl $(DESTDIR)/etc/webdns.conf

SCRIPTS= \
	topographd.sh \
	toposendd.sh

all:

install:
	mkdir -p $(DESTDIR)/etc/rc.d
	for i in $(SCRIPTS) ; \
	do \
		sed -e "s|%TOPOBINDIR%|$(DESTDIR)/lib/webdns/topo|" $$i \
			    > $(DESTDIR)/etc/rc.d/$$i && \
		chmod 0775 $(DESTDIR)/etc/rc.d$/$i ; \
	done

clean:
