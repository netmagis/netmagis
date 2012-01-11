NINSTALL	= ../../ninstall

FILES = *.conf

install:
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)/$(NMXMPDIR)/radius
	$(NINSTALL) -m 0644 $(SUBST) $(FILES) $(DESTDIR)/$(NMXMPDIR)/radius
