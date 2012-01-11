NINSTALL	= ../../ninstall

build:
	@echo ">>> Making build in `pwd`"

install:
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)/$(NMXMPDIR)
	$(NINSTALL) -m 0644 -e "s|%NMCGIDIR%|$(NMCGIDIR)|" \
	    	$(SUBST) *.conf $(DESTDIR)/$(NMXMPDIR)

clean:
