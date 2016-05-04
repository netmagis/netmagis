NINSTALL	= ../../ninstall

SCRIPTS = \
	netmagis-config \
	netmagis-dbcreate \
	netmagis-dbimport \
	netmagis-dbmaint \
	netmagis-dbupgrade \
	netmagis-getoui \
	netmagis-restd \

install:
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)$(BINDIR)
	$(NINSTALL) -m 0755 \
		-e "s|%NMLIBDIR%|$(NMLIBDIR)|" \
		-e "s|%BINDIR%|$(BINDIR)|" $(SUBST) \
		$(SCRIPTS) $(DESTDIR)$(BINDIR)
