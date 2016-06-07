NINSTALL	= ../../../ninstall
TCLSH		= /usr/local/bin/tclsh

FILES =	\
	worker.tcl \
	libworker.tcl \
	hdl-files.tcl \
	hdl-login.tcl \
	hdl-names.tcl \
	hdl-networks.tcl \
	hdl-views.tcl \


install: ################## build
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)$(NMLIBDIR)/worker
	for F in $(FILES) ; do \
	    $(NINSTALL) -m 0644 \
		    -e "s|%NMLIBDIR%|$(NMLIBDIR)|" \
		    $(SUBST) \
		    $$F $(DESTDIR)$(NMLIBDIR)/worker ; \
	done
