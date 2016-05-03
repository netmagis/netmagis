NINSTALL	= ../../ninstall

build:
	@echo ">>> Making build in `pwd`"
	cd pkgtcl ; make build

install:
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)$(NMLIBDIR)
	cd pkgtcl ; make $(DIRS) install
	cd worker ; make $(DIRS) install
	cd upgrade ; make $(DIRS) install
	tar cf - sql* *.sql | tar xf - -C $(DESTDIR)$(NMLIBDIR)

clean:
	cd pkgtcl ; make clean
