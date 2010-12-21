DESTDIR		= /usr/local
TCLSH		= /usr/local/bin/tclsh

FILES =	\
	webapp.tcl \
	arrgen.tcl \
	pgsql.tcl \
	auth.tcl

all:	pkgIndex.tcl
	@echo ">>> Making all in `pwd`"

pkgIndex.tcl:	$(FILES)
	echo "pkg_mkIndex ." | $(TCLSH)
	chmod g+w pkgIndex.tcl

install: all
	@echo ">>> Making install in `pwd`"
	install -m 0644 *.tcl *.n $(DESTDIR)

clean:
	rm -f pkgIndex.tcl 
