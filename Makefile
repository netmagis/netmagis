# $Id$

LISTE =	\
	webapp.tcl \
	arrgen.tcl \
	pgsql.tcl \
	annuaire.tcl	\
	auth.tcl

all:	pkgIndex.tcl

pkgIndex.tcl:	$(LISTE)
	echo "pkg_mkIndex ." | tclsh8.5
	chmod g+w pkgIndex.tcl

clean:
	rm -f pkgIndex.tcl 
