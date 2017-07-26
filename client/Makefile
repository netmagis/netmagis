NINSTALL	= ../ninstall

MODULES = \
	core.py \
	fileinst.py \
	utils.py \
	nmlock.py \

SCRIPTS = \
	dnsaddalias.py \
	dnsaddhost.py \
	dnsdelhost.py \
	dnsdelip.py \
	dnsmodattr.py \
	dnsreadprol.py \
	dnswriteprol.py \
	mkzones.py \

MAN1 = \
	dnsaddalias.man \
	dnsaddhost.man \
	dnsdelhost.man \
	dnsdelip.man \
	dnsmodattr.man \
	dnsreadprol.man \
	dnswriteprol.man \
	mkzones.man \

MAN5 = \
	netmagisrc.man \

.SUFFIXES: .md .man

.md.man:
	pandoc -s -t man $*.md > $*.man

build: $(MAN1) $(MAN5)
	@echo ">>> Making build in `pwd`"

install: build
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)$(NMLIBDIR)/pynm
	for mod in $(MODULES) ; do \
	    b=$$(basename $$mod .py) ; \
	    $(NINSTALL) -m 0644 \
		    -e "s|%ETCDIR%|$(ETCDIR)|" \
		    $(SUBST) \
		    pynm/$$mod $(DESTDIR)$(NMLIBDIR)/pynm/$$b ; \
	done
	mkdir -p $(DESTDIR)$(BINDIR)
	for scr in $(SCRIPTS) ; do \
	    b=$$(basename $$scr .py) ; \
	    $(NINSTALL) -m 0755 \
		    -e "s|%NMLIBDIR%|$(NMLIBDIR)|" \
		    -e "s|%ETCDIR%|$(ETCDIR)|" \
		    $(SUBST) \
		    $$scr $(DESTDIR)$(BINDIR)/$$b ; \
	done
	mkdir -p $(DESTDIR)$(MANDIR)/man1
	for page in $(MAN1) ; do \
	    b=$$(basename $$page .man) ; \
	    $(NINSTALL) -m 0644 \
		    -e "s|%NMLIBDIR%|$(NMLIBDIR)|" \
		    -e "s|%ETCDIR%|$(ETCDIR)|" \
		    $(SUBST) \
		    $$page $(DESTDIR)$(MANDIR)/man1/$$b.1 ; \
	done
	mkdir -p $(DESTDIR)$(MANDIR)/man5
	for page in $(MAN5) ; do \
	    b=$$(basename $$page .man) ; \
	    $(NINSTALL) -m 0644 \
		    -e "s|%NMLIBDIR%|$(NMLIBDIR)|" \
		    -e "s|%ETCDIR%|$(ETCDIR)|" \
		    $(SUBST) \
		    $$page $(DESTDIR)$(MANDIR)/man5/$$b.5 ; \
	done

test:	build
	for i in *.man ; do \
	    groff -man $$i | ps2pdf - $$(basename $$i .man).pdf ; \
	done
	pdfjam -o all.pdf dns*.pdf netmagisrc.pdf
	
clean:
	rm -rf pynm/__*
	rm -f $(MAN1) $(MAN5)
	rm -f *.pdf
