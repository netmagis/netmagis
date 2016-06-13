NINSTALL = ../ninstall

build:
	@echo ">>> Making build in `pwd`"
	cd htg ; $(MAKE) TCLCFLAGS="$(TCLCFLAGS)" TCLLFLAGS="$(TCLLFLAGS)" build

install: build
	@echo ">>> Making install in `pwd`"
	#
	# install CGI
	#
	mkdir -p $(DESTDIR)$(NMCGIDIR)
	cd cgi ; $(MAKE) install
	#
	# install API
	#
	mkdir -p $(DESTDIR)$(NMCGIDIR)
	cd nmd ; $(MAKE) install

	############################## WARNING : REMOVE AS SOON AS POSSIBLE
		exit 1
	############################## WARNING :

	#
	# install ps2pdf
	#
	mkdir -p $(DESTDIR)$(NMLIBDIR)
	install -m 0755 ps2pdf $(DESTDIR)$(NMLIBDIR)
	#
	# install htg and models
	#
	cd htg ; $(MAKE) install
	#
	# install tmpl pages
	#
	mkdir -p $(DESTDIR)$(NMLIBDIR)/tmpl
	./htg/src/htg2html -b htg/src -d htg/models -m default \
			tmpl /tmp/htgtmp $(DESTDIR)$(NMLIBDIR)/tmpl
	rm -rf /tmp/htgtmp
	cd $(DESTDIR)$(NMLIBDIR)/tmpl ; ln -s en C
	#
	# install css and images
	#
	rm -f $(DESTDIR)$(NMCGIDIR)/css
	ln -s $(NMLIBDIR)/htg/models/default/css $(DESTDIR)$(NMCGIDIR)
	#
	# install default files
	#
	cd share ; $(MAKE) install

clean:
	cd htg ; $(MAKE) clean
