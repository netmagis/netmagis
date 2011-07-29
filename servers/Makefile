DESTDIR		= /usr/local
TCLSH		= /usr/local/bin/tclsh
NINSTALL	= ../ninstall
SUBST		= $(TCLSH) \
			$(DESTDIR)/lib/netmagis/libnetmagis.tcl \
			$(DESTDIR)/etc/netmagis.conf \
			$(DESTDIR)/bin/netmagis-config

SHARE = \
	crontab.bind \
	crontab.dhcp \
	crontab.mroute \
	crontab.smtpf \
	pf.conf.sample

SCRIPTS = \
	mkzones \
	mkdhcp \
	mkmroute \
	mksmtpf

install:
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)/sbin
	$(NINSTALL) -m 0755 $(SUBST) $(SCRIPTS) $(DESTDIR)/sbin
	mkdir -p $(DESTDIR)/share/examples
	$(NINSTALL) -m 0644 $(SUBST) $(SHARE) $(DESTDIR)/share/examples

clean:
