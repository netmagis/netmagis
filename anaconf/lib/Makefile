#
# $Id: Makefile,v 1.3 2007-01-10 16:49:53 pda Exp $
#

CFLAGS = -g -Wall

OBJS = \
	mobj.o \
	ip.o \
	net.o \
	symtab.o \
	node.o \
	eq.o \
	util.o \
	textread.o \
	textwrite.o \
	l2trans.o \
	getneighbour.o \
	traversedvlans.o \
	printvlans.o \
	dupgraph.o \
	checklinks.o \
	relabs.o \
	absrel.o \
	binwrite.o \
	binread.o \
	sel.o


libgraph.a:	$(OBJS)
	ar r libgraph.a $(OBJS)

$(OBJS):	graph.h

clean:
	rm -f *.o *.a
