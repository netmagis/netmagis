NINSTALL	= ../../ninstall

PROG =	netmagis-test
FILES = cgi
TESTS = *.test

install:
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)$(SBINDIR)
	mkdir -p $(DESTDIR)$(NMLIBDIR)/tests
	mkdir -p $(DESTDIR)$(NMVARDIR)/tests
	$(NINSTALL) -m 0755 -e "s|%NMLIBDIR%|$(NMLIBDIR)|" \
			    -e "s|%NMVARDIR%|$(NMVARDIR)|" \
			    -e "s|%NMCGIDIR%|$(NMCGIDIR)|" \
			    $(SUBST) $(PROG) $(DESTDIR)$(SBINDIR)
	$(NINSTALL) -m 0755 $(SUBST) $(FILES) $(DESTDIR)$(NMLIBDIR)/tests
	$(NINSTALL) -m 0644 -e "s|%NMLIBDIR%|$(NMLIBDIR)|" \
			    -e "s|%NMVARDIR%|$(NMVARDIR)|" \
			    -e "s|%NMCGIDIR%|$(NMCGIDIR)|" \
			    $(SUBST) $(TESTS) $(DESTDIR)$(NMLIBDIR)/tests

clean:
