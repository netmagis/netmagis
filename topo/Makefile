DESTDIR		= /usr/local
TCLSH		= /usr/local/bin/tclsh

all:
	@echo ">>> Making all in `pwd`"
	cd lib ; make
	cd src ; make

install: all
	@echo ">>> Making install in `pwd`"
	cd src ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) install
	cd etc ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) install
	mkdir -p $(DESTDIR)/var/netmagis
	mkdir -p $(DESTDIR)/var/netmagis/eqvirt
	mkdir -p $(DESTDIR)/var/netmagis/eqgen

clean:
	cd lib ; make clean
	cd src ; make clean
