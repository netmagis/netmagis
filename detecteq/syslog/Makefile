NINSTALL	= ../../ninstall

build:
	@echo ">>> Making build in `pwd`"

install:
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)/$(SBINDIR)
	$(NINSTALL) -m 0755 -e "s|%SBINDIR%|$(SBINDIR)|" \
		$(SUBST) detectconfmod $(DESTDIR)/$(SBINDIR)

clean:
