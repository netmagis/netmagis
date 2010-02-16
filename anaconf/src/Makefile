#
# $Id: Makefile,v 1.6 2008-07-30 08:48:49 pda Exp $
#

TOPODIR=/local/applis/topo

LIBDIR = ../lib

CFLAGS = -g -Wall -I$(LIBDIR)
LDFLAGS = -L$(LIBDIR)
LDLIBS = -lgraph

PROGS = \
	dumpgraph	\
	buildgraph	\
	extractl1	\
	extractl2	\
	extractl3	\
	extracteq	\
	extractcoll	\
	getnetif

SCRIPTS = \
	anaconf		\
	analyser	\
	checkdns	\
	doteq		\
	ssidprobes	\
	liste-rancid	\
	liste-vlans	\
	parse-hp.tcl	\
	parse-cisco.tcl	\
	parse-juniper.tcl	\
	sendcoll

SUBST = \
        -e 's|%TOPODIR%|$(TOPODIR)|'


all:	$(PROGS)

dumpgraph:	dumpgraph.c	$(LIBDIR)/libgraph.a
buildgraph:	buildgraph.c	$(LIBDIR)/libgraph.a
extractl1:	extractl1.c	$(LIBDIR)/libgraph.a
extractl2:	extractl2.c	$(LIBDIR)/libgraph.a
extractl3:	extractl3.c	$(LIBDIR)/libgraph.a
extracteq:	extracteq.c	$(LIBDIR)/libgraph.a
extractcoll:	extractcoll.c	$(LIBDIR)/libgraph.a
getnetif:	getnetif.c	$(LIBDIR)/libgraph.a

install: $(PROGS) $(SCRIPTS)
	test -d $(TOPODIR)/bin || mkdir $(TOPODIR)/bin
	chmod 775 $(TOPODIR)/bin
	for i in $(SCRIPTS) ; \
	do \
		sed $(SUBST) $$i > $(TOPODIR)/bin/$$i ; \
		chmod 0775 $(TOPODIR)/bin/$$i ; \
	done
	for i in $(PROGS) ; \
	do \
		install -m 0775 $$i $(TOPODIR)/bin ; \
	done

clean:
	rm -f *.o $(PROGS) *.core
