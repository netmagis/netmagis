NINSTALL	= ../../ninstall

MAN = \
	netmagis-config.man \
	netmagis-dbcreate.man \
	netmagis-dbmaint.man \
	netmagis-dbupgrade.man \
	netmagis-restd.man \


.SUFFIXES: .md .man

.md.man:
	pandoc -s -t man $*.md > $*.man

build: $(MAN)
	@echo ">>> Making build in `pwd`"

install: build
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)$(MANDIR)/man1
	for page in $(MAN) ; do \
	    b=`basename $$page .man` ; \
	    $(NINSTALL) -m 0644 \
		    -e "s|%NMLIBDIR%|$(NMLIBDIR)|" \
		    -e "s|%VERSION%|$(VERSION)|" \
		    $(SUBST) \
		    $$page $(DESTDIR)$(MANDIR)/man1/$$b.1 ; \
	done

clean:
	rm -f $(MAN)
