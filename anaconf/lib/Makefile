#
# $Id: Makefile,v 1.1.1.1 2007-01-05 15:12:00 pda Exp $
#

CFLAGS = -g -Wall

OBJS = \
	mobj.o \
	ip.o \
	symtab.o \
	node.o \
	util.o \
	textread.o \
	textwrite.o \
	l2trans.o \
	searcheq.o \
	getneighbour.o \
	traversedvlans.o \
	printvlans.o \
	dupgraph.o \
	checklinks.o \
	relabs.o \
	absrel.o \
	binwrite.o \
	binread.o


libgraph.a:	$(OBJS)
	ar r libgraph.a $(OBJS)

$(OBJS):	graph.h

clean:
	rm -f *.o *.a
