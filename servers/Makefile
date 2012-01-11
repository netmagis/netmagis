NINSTALL	= ../ninstall

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

build:
	@echo ">>> Making build in `pwd`"

install:
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)$(SBINDIR)
	$(NINSTALL) -m 0755 $(SUBST) $(SCRIPTS) $(DESTDIR)$(SBINDIR)
	mkdir -p $(DESTDIR)$(NMXMPDIR)
	$(NINSTALL) -m 0644 -e "s|%SBINDIR%|$(SBINDIR)|" $(SUBST) \
			$(SHARE) $(DESTDIR)$(NMXMPDIR)

clean:
