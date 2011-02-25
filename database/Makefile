DESTDIR		= /usr/local
TCLSH		= /usr/local/bin/tclsh

all:
	@echo ">>> Making all in `pwd`"

install:
	@echo ">>> Making install in `pwd`"
	cd sbin ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) install
	cd examples ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) install

clean:
