DESTDIR		= /usr/local
TCLSH		= /usr/local/bin/tclsh
NINSTALL	= ../../ninstall
SUBST		= $(TCLSH) \
			$(DESTDIR)/lib/netmagis/libnetmagis.tcl \
			$(DESTDIR)/etc/netmagis.conf \
			$(DESTDIR)/bin/netmagis-config

SCRIPTS 	= \
		    index \
		    admindex \
		    admgrp \
		    admmrel admmx \
		    admpar admref \
		    admzgen \
		    admlmx \
		    add del mod edit \
		    dhcp \
		    eq l2 l3 metro graph ifchg \
		    lusers \
		    lnet \
		    macindex mac macstat ipinact \
		    mail \
		    net \
		    perm search \
		    statuser statorg \
		    topotop \
		    pgaindex pgapasswd pgarealm pgaacc

all:
	@echo ">>> Making all in `pwd`"

install:
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)/www/netmagis
	$(NINSTALL) -m 0755 $(SUBST) $(SCRIPTS) $(DESTDIR)/www/netmagis

clean:
