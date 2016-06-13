NINSTALL	= ../ninstall

build:
	@echo ">>> Making build in `pwd`"
	cd lib ; $(MAKE) build

install:
	@echo ">>> Making install in `pwd`"
	cd etc ; $(MAKE) install
	cd bin ; $(MAKE) install
	cd lib ; $(MAKE) install
	cd www ; $(MAKE) install
	cd examples ; $(MAKE) install
	mkdir -p $(DESTDIR)$(NMVARDIR)/dbdump

clean:
	cd lib ; $(MAKE) clean
