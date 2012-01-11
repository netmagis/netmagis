NINSTALL	= ../../ninstall

SCRIPTS = \
	run-all.sh

FILES = *.txt \
	crontab.database

install:
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)$(NMXMPDIR)
	$(NINSTALL) -m 0755 -e "s|%SBINDIR%|$(SBINDIR)|" $(SUBST) \
			$(SCRIPTS) $(DESTDIR)$(NMXMPDIR)
	$(NINSTALL) -m 0644 -e "s|%SBINDIR%|$(SBINDIR)|" $(SUBST) \
			$(FILES) $(DESTDIR)$(NMXMPDIR)
	mkdir -p $(DESTDIR)$(NMXMPDIR)/zones
	install -m 0644 zones/* $(DESTDIR)$(NMXMPDIR)/zones
