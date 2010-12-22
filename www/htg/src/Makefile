DESTDIR		= /usr/local
TCLSH		= /usr/local/bin/tclsh
SINSTALL	= ../../../inst/install-script
SUBST		= $(TCLSH) \
		    $(DESTDIR)/lib/webdns/libdns.tcl \
		    $(DESTDIR)/etc/webdns.conf \
		    $(DESTDIR)/bin/webdns-config

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
	$(SINSTALL) -m 0755 \
		-e "s|%HTGBINDIR%|$(DESTDIR)/bin|" \
		-e "s|%HTGMODLDIR%|$(DESTDIR)/lib/webdns/htg/models|" \
		$(SUBST) htg htg2html $(DESTDIR)/bin

clean:
	rm -f htgtcl *.o a.out *.core
