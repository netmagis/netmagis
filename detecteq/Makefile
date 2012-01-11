DESTDIR		= /usr/local
TCLSH		= /usr/local/bin/tclsh

build:
	@echo ">>> Making build in `pwd`"

install: build
	@echo ">>> Making install in `pwd`"
	cd syslog ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) install
	cd radius ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) install

clean:
