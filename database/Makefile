DESTDIR		= /usr/local
TCLSH		= /usr/local/bin/tclsh

build:
	@echo ">>> Making build in `pwd`"

install:
	@echo ">>> Making install in `pwd`"
	cd sbin ; make $(DIRS) install
	cd examples ; make $(DIRS) install
	cd upgrade  ; make $(DIRS) install
	mkdir -p $(DESTDIR)$(NMVARDIR)/dbdump

clean:
