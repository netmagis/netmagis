NINSTALL	= ../ninstall

build:
	@echo ">>> Making build in `pwd`"

install:
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)$(ETCDIR)
	$(NINSTALL) -m 0644 \
			-e "s|%ETCDIR%|$(ETCDIR)|" \
			-e "s|%CAFILE%|$(CAFILE)|" \
			-e "s|%NMLIBDIR%|$(NMLIBDIR)|" \
			-e "s|%NMVARDIR%|$(NMVARDIR)|" \
			$(SUBST) netmagis.conf.sample $(DESTDIR)$(ETCDIR)
	mkdir -p $(DESTDIR)$(BINDIR)
	$(NINSTALL) -m 0755 $(SUBST) netmagis-config $(DESTDIR)$(BINDIR)
	mkdir -p $(DESTDIR)$(NMLIBDIR)
	$(NINSTALL) -m 0644 -e "s/%NMVERSION%/$(VERSION)/" \
		$(SUBST) libnetmagis.tcl $(DESTDIR)$(NMLIBDIR)
	mkdir -p $(DESTDIR)$(NMLIBDIR)/pkgtcl
	cd pkgtcl && make $(DIRS) TCLSH=$(TCLSH) clean install
	mkdir -p $(DESTDIR)$(NMLIBDIR)/msgs 
	tar cf - msgs | tar xvf - -C $(DESTDIR)$(NMLIBDIR)

clean:
