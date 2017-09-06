NINSTALL	= ../../../ninstall

SRCS =	\
	lconf.tcl \
	nmenv.tcl \
	nmjson.tcl \
	pgdb.tcl \
	scgi.tcl \
	rr.tcl \
	auth.tcl \

FILES = $(SRCS) pkgIndex.tcl

build:	pkgIndex.tcl
	@echo ">>> Making build in `pwd`"

pkgIndex.tcl:	$(SRCS)
	echo "pkg_mkIndex ." | tclsh
	# chmod g+w pkgIndex.tcl

install: build
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)$(NMLIBDIR)/pkgtcl
	$(NINSTALL) -m 0644 \
		    -e "s|%NMVERSION%|$(VERSION)|" \
		    $(SUBST) \
		    $(FILES) \
		    $(DESTDIR)$(NMLIBDIR)/pkgtcl ; \
	done

clean:
	rm -f pkgIndex.tcl 
