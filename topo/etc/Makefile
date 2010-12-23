DESTDIR		= /usr/local
TCLSH		= /usr/local/bin/tclsh
SINSTALL	= ../../inst/install-script
SUBST		= $(TCLSH) \
			$(DESTDIR)/lib/netmagis/libdns.tcl \
			$(DESTDIR)/etc/netmagis.conf \
			$(DESTDIR)/bin/netmagis-config

SCRIPTS= \
	topographd.sh \
	toposendd.sh

all:
	@echo ">>> Making all in `pwd`"

install:
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)/etc/rc.d
	for i in $(SCRIPTS) ; \
	do \
		sed -e "s|%TOPOBINDIR%|$(DESTDIR)/lib/netmagis/topo|" $$i \
			    > $(DESTDIR)/etc/rc.d/$$i && \
		chmod 0775 $(DESTDIR)/etc/rc.d$/$i ; \
	done

clean:
