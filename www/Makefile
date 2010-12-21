DESTDIR	= /usr/local
TCLSH	= /usr/local/bin/tclsh
SINSTALL = ../inst/install-script
SUBST	= $(TCLSH) \
	$(DESTDIR)/lib/webdns/libdns.tcl \
	$(DESTDIR)/etc/webdns.conf \
	$(DESTDIR)/bin/webdns-config

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
	mkdir -p $(DESTDIR)/www/webdns
	cd cgi ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) install
	#
	# install ps2pdf
	#
	mkdir -p $(DESTDIR)/lib/webdns
	install -m 0755 ps2pdf $(DESTDIR)/lib/webdns/
	#
	# install tmpl pages
	#
	mkdir -p $(DESTDIR)/lib/webdns/tmpl
	./htg/src/htg2html -g htg/src -d htg/models -m default \
			-c ./htg/src/htgtcl \
			tmpl /tmp/htg.$$ $(DESTDIR)/lib/webdns/tmpl
	cd $(DESTDIR)/lib/webdns/tmpl ; ln -s en C
	#
	# install css and images
	#
	rm -f $(DESTDIR)/www/webdns/css
	ln -s $(DESTDIR)/www/webdns/models/default/css $(DESTDIR)/www/webdns
	#
	# install default files
	#
	tar cf - defaults | tar xf - -C $(DESTDIR)/lib/webdns

clean:
	cd htg ; make clean
