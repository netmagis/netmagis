#
#

TOPODIR=/local/applis/topo
DESTDIR=/local/etc/rc.d

SUBST = \
        -e 's|%TOPODIR%|$(TOPODIR)|'

SCRIPTS=topod.sh

all:

install:
	test -d $(DESTDIR) || mkdir $(DESTDIR)
	chmod 775 $(TOPODIR)/bin
	for i in $(SCRIPTS) ; \
	do \
		sed $(SUBST) $$i > $(DESTDIR)/$$i ; \
		chmod 0775 $(DESTDIR)/$$i ; \
	done

clean:
