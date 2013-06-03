NINSTALL	= ../../ninstall

PROG =	netmagis-test
FILES = cgi
TESTS = *.test

install:
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)$(BINDIR)
	mkdir -p $(DESTDIR)$(NMLIBDIR)/tests
	mkdir -p $(DESTDIR)$(NMVARDIR)/tests
	$(NINSTALL) -m 0755 -e "s|%BINDIR%|$(BINDIR)|" \
			    -e "s|%NMLIBDIR%|$(NMLIBDIR)|" \
			    -e "s|%NMVARDIR%|$(NMVARDIR)|" \
			    -e "s|%NMCGIDIR%|$(NMCGIDIR)|" \
			    $(SUBST) $(PROG) $(DESTDIR)$(BINDIR)
	$(NINSTALL) -m 0755 $(SUBST) $(FILES) $(DESTDIR)$(NMLIBDIR)/tests
	$(NINSTALL) -m 0644 -e "s|%BINDIR%|$(BINDIR)|" \
			    -e "s|%NMLIBDIR%|$(NMLIBDIR)|" \
			    -e "s|%NMVARDIR%|$(NMVARDIR)|" \
			    -e "s|%NMCGIDIR%|$(NMCGIDIR)|" \
			    -e "s|%NMXMPDIR%|$(NMXMPDIR)|" \
			    $(SUBST) $(TESTS) $(DESTDIR)$(NMLIBDIR)/tests

clean:
