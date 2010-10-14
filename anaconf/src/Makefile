#
# $Id$
#

TOPODIR=/local/applis/topo
GRAPH=$(TOPODIR)/osiris/osiris.graph

# pour topod
BASE="{host=dbcrc.u-strasbg.fr dbname=dns user=dns password=pas-fou-non}"
DELAY=5					# delai entre itérations de topod
PKGTCL=
LIBDNS=
FPING=



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
	decodename	\
	doteq		\
	liste-rancid	\
	liste-vlans	\
	parse-hp.tcl	\
	parse-cisco.tcl	\
	parse-juniper.tcl	\
	sendcoll \
	ssidprobes \
	topod

SUBST = \
        -e 's|%TCLSH%|$(TCLSH)|' \
        -e 's|%FPING%|$(FPING)|' \
        -e 's|%GRAPH%|$(GRAPH)|' \
        -e 's|%TOPODIR%|$(TOPODIR)|' \
        -e 's|%BASE%|$(BASE)|' \
        -e 's|%LIBDNS%|$(LIBDNS)|' \
        -e 's|%PKGTCL%|$(PKGTCL)|' \
        -e 's|%DELAY%|$(DELAY)|' \
	-e 's|%RANCIDMODUSER%|$(RANCIDMODUSER)|' \
	-e 's|%RANCIDMODPASS%|$(RANCIDMODPASS)|'


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
