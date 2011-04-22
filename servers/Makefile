DESTDIR		= /usr/local
TCLSH		= /usr/local/bin/tclsh
SINSTALL	= ../inst/install-script
SUBST		= $(TCLSH) \
			$(DESTDIR)/lib/netmagis/libdns.tcl \
			$(DESTDIR)/etc/netmagis.conf \
			$(DESTDIR)/bin/netmagis-config

SHARE = \
	crontab.bind \
	crontab.dhcp \
	crontab.droitsmtp \
	crontab.relay

SCRIPTS = \
	generer-dhcp \
	generer-routages \
	generer-zone \
	mkdhcp \
	mkdroitsmtp \
	mkroutages \
	mkzones

install:
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)/sbin
	$(SINSTALL) -m 0755 $(SUBST) $(SCRIPTS) $(DESTDIR)/sbin
	mkdir -p $(DESTDIR)/share/examples
	$(SINSTALL) -m 0644 $(SUBST) $(SHARE) $(DESTDIR)/share/examples
