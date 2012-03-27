NINSTALL	= ../../../ninstall

SCRIPTS= \
	topographd \
	toposendd

build:
	@echo ">>> Making build in `pwd`"

install:
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)$(RCDIR)
	$(NINSTALL) -m 0755 -e "s|%NMLIBDIR%|$(NMLIBDIR)|" \
		$(SUBST) $(SCRIPTS) $(DESTDIR)$(RCDIR)

clean:
