DESTDIR		?= /usr/local
TCLSH		= /usr/local/bin/tclsh
SINSTALL	= inst/install-script
SUBST		= $(TCLSH) \
			$(DESTDIR)/lib/netmagis/libdns.tcl \
			$(DESTDIR)/etc/netmagis.conf \
			$(DESTDIR)/bin/netmagis-config

uname := $(shell sh -c 'uname')

# for www/htg/src
ifeq ($(uname),Linux)
TCLCONF		= /usr/lib/tclConfig.sh
TCLSH		= /usr/bin/tclsh
endif
TCLCFLAGS	= `(cat $(TCLCONF) ; echo 'echo "$$TCL_INCLUDE_SPEC"')|sh`
TCLLFLAGS	= `(cat $(TCLCONF) ; echo 'echo "$$TCL_LIB_SPEC $$TCL_LIBS"')|sh`

usage:
	@echo "available targets:"
	@echo "	all"
	@echo "	install-common"
	@echo "	install-www"
	@echo "	install-utils"
	@echo "	install-detecteq"
	@echo "	install-topo"
	@echo "	clean"

all:
	cd www ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) \
		TCLCFLAGS="$(TCLCFLAGS)" TCLLFLAGS="$(TCLLFLAGS)" all
	cd topo ; make all

install-common:
	cd common ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) install

install-database:
	cd database ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) install

install-www:
	cd www ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) \
		TCLCFLAGS="$(TCLCFLAGS)" TCLLFLAGS="$(TCLLFLAGS)" install

install-utils:
	cd utils ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) install

install-topo:
	cd topo ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) install

install-detecteq:
	cd detecteq ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) install

clean:
	cd www ; make clean
	cd common ; make clean
	cd topo ; make clean
