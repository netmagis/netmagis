DESTDIR	= /usr/local
TCLSH	= /usr/local/bin/tclsh
SINSTALL = ../inst/install-script
SUBST	= $(TCLSH) $(DESTDIR)/lib/webdns/libdns.tcl $(DESTDIR)/etc/webdns.conf

TCLCFLAGS	= -I/usr/local/include/tcl8.5
TCLLFLAGS	= -L/usr/local/lib -ltcl85 -lm

all:
	cd htg ; make TCLCFLAGS="$(TCLCFLAGS)" TCLLFLAGS="$(TCLLFLAGS)"

install: all
	mkdir -p $(DESTDIR)/www/webdns
	cd bin ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) install
	mkdir -p $(DESTDIR)/lib/webdns
	install -m 0755 ps2pdf $(DESTDIR)/lib/webdns/
	cd htg ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) \
		TCLCFLAGS="$(TCLCFLAGS)" TCLLFLAGS="$(TCLLFLAGS)" install
	mkdir -p $(DESTDIR)/lib/webdns/tmpl.src
	tar cf - -C tmpl . | tar xf - -C $(DESTDIR)/lib/webdns/tmpl.src
	mkdir -p $(DESTDIR)/lib/webdns/tmpl
	tar cf - defaults | tar xf - -C $(DESTDIR)/lib/webdns

clean:
	cd htg ; make clean
