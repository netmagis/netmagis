DESTDIR		= /usr/local
TCLSH		= /usr/local/bin/tclsh
SINSTALL	= ../../inst/install-script
SUBST		= $(TCLSH) \
			$(DESTDIR)/lib/netmagis/libdns.tcl \
			$(DESTDIR)/etc/netmagis.conf \
			$(DESTDIR)/bin/netmagis-config

SCRIPTS 	= \
		    index \
		    admgenliste admgenset \
		    admgrpedit admgrpmodif admgrpsel \
		    admindex \
		    admmxedit admmxmodif admmxsel \
		    admparhelp admparliste admparmodif \
		    admrefhelp admrefliste admrefmodif \
		    admreledit admrelmodif admrelsel \
		    add \
		    consultmx \
		    consultnet \
		    del \
		    dhcp \
		    edit \
		    eq \
		    graph \
		    ifchg \
		    ipinact \
		    l2 \
		    l3 \
		    listecorresp \
		    listemx \
		    listenet \
		    mac \
		    macindex \
		    macstat \
		    mail \
		    metro \
		    mod \
		    net \
		    perm \
		    search \
		    statcor \
		    statetab \
		    topotop

all:
	@echo ">>> Making all in `pwd`"

install:
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)/www/netmagis
	$(SINSTALL) -m 0755 $(SUBST) $(SCRIPTS) $(DESTDIR)/www/netmagis

clean:
