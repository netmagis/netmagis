DESTDIR		= /usr/local
TCLSH		= /usr/local/bin/tclsh
NINSTALL	= ../../../ninstall
SUBST		= $(TCLSH) \
		    $(DESTDIR)/lib/netmagis/libdns.tcl \
		    $(DESTDIR)/etc/netmagis.conf \
		    $(DESTDIR)/bin/netmagis-config

TCLCFLAGS	= -I/usr/local/include/tcl8.5
TCLLFLAGS	= -L/usr/local/lib -ltcl85 -lm

CC		= gcc -Wall
DEBUG		= -g
CFLAGS		= $(DEBUG) $(TCLCFLAGS)

OBJS		= htgtcl.o base.o

all:		htgtcl
	@echo ">>> Making all in `pwd`"

htgtcl:		$(OBJS)
	$(CC) -o htgtcl $(OBJS) $(TCLLFLAGS)

install:	htgtcl
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)/bin
	install -m 0755 htgtcl $(DESTDIR)/bin
	$(NINSTALL) -m 0755 \
		-e "s|%HTGBINDIR%|$(DESTDIR)/bin|" \
		-e "s|%HTGMODLDIR%|$(DESTDIR)/lib/netmagis/htg/models|" \
		$(SUBST) htg htg2html $(DESTDIR)/bin

clean:
	rm -f htgtcl *.o a.out *.core
