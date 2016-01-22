NINSTALL	= ../../ninstall

SUBDIRS		= `find . -type d -print`
SCRIPTS 	= `find . -type f -name "[a-z]*" -print`

build:
	@echo ">>> Making build in `pwd`"

install:
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)$(NMCGIDIR)
	for D in $(SUBDIRS) ; do mkdir -p $(DESTDIR)$(NMCGIDIR)/$$D ; done
	for S in $(SCRIPTS) ; do \
	    $(NINSTALL) -m 0755 $(SUBST) $$S $(DESTDIR)$(NMCGIDIR)/$$S ; \
	done

clean:
