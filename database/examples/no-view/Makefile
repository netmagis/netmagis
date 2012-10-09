NINSTALL	= ../../../ninstall

SCRIPTS = \
	run-all.sh

FILES = *.txt \
	README

DEST =	$(DESTDIR)$(NMXMPDIR)/no-view

install:
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DEST)
	$(NINSTALL) -m 0755 -e "s|%SBINDIR%|$(SBINDIR)|" $(SUBST) \
			$(SCRIPTS) $(DEST)
	$(NINSTALL) -m 0644 -e "s|%SBINDIR%|$(SBINDIR)|" $(SUBST) \
			$(FILES) $(DEST)
	mkdir -p $(DEST)/zones
	install -m 0644 zones/* $(DEST)/zones
