NINSTALL	= ../ninstall

build:
	@echo ">>> Making build in `pwd`"
	cd lib ; make build

install:
	@echo ">>> Making install in `pwd`"
	cd etc ; make $(DIRS) install
	cd bin ; make $(DIRS) install
	cd lib ; make $(DIRS) install
	cd examples ; make $(DIRS) install
	mkdir -p $(DESTDIR)$(NMVARDIR)/dbdump

clean:
	cd lib ; make clean
