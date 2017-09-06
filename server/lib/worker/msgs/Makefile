NINSTALL	= ../../../../ninstall

FILES =	\
	fr.msg \

build:
	@echo ">>> Making build in `pwd`"

install:
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)$(NMLIBDIR)/worker/msgs
	$(NINSTALL) -m 0644 $(SUBST) \
		    $(FILES) $(DESTDIR)$(NMLIBDIR)/worker/msgs ; \
