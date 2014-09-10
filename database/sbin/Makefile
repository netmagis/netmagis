NINSTALL	= ../../ninstall

SCRIPTS = \
	netmagis-dbcreate \
	netmagis-dbimport \
	netmagis-dbmaint \
	netmagis-dbupgrade \
	netmagis-getoui

install:
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)$(SBINDIR)
	$(NINSTALL) -m 0755 \
		-e "s|%NMLIBDIR%|$(NMLIBDIR)|" \
		-e "s|%SBINDIR%|$(SBINDIR)|" $(SUBST) \
		$(SCRIPTS) $(DESTDIR)$(SBINDIR)
