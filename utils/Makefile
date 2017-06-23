NINSTALL	= ../ninstall

SCRIPTS = \
	dnsaddalias.py \
	dnsaddhost.py \
	dnsdelhost.py \
	dnsdelip.py \
	dnsmodattr.py \
	dnsreadprol.py \
	dnswriteprol.py

build:
	@echo ">>> Making build in `pwd`"

install:
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)$(NMLIBDIR)/pynm
	$(NINSTALL) -m 0644 $(SUBST) pynm/core.py $(DESTDIR)$(NMLIBDIR)/pynm
	mkdir -p $(DESTDIR)$(BINDIR)
	for s in $(SCRIPTS) ; do \
	    f=$$(basename $$s .py) ; \
	    $(NINSTALL) -m 0755 \
		    -e "s|%NMLIBDIR%|$(NMLIBDIR)|" \
		    $(SUBST) \
		    $$s \
		    $(DESTDIR)$(BINDIR)/$$f \
		    ; \
	done

clean:
	rm -rf pynm/__*
