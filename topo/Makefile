NINSTALL	= ../ninstall

build:
	@echo ">>> Making build in `pwd`"
	cd lib ; $(MAKE) build
	cd src ; $(MAKE) build

install: build
	@echo ">>> Making install in `pwd`"
	cd src ; $(MAKE) install
	cd eqvirt ; $(MAKE) install
	mkdir -p $(DESTDIR)$(NMVARDIR)/eqvirt
	mkdir -p $(DESTDIR)$(NMVARDIR)/eqgen

clean:
	cd lib ; $(MAKE) clean
	cd src ; $(MAKE) clean
