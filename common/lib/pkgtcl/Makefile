DESTDIR = /usr/local/lib/webdns/pkgtcl
TCLSH = tclsh

FILES =	\
	webapp.tcl \
	arrgen.tcl \
	pgsql.tcl \
	auth.tcl

all:	pkgIndex.tcl

pkgIndex.tcl:	$(FILES)
	echo "pkg_mkIndex ." | $(TCLSH)
	chmod g+w pkgIndex.tcl

install: all
	install -m 0644 *.tcl *.n $(DESTDIR)

clean:
	rm -f pkgIndex.tcl 
