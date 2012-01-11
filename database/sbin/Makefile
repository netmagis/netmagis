NINSTALL	= ../../ninstall

SCRIPTS = \
	netmagis-dbcreate \
	netmagis-dbimport \
	netmagis-maint

install:
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)/$(SBINDIR)
	$(NINSTALL) -m 0755 $(SUBST) $(SCRIPTS) $(DESTDIR)/$(SBINDIR)
