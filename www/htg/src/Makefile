
TCLCONF	= /usr/local/lib/tcl8.6/tclConfig.sh
CC		= gcc -Wall
DEBUG		= -g
TCLCFLAGS	= -I/usr/local/include/tcl8.5
TCLLFLAGS	= -L/usr/local/lib -ltcl85 -lm

CFLAGS		= $(DEBUG) $(TCLCFLAGS)

OBJS		= htgtcl.o base.o

all:		htgtcl

htgtcl:		$(OBJS)
	./$(TCLCONF) $(CC) -o htgtcl $(OBJS) $$TCL_LIB_SPEC $(TCLLFLAGS)
####	$(CC) -o htgtcl $(OBJS) $(TCLLFLAGS)

install:	htgtcl


clean:
	rm -f htgtcl *.o a.out *.core
