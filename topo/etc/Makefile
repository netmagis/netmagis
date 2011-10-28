DESTDIR		= /usr/local
TCLSH		= /usr/local/bin/tclsh
NINSTALL	= ../../ninstall
SUBST		= $(TCLSH) \
			$(DESTDIR)/lib/netmagis/libnetmagis.tcl \
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
	$(NINSTALL) -m 0755 -e "s|%TOPOBINDIR%|$(DESTDIR)/lib/netmagis/topo|" \
		$(SUBST) $(SCRIPTS) $(DESTDIR)/etc/rc.d

clean:
