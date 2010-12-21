DESTDIR		= /usr/local
TCLSH		= /usr/local/bin/tclsh
SINSTALL	= ../../inst/install-script
SUBST		= $(TCLSH) \
			$(DESTDIR)/lib/webdns/libdns.tcl \
			$(DESTDIR)/etc/webdns.conf \
			$(DESTDIR)/bin/webdns-config

SCRIPTS 	= \
		    accueil \
		    admgenliste admgenset \
		    admgrpedit admgrpmodif admgrpsel \
		    admin \
		    admmxedit admmxmodif admmxsel \
		    admparhelp admparliste admparmodif \
		    admrefhelp admrefliste admrefmodif \
		    admreledit admrelmodif admrelsel \
		    ajout \
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
		    traiteajout \
		    traiteifchg \
		    traitemodif \
		    traitesuppr

all:
	@echo ">>> Making all in `pwd`"

install:
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)/www/webdns
	$(SINSTALL) -m 0755 $(SUBST) $(SCRIPTS) $(DESTDIR)/www/webdns

clean:
