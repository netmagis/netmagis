DESTDIR		= /usr/local
TCLSH		= /usr/local/bin/tclsh

all:
	@echo ">>> Making all in `pwd`"

install: all
	@echo ">>> Making install in `pwd`"
	cd syslog ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) install
	cd radius ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) install

clean:
