DESTDIR 	= /usr/local
TCLSH		= /usr/local/bin/tclsh
NINSTALL	= ../ninstall
SUBST		= $(TCLSH) \
			$(DESTDIR)/lib/netmagis/libnetmagis.tcl \
			$(DESTDIR)/etc/netmagis.conf \
			$(DESTDIR)/bin/netmagis-config

SHARE	= crontab.metro apache_metro.conf

SUBDIRS = cache lock log db spool graph wifi report

all:
	@echo ">>> Making all in `pwd`"

install:
	@echo ">>> Making install in `pwd`"
	cd bin ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) install
	cd lib ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) install
	cd ws ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) install
	mkdir -p $(DESTDIR)/share/examples/netmagis
	$(NINSTALL) -m 0644 -e "s|%DESTDIR%|$(DESTDIR)|" $(SUBST) \
		$(SHARE) $(DESTDIR)/share/examples/netmagis
	cd $(DESTDIR) ; mkdir -p var/netmagis/metro
	cd $(DESTDIR)/var/netmagis/metro ; \
	    for i in $(SUBDIRS) ; do mkdir -p $$i ; done

clean:
