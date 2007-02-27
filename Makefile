# $Id: Makefile,v 1.2 2007-02-27 13:04:48 pda Exp $

LISTE =	\
	webapp.tcl \
	arrgen.tcl \
	pgsql.tcl \
	annuaire.tcl	\
	auth.tcl

all:	pkgIndex.tcl trpw

pkgIndex.tcl:	$(LISTE)
	echo "pkg_mkIndex ." | tclsh8.4
	chmod g+w pkgIndex.tcl

trpw:	trpw.c
	cc -o trpw trpw.c -lcrypt

clean:
	rm -f pkgIndex.tcl 
	rm -f trpw *.o
