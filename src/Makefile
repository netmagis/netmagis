CC		= gcc -Wall
DEBUG		= -g
TCLCFLAGS	= -I/usr/local/include/tcl8.4
TCLLFLAGS	= -L/usr/local/lib -ltcl84 -lm


CFLAGS		= $(DEBUG) $(TCLCFLAGS)

OBJS		= htgtcl.o base.o


all:		htgtcl

htgtcl:		$(OBJS)
	$(CC) -o htgtcl $(OBJS) $(TCLLFLAGS)

clean:
	rm -f htgtcl *.o a.out *.core
