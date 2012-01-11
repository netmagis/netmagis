NINSTALL	= ../../ninstall

install:
	@echo ">>> Making install in `pwd`"
	mkdir -p $(NMLIBDIR)/$(NMLIBDIR)
	$(NINSTALL) -m 0755 -e 's|%NMLIBDIR%|$(NMLIBDIR)|' $(SUBST) *.pl \
			$(NMLIBDIR)/$(NMLIBDIR)
	mkdir -p $(NMLIBDIR)/$(NMLIBDIR)/probes
	$(NINSTALL) -m 0755 -e 's|%NMLIBDIR%|$(NMLIBDIR)|' $(SUBST) probes/*.pl \
			$(NMLIBDIR)/$(NMLIBDIR)/probes
	mkdir -p $(NMLIBDIR)/$(NMLIBDIR)/plugins
	$(NINSTALL) -m 0755 -e 's|%NMLIBDIR%|$(NMLIBDIR)|' $(SUBST) plugins/* \
			$(NMLIBDIR)/$(NMLIBDIR)/plugins
