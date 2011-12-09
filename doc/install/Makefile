DESTDIR	= /www/docs/install
TCLSH	= /usr/local/bin/tclsh
NINSTALL = ../../ninstall
SUBST	= $(TCLSH) \
		$(DESTDIR)/lib/netmagis/libnetmagis.tcl \
		$(DESTDIR)/etc/netmagis.conf \
		$(DESTDIR)/bin/netmagis-config

HTGDIR	= ../../www/htg
HTGBINDIR = $(HTGDIR)/src

install:
	@echo ">>> Making install in `pwd`"
	#
	# install HTML files
	#
	mkdir -p $(DESTDIR)
	for i in *.htgt* ; \
	do \
	    h=`echo $$i | sed 's/\.htgt/\.html/'` ; \
	    $(HTGBINDIR)/htgtcl $(HTGBINDIR)/htg -d $(HTGDIR)/models \
			-m default $$i > $(DESTDIR)/$$h \
		    || exit 1 ; \
	done
	#
	# install CSS and images
	#
	cd $(DESTDIR) ; if [ ! -L css ] ; then ln -s ../css . ; fi

#	rm -rf $(DESTDIR)/css
#	tar cf - -C $(HTGDIR)/models/netmagis css | tar xvf - -C $(DESTDIR)
#	#
#	# install PNG files
#	#
#	cp *.png.?? $(DESTDIR)

clean:
