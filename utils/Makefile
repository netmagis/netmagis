NINSTALL	= ../ninstall

SCRIPTS = \
	dnsaddalias \
	dnsaddhost \
	dnsdelhost \
	dnsdelip \
	dnsmodattr \
	dnsreadprol \
	dnswriteprol

build:
	@echo ">>> Making build in `pwd`"

install:
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)$(BINDIR)
	$(NINSTALL) -m 0755 $(SUBST) $(SCRIPTS) $(DESTDIR)$(BINDIR)

clean:
