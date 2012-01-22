NINSTALL	= ../../ninstall

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
		    eq l2 l3 metro graph ifchg genl \
		    lusers \
		    lnet \
		    macindex mac macstat ipinact \
		    mail \
		    net \
		    perm search \
		    statuser statorg \
		    topotop \
		    pgaindex pgapasswd pgarealm pgaacc

build:
	@echo ">>> Making build in `pwd`"

install:
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)$(NMCGIDIR)
	$(NINSTALL) -m 0755 $(SUBST) $(SCRIPTS) $(DESTDIR)$(NMCGIDIR)

clean:
