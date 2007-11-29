# $Id: Makefile,v 1.3 2007-11-29 15:27:45 pda Exp $

LISTE =	\
	webapp.tcl \
	arrgen.tcl \
	pgsql.tcl \
	annuaire.tcl	\
	auth.tcl

all:	pkgIndex.tcl

pkgIndex.tcl:	$(LISTE)
	echo "pkg_mkIndex ." | tclsh8.4
	chmod g+w pkgIndex.tcl

clean:
	rm -f pkgIndex.tcl 
