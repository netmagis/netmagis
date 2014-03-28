NINSTALL	= ../../ninstall

install:
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)$(NMLIBDIR)
	cd upgrade ; make $(DIRS) install
	tar cf - sql* *.sql | tar xf - -C $(DESTDIR)$(NMLIBDIR)
