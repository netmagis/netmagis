NINSTALL	= ../../ninstall

MAN1 = \
	netmagis-config.man \
	netmagis-dbcreate.man \
	netmagis-dbimport.man \
	netmagis-dbmaint.man \
	netmagis-dbupgrade.man \
	netmagis-restd.man \

MAN5 = \
	netmagis.conf.man \


.SUFFIXES: .md .man

.md.man:
	pandoc -s -t man $*.md > $*.man

build: $(MAN1) $(MAN5)
	@echo ">>> Making build in `pwd`"

install: build
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)$(MANDIR)/man1
	for page in $(MAN1) ; do \
	    b=`basename $$page .man` ; \
	    $(NINSTALL) -m 0644 \
		    -e "s|%NMLIBDIR%|$(NMLIBDIR)|" \
		    -e "s|%VERSION%|$(VERSION)|" \
		    $(SUBST) \
		    $$page $(DESTDIR)$(MANDIR)/man1/$$b.1 ; \
	done
	mkdir -p $(DESTDIR)$(MANDIR)/man5
	for page in $(MAN5) ; do \
	    b=`basename $$page .man` ; \
	    $(NINSTALL) -m 0644 \
		    -e "s|%NMLIBDIR%|$(NMLIBDIR)|" \
		    -e "s|%VERSION%|$(VERSION)|" \
		    $(SUBST) \
		    $$page $(DESTDIR)$(MANDIR)/man5/$$b.5 ; \
	done

clean:
	rm -f $(MAN1) $(MAN5)
