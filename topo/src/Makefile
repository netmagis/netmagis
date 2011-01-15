DESTDIR		= /usr/local
TCLSH		= /usr/local/bin/tclsh
SINSTALL	= ../../inst/install-script
SUBST		= $(TCLSH) \
			$(DESTDIR)/lib/netmagis/libdns.tcl \
			$(DESTDIR)/etc/netmagis.conf \
			$(DESTDIR)/bin/netmagis-config

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
	analyze	\
	cache		\
	checkdns	\
	decodename	\
	doteq		\
	list-rancid	\
	list-vlans	\
	parse-hp.tcl	\
	parse-cisco.tcl	\
	parse-juniper.tcl	\
	ssidsensors	\
	topographd	\
	toposendd	\
	updatecache	\
	start-rancid	\
	sendmail

all:	$(PROGS)
	@echo ">>> Making all in `pwd`"

dumpgraph:	dumpgraph.c	$(LIBDIR)/libgraph.a
buildgraph:	buildgraph.c	$(LIBDIR)/libgraph.a
extractl1:	extractl1.c	$(LIBDIR)/libgraph.a
extractl2:	extractl2.c	$(LIBDIR)/libgraph.a
extractl3:	extractl3.c	$(LIBDIR)/libgraph.a
extracteq:	extracteq.c	$(LIBDIR)/libgraph.a
extractcoll:	extractcoll.c	$(LIBDIR)/libgraph.a
getnetif:	getnetif.c	$(LIBDIR)/libgraph.a

install: $(PROGS) $(SCRIPTS)
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)/lib/netmagis/topo
	install -m 0755 $(PROGS) $(DESTDIR)/lib/netmagis/topo
	$(SINSTALL) -m 0755 $(SUBST) $(SCRIPTS) $(DESTDIR)/lib/netmagis/topo

clean:
	rm -f *.o $(PROGS) *.core
