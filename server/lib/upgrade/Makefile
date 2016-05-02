NINSTALL	= ../../../ninstall

DIRS = `ls -d [0-9]*`
FILES = `ls -d [0-9]*/*`

install:
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)$(NMLIBDIR)/upgrade
	for i in $(DIRS) ; do \
	    mkdir -p  $(DESTDIR)$(NMLIBDIR)/upgrade/$$i ; \
	done
	for i in $(FILES) ; do \
	    $(NINSTALL) -m 0644 -e "s|%NMLIBDIR%|$(NMLIBDIR)|" $(SUBST) \
	    		$$i $(DESTDIR)$(NMLIBDIR)/upgrade/$$i ; \
	done

