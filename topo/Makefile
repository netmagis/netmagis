NINSTALL	= ../ninstall

build:
	@echo ">>> Making build in `pwd`"
	cd lib ; make build
	cd src ; make build

install: build
	@echo ">>> Making install in `pwd`"
	cd src ; make $(DIRS) install
	cd rc ; make $(DIRS) install
	cd eqvirt ; make $(DIRS) install
	mkdir -p $(DESTDIR)$(NMVARDIR)/eqvirt
	mkdir -p $(DESTDIR)$(NMVARDIR)/eqgen

clean:
	cd lib ; make clean
	cd src ; make clean
