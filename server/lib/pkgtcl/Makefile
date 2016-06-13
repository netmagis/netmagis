NINSTALL	= ../../../ninstall
TCLSH		= /usr/local/bin/tclsh

FILES =	\
	dbconf.tcl \
	lconf.tcl \
	pgdb.tcl \
	scgi.tcl \

build:	pkgIndex.tcl
	@echo ">>> Making build in `pwd`"

pkgIndex.tcl:	$(FILES)
	echo "pkg_mkIndex ." | $(TCLSH)
	chmod g+w pkgIndex.tcl

install: build
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)$(NMLIBDIR)/pkgtcl
	$(NINSTALL) -m 0644 \
		    $(SUBST) \
		    $(FILES) $(DESTDIR)$(NMLIBDIR)/pkgtcl ; \
	done

clean:
	rm -f pkgIndex.tcl 
