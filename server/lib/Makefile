NINSTALL	= ../../ninstall

build:
	@echo ">>> Making build in `pwd`"
	cd pkgtcl ; $(MAKE) build

install:
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)$(NMLIBDIR)
	cd pkgtcl ; $(MAKE) install
	cd worker ; $(MAKE) install
	cd upgrade ; $(MAKE) install
	tar cf - sql* *.sql | tar xf - -C $(DESTDIR)$(NMLIBDIR)

clean:
	cd pkgtcl ; $(MAKE) clean
