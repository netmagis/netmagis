NINSTALL	= ../../../ninstall

TCLSH		= /usr/local/bin/tclsh

FILES =	\
	pgdb.tcl \
	scgi.tcl \
	worker.tcl \

# XXXXXXXXXXXXXXX
####build:	pkgIndex.tcl
####	@echo ">>> Making build in `pwd`"

install: ################## build
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)$(NMLIBDIR)/tcl
	install -m 0644 *.tcl $(DESTDIR)$(NMLIBDIR)/tcl

# XXXXXXXXXXXXXXX
pkgIndex.tcl:	$(FILES)
	echo "pkg_mkIndex ." | $(TCLSH)
	chmod g+w pkgIndex.tcl

# XXXXXXXXXXXXXXX
clean:
	rm -f pkgIndex.tcl 
