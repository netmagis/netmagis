NINSTALL	= ../../ninstall

build:
	@echo ">>> Making build in `pwd`"

install:
	@echo ">>> Making install in `pwd`"
	mkdir -p $(NMLIBDIR)/$(NMLIBDIR)
	$(NINSTALL) -m 0755 -e 's|%NMLIBDIR%|$(NMLIBDIR)|' $(SUBST) *.pl \
			$(DESTDIR)$(NMLIBDIR)
	mkdir -p $(DESTDIR)$(NMLIBDIR)/probes
	$(NINSTALL) -m 0755 -e 's|%NMLIBDIR%|$(NMLIBDIR)|' $(SUBST) probes/*.pl \
			$(DESTDIR)$(NMLIBDIR)/probes
	mkdir -p $(DESTDIR)$(NMLIBDIR)/plugins
	$(NINSTALL) -m 0755 -e 's|%NMLIBDIR%|$(NMLIBDIR)|' $(SUBST) plugins/* \
			$(DESTDIR)$(NMLIBDIR)/plugins

clean:
