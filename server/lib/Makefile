NINSTALL	= ../../ninstall

build:
	@echo ">>> Making build in `pwd`"
	cd pkgtcl ; make build

install:
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)$(NMLIBDIR)
	cd pkgtcl ; make DIRS="$(DIRS)" SUBST="$(SUBST)" VERSION=$(VERSION) install
	cd worker ; make DIRS="$(DIRS)" SUBST="$(SUBST)" install
	cd upgrade ; make $(DIRS) SUBST="$(SUBST)" install
	tar cf - sql* *.sql | tar xf - -C $(DESTDIR)$(NMLIBDIR)

clean:
	cd pkgtcl ; make clean
