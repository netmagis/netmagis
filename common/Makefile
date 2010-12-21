DESTDIR		= /usr/local
TCLSH		= /usr/local/bin/tclsh

all:
	@echo ">>> Making all in `pwd`"

install:
	@echo ">>> Making install in `pwd`"
	cd etc ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) install
	cd bin ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) install
	cd lib ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) install

clean:
