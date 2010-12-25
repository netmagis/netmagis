DESTDIR		= /usr/local
TCLSH		= /usr/local/bin/tclsh
SINSTALL	= ../../inst/install-script
SUBST		= $(TCLSH) \
			$(DESTDIR)/lib/netmagis/libdns.tcl \
			$(DESTDIR)/etc/netmagis.conf \
			$(DESTDIR)/bin/netmagis-config

SCRIPTS 	= \
		    accueil \
		    admgenliste admgenset \
		    admgrpedit admgrpmodif admgrpsel \
		    admin \
		    admmxedit admmxmodif admmxsel \
		    admparhelp admparliste admparmodif \
		    admrefhelp admrefliste admrefmodif \
		    admreledit admrelmodif admrelsel \
		    add \
		    consulter \
		    consultmx \
		    consultnet \
		    corresp \
		    dhcp dhcpedit dhcpmodif \
		    droits \
		    edit \
		    editmodif \
		    eq \
		    graphe \
		    ifchg \
		    ipinact \
		    l2 \
		    l3 \
		    liste \
		    listecorresp \
		    listemx \
		    listenet \
		    mac \
		    macindex \
		    macstat \
		    mail mailheberg mailmodif \
		    metro \
		    modif \
		    statcor \
		    statetab \
		    suppr \
		    topotop \
		    traiteifchg \
		    traitemodif \
		    traitesuppr

all:
	@echo ">>> Making all in `pwd`"

install:
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)/www/netmagis
	$(SINSTALL) -m 0755 $(SUBST) $(SCRIPTS) $(DESTDIR)/www/netmagis

clean:
