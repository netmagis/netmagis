NINSTALL	= ../../../ninstall
TCLSH		= /usr/local/bin/tclsh

SRCS =	\
	lconf.tcl \
	nmenv.tcl \
	pgdb.tcl \
	scgi.tcl \

FILES = $(SRCS) pkgIndex.tcl

build:	pkgIndex.tcl
	@echo ">>> Making build in `pwd`"

pkgIndex.tcl:	$(SRCS)
	echo "pkg_mkIndex ." | $(TCLSH)
	# chmod g+w pkgIndex.tcl

install: build
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)$(NMLIBDIR)/pkgtcl
	$(NINSTALL) -m 0644 \
		    $(SUBST) \
		    $(FILES) \
		    $(DESTDIR)$(NMLIBDIR)/pkgtcl ; \
	done

clean:
	rm -f pkgIndex.tcl 
