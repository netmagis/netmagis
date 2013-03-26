NINSTALL	= ../../ninstall

install:
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)$(NMLIBDIR)
	tar cf - sql* *.sql | tar xf - -C $(DESTDIR)$(NMLIBDIR)
