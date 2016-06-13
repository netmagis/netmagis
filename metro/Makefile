NINSTALL	= ../ninstall

SHARE	= crontab.metro apache-metro.conf

SUBDIRS = cache lock log db spool graph wifi report

build:
	@echo ">>> Making build in `pwd`"

install:
	@echo ">>> Making install in `pwd`"
	cd bin ; $(MAKE) install
	cd lib ; $(MAKE) install
	cd ws ; $(MAKE) install
	mkdir -p $(DESTDIR)$(NMXMPDIR)
	$(NINSTALL) -m 0644 \
		-e "s|%BINDIR%|$(BINDIR)|" \
		-e "s|%NMWSDIR%|$(NMWSDIR)|" \
		$(SUBST) $(SHARE) $(DESTDIR)$(NMXMPDIR)
	mkdir -p $(DESTDIR)$(NMVARDIR)/metro
	for i in $(SUBDIRS); do \
		mkdir -p $(DESTDIR)$(NMVARDIR)/metro/$$i; \
	done

clean:
