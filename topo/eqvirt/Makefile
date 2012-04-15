NINSTALL	= ../../ninstall

FILES = README *.eq

install:
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)$(NMXMPDIR)
	mkdir -p $(DESTDIR)$(NMXMPDIR)/eqvirt
	install -m 0644 $(FILES) $(DESTDIR)$(NMXMPDIR)/eqvirt
