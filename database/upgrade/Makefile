NINSTALL	= ../../ninstall

install:
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)/$(NMXMPDIR)/upgrade
	tar cf - [0-9]* | tar xvf - -C $(DESTDIR)/$(NMXMPDIR)/upgrade
