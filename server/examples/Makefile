NINSTALL	= ../../ninstall

FILES = crontab.database

install:
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)$(NMXMPDIR)
	$(NINSTALL) -m 0644 -e "s|%SBINDIR%|$(SBINDIR)|" $(SUBST) \
			$(FILES) $(DESTDIR)$(NMXMPDIR)
	cd no-view ; make $(DIRS) install
	cd with-views ; make $(DIRS) install

clean:
	cd no-view ; make clean
	cd with-views ; make clean
