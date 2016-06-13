NINSTALL	= ../../../ninstall
TCLSH		= /usr/local/bin/tclsh

FILES =	\
	worker.tcl \
	libworker.tcl \
	hdl-admin.tcl \
	hdl-dhcpranges.tcl \
	hdl-domains.tcl \
	hdl-files.tcl \
	hdl-hinfos.tcl \
	hdl-login.tcl \
	hdl-names.tcl \
	hdl-networks.tcl \
	hdl-views.tcl \

build:
	@echo ">>> Making build in `pwd`"
	cd msgs && $(MAKE) build

install: ################## build
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)$(NMLIBDIR)/worker
	$(NINSTALL) -m 0644 $(SUBST) \
		    $(FILES) $(DESTDIR)$(NMLIBDIR)/worker ; \
	cd msgs && $(MAKE) install
