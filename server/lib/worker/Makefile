NINSTALL	= ../../../ninstall
TCLSH		= /usr/local/bin/tclsh

FILES =	\
	worker.tcl \
	hdl-login.tcl \
	hdl-names.tcl \
	hdl-views.tcl \


install: ################## build
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)$(NMLIBDIR)/worker
	for F in $(FILES) ; do \
	    $(NINSTALL) -m 0644 $(SUBST) $$F $(DESTDIR)$(NMLIBDIR)/worker ; \
	done
