DESTDIR		= /local/services/www/htg

SUBST	= \
	-e 's|%DESTDIR%|$(DESTDIR)|'

install:
	cd src ; make
	-mkdir -p $(DESTDIR)/bin
	for i in htg htg2html ; do \
	    sed $(SUBST) src/$$i > $(DESTDIR)/bin/$$i ; \
		chmod 755 $(DESTDIR)/bin/$$i ; \
	done
	cp src/htgtcl $(DESTDIR)/bin/$$i
	tar cf - modeles | tar xf - -C $(DESTDIR)

clean:
	cd src ; make clean
