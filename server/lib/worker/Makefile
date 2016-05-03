NINSTALL	= ../../../ninstall

TCLSH		= /usr/local/bin/tclsh

FILES =	\
	worker.tcl \

install: ################## build
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)$(NMLIBDIR)/tcl
	install -m 0644 *.tcl $(DESTDIR)$(NMLIBDIR)/worker
