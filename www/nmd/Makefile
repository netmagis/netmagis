NINSTALL	= ../../ninstall

SCRIPTS 	= \
		    nmd

WORKERS		= \
		  worker.tcl \
		  lib.tcl

build:
	@echo ">>> Making build in `pwd`"

install:
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)$(NMCGIDIR)
	$(NINSTALL) -m 0755 $(SUBST) \
		-e "s|%NMCGIDIR%|$(NMCGIDIR)|" \
	    	$(SCRIPTS) $(DESTDIR)$(NMCGIDIR)
	$(NINSTALL) -m 0644 $(SUBST) $(WORKERS) $(DESTDIR)$(NMCGIDIR)

clean:
