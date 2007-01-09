#
# $Id: Makefile,v 1.2 2007-01-09 10:46:10 pda Exp $
#

CFLAGS = -g -Wall

OBJS = \
	mobj.o \
	ip.o \
	net.o \
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
