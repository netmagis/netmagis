TCLSH		= /usr/local/bin/tclsh
NINSTALL	= ../../../ninstall

TCLCFLAGS	= -I/usr/local/include/tcl8.5
TCLLFLAGS	= -L/usr/local/lib -ltcl85 -lm

CC		= gcc -Wall
#DEBUG		= -g
OPT		= -O
CFLAGS		= $(DEBUG) $(OPT) $(TCLCFLAGS)

OBJS		= htgtcl.o base.o

build:		htgtcl
	@echo ">>> Making build in `pwd`"

htgtcl:		$(OBJS)
	$(CC) -o htgtcl $(OBJS) $(TCLLFLAGS)

install:	htgtcl
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)/$(BINDIR)
	install -m 0755 htgtcl $(DESTDIR)/$(BINDIR)
	$(NINSTALL) -m 0755 \
		-e "s|%HTGBINDIR%|$(BINDIR)|" \
		-e "s|%HTGMODLDIR%|$(NMLIBDIR)/htg/models|" \
		$(SUBST) htg htg2html $(DESTDIR)/$(BINDIR)

clean:
	rm -f htgtcl *.o a.out *.core
