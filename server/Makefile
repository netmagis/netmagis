NINSTALL	= ../ninstall

build:
	@echo ">>> Making build in `pwd`"
	cd lib ; $(MAKE) build
	cd man ; $(MAKE) build
	cd www ; $(MAKE) build

install:
	@echo ">>> Making install in `pwd`"
	cd etc ; $(MAKE) install
	cd bin ; $(MAKE) install
	cd man ; $(MAKE) install
	cd lib ; $(MAKE) install
	cd www ; $(MAKE) install
	cd examples ; $(MAKE) install
	mkdir -p $(DESTDIR)$(NMVARDIR)/dbdump

test:
	@echo ">>> Making test in `pwd`"
	cd tests ; $(MAKE) test

clean:
	cd lib ; $(MAKE) clean
	cd man ; $(MAKE) clean
	cd www ; $(MAKE) clean
