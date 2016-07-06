NINSTALL	= ../../ninstall

FILES = crontab.database \
	apache.conf \
	nginx.conf

install:
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)$(NMXMPDIR)
	$(NINSTALL) -m 0644 -e "s|%SBINDIR%|$(SBINDIR)|" $(SUBST) \
			$(FILES) $(DESTDIR)$(NMXMPDIR)
	cd no-view ; $(MAKE) install
	cd with-views ; $(MAKE) install

clean:
	cd no-view ; $(MAKE) clean
	cd with-views ; $(MAKE) clean
