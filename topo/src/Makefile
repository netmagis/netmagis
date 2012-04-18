NINSTALL	= ../../ninstall

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
	checkdns	\
	decodename	\
	doteq		\
	list-rancid	\
	list-vlans	\
	ssidsensors	\
	start-rancid	\
	sendmail

DAEMONS = \
	topographd	\
	toposendd

LIBS	= \
	parse-hp.tcl	\
	parse-cisco.tcl	\
	parse-juniper.tcl	\
	parse-server.tcl

build:	$(PROGS)
	@echo ">>> Making build in `pwd`"

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
	mkdir -p $(DESTDIR)$(NMLIBDIR)/topo
	install -m 0755 $(PROGS) $(DESTDIR)$(NMLIBDIR)/topo
	$(NINSTALL) -m 0755 $(SUBST) $(SCRIPTS) $(DESTDIR)$(NMLIBDIR)/topo
	$(NINSTALL) -m 0644 $(SUBST) $(LIBS)    $(DESTDIR)$(NMLIBDIR)/topo
	mkdir -p $(DESTDIR)$(SBINDIR)
	$(NINSTALL) -m 0755 $(SUBST) $(DAEMONS) $(DESTDIR)$(SBINDIR)

clean:
	rm -f *.o $(PROGS) *.core
