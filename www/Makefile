DESTDIR	= /usr/local
TCLSH	= /usr/local/bin/tclsh
NINSTALL = ../ninstall
SUBST	= $(TCLSH) \
		$(DESTDIR)/lib/netmagis/libnetmagis.tcl \
		$(DESTDIR)/etc/netmagis.conf \
		$(DESTDIR)/bin/netmagis-config

TCLCFLAGS	= -I/usr/local/include/tcl8.5
TCLLFLAGS	= -L/usr/local/lib -ltcl85 -lm

all:
	@echo ">>> Making all in `pwd`"
	cd htg ; make TCLCFLAGS="$(TCLCFLAGS)" TCLLFLAGS="$(TCLLFLAGS)"

install: all
	@echo ">>> Making install in `pwd`"
	#
	# install CGI
	#
	mkdir -p $(DESTDIR)/www/netmagis
	cd cgi ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) install
	#
	# install ps2pdf
	#
	mkdir -p $(DESTDIR)/lib/netmagis
	install -m 0755 ps2pdf $(DESTDIR)/lib/netmagis/
	#
	# install htg and models
	#
	cd htg ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) install
	#
	# install tmpl pages
	#
	mkdir -p $(DESTDIR)/lib/netmagis/tmpl
	./htg/src/htg2html -b htg/src -d htg/models -m default \
			tmpl /tmp/htgtmp $(DESTDIR)/lib/netmagis/tmpl
	rm -rf /tmp/htgtmp
	cd $(DESTDIR)/lib/netmagis/tmpl ; ln -s en C
	#
	# install css and images
	#
	rm -f $(DESTDIR)/www/netmagis/css
	ln -s $(DESTDIR)/lib/netmagis/htg/models/default/css $(DESTDIR)/www/netmagis
	#
	# install default files
	#
	tar cf - -C share . | tar xf - -C $(DESTDIR)/share/examples/netmagis

clean:
	cd htg ; make clean
