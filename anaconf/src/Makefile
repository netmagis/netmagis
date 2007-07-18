#
# $Id: Makefile,v 1.2 2007-07-18 15:09:53 pda Exp $
#

DESTDIR=/local/applis/topo

LIBDIR = ../lib

CFLAGS = -g -Wall -I$(LIBDIR)
LDFLAGS = -L$(LIBDIR)
LDLIBS = -lgraph

PROGS = \
	dumpgraph	\
	dumpcoll	\
	buildgraph	\
	extractl1	\
	extractl2	\
	extractl3	\
	extracteq	\
	extractcoll	\
	locatecoll	\
	getnetif

SCRIPTS = \
	anaconf		\
	analyser	\
	checkdns	\
	doteq		\
	liste-rancid	\
	liste-vlans	\
	parse-cisco.tcl	\
	parse-juniper.tcl	\
	sendcoll

all:	$(PROGS)

dumpgraph:	dumpgraph.c	$(LIBDIR)/libgraph.a
dumpcoll:	dumpcoll.c	$(LIBDIR)/libgraph.a
buildgraph:	buildgraph.c	$(LIBDIR)/libgraph.a
extractl1:	extractl1.c	$(LIBDIR)/libgraph.a
extractl2:	extractl2.c	$(LIBDIR)/libgraph.a
extractl3:	extractl3.c	$(LIBDIR)/libgraph.a
extracteq:	extracteq.c	$(LIBDIR)/libgraph.a
extractcoll:	extractcoll.c	$(LIBDIR)/libgraph.a
locatecoll:	locatecoll.c	$(LIBDIR)/libgraph.a
getnetif:	getnetif.c	$(LIBDIR)/libgraph.a

install: $(PROGS) $(SCRIPTS)
	test -d $(DESTDIR)/bin || mkdir $(DESTDIR)/bin
	chmod 775 $(DESTDIR)/bin
	for i in $(PROGS) $(SCRIPTS) ; \
	do \
		install -m 0775 $$i $(DESTDIR)/bin ; \
	done

clean:
	rm -f *.o $(PROGS) *.core
