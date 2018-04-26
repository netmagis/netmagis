TCLSH		= /usr/local/bin/tclsh

FILES =	\
	webapp.tcl \
	arrgen.tcl \
	pgsql.tcl

build:	pkgIndex.tcl
	@echo ">>> Making build in `pwd`"

pkgIndex.tcl:	$(FILES)
	echo "pkg_mkIndex ." | $(TCLSH)
	chmod g+w pkgIndex.tcl

install: build
	@echo ">>> Making install in `pwd`"
	install -m 0644 *.tcl *.n $(DESTDIR)$(NMLIBDIR)/pkgtcl
	# Ugly hack (see issue #168)
	install -m 0644 ldap-bug-fix.192 *.n $(DESTDIR)$(NMLIBDIR)/pkgtcl

clean:
	rm -f pkgIndex.tcl 
