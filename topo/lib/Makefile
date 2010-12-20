#
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


all:	libgraph.a

libgraph.a:	$(OBJS)
	ar r libgraph.a $(OBJS)

$(OBJS):	graph.h

install:

clean:
	rm -f *.o *.a
