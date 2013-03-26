NINSTALL	= ../../ninstall

SCRIPTS = \
	netmagis-dbcreate \
	netmagis-dbimport \
	netmagis-dbmaint

install:
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)$(SBINDIR)
	$(NINSTALL) -m 0755 -e "s|%NMLIBDIR%|$(NMLIBDIR)|" $(SUBST) \
		$(SCRIPTS) $(DESTDIR)$(SBINDIR)
