NINSTALL	= ../../ninstall

build:
	@echo ">>> Making build in `pwd`"

install:
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)$(NMWSDIR)
	$(NINSTALL) -m 0755 -e "s|%NMLIBDIR%|$(NMLIBDIR)|" \
			$(SUBST) gengraph $(DESTDIR)$(NMWSDIR)

clean:
