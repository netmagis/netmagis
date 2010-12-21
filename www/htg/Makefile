DESTDIR		= /usr/local
TCLSH		= /usr/local/bin/tclsh
SINSTALL	= ../../inst/install-script
SUBST		= $(TCLSH) \
			$(DESTDIR)/lib/webdns/libdns.tcl \
			$(DESTDIR)/etc/webdns.conf \
			$(DESTDIR)/bin/webdns-config

TCLCFLAGS	= -I/usr/local/include/tcl8.5
TCLLFLAGS	= -L/usr/local/lib -ltcl85 -lm

all:
	@echo ">>> Making all in `pwd`"
	cd src ; make TCLCFLAGS="$(TCLCFLAGS)" TCLLFLAGS="$(TCLLFLAGS)" all

install: all
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)/bin
	cd src ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) install
	mkdir -p $(DESTDIR)/lib/webdns/htg
	tar cf - models doc | tar xf - -C $(DESTDIR)/lib/webdns/htg

clean:
	cd src ; make clean
