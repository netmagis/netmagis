NINSTALL	= ../../../ninstall
TCLSH		= /usr/local/bin/tclsh

FILES =	\
	scgi.tcl \
	pgdb.tcl \
	lconf.tcl \
	dbconf.tcl \

build:	pkgIndex.tcl
	@echo ">>> Making build in `pwd`"

pkgIndex.tcl:	$(FILES)
	echo "pkg_mkIndex ." | $(TCLSH)
	chmod g+w pkgIndex.tcl

install: build
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)$(NMLIBDIR)/pkgtcl
	for F in *.tcl ; do \
	    $(NINSTALL) -m 0644 \
		    -e "s|%NMVERSION%|$(VERSION)|" \
		    $(SUBST) $$F $(DESTDIR)$(NMLIBDIR)/pkgtcl ; \
	done

clean:
	rm -f pkgIndex.tcl 
