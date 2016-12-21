NINSTALL	= ../../../ninstall
TCLSH		= /usr/local/bin/tclsh

FILES =	\
	worker.tcl \
	libworker.tcl \
	hdl-admin.tcl \
	hdl-aliases.tcl \
	hdl-cap.tcl \
	hdl-dhcpprofiles.tcl \
	hdl-dhcpranges.tcl \
	hdl-domains.tcl \
	hdl-files.tcl \
	hdl-freeblocks.tcl \
	hdl-hinfos.tcl \
	hdl-hosts.tcl \
	hdl-mailroles.tcl \
	hdl-names.tcl \
	hdl-networks.tcl \
	hdl-search.tcl \
	hdl-sessions.tcl \
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
