NINSTALL	= ../ninstall

build:
	@echo ">>> Making build in `pwd`"
	cd lib ; $(MAKE) build
	cd man ; $(MAKE) build

install:
	@echo ">>> Making install in `pwd`"
	cd etc ; $(MAKE) install
	cd bin ; $(MAKE) install
	cd man ; $(MAKE) clean
	cd lib ; $(MAKE) install
	cd www ; $(MAKE) install
	cd examples ; $(MAKE) install
	mkdir -p $(DESTDIR)$(NMVARDIR)/dbdump

clean:
	cd lib ; $(MAKE) clean
	cd man ; $(MAKE) clean
