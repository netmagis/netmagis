DESTDIR		= /usr/local
TCLSH		= /usr/local/bin/tclsh
NINSTALL	= ./ninstall
SUBST		= $(TCLSH) \
			$(DESTDIR)/lib/netmagis/libnetmagis.tcl \
			$(DESTDIR)/etc/netmagis.conf \
			$(DESTDIR)/bin/netmagis-config

# for www/htg/src
TCLCONF		= /usr/local/lib/tcl8.6/tclConfig.sh
TCLCFLAGS	= `(cat $(TCLCONF) ; echo 'echo "$$TCL_INCLUDE_SPEC"')|sh`
TCLLFLAGS	= `(cat $(TCLCONF) ; echo 'echo "$$TCL_LIB_SPEC $$TCL_LIBS"')|sh`

# for packaging and libnetmagis.tcl
VERSION		= 2.0b1

usage:
	@echo "available targets:"
	@echo "	all"
	@echo "	install-common"
	@echo "	install-database"
	@echo "	install-servers"
	@echo "	install-www"
	@echo "	install-utils"
	@echo "	install-detecteq"
	@echo "	install-topo"
	@echo " install-metro"
	@echo "	install-netmagis.org"
	@echo "	distrib"
	@echo "	clean"


all:
	cd www ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) \
		TCLCFLAGS="$(TCLCFLAGS)" TCLLFLAGS="$(TCLLFLAGS)" all
	cd topo ; make all

install-common:
	cd common ; \
	    make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) VERSION=$(VERSION) install

install-database:
	cd database ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) install

install-servers:
	cd servers ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) install

install-www:
	cd www ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) \
		TCLCFLAGS="$(TCLCFLAGS)" TCLLFLAGS="$(TCLLFLAGS)" install

install-utils:
	cd utils ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) install

install-topo:
	cd topo ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) install

install-metro:
	cd metro ; make DESTDIR=$(DESTDIR) install

install-detecteq:
	cd detecteq ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) install

install-netmagis.org:
	# compilation of htg if needed
	cd www ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) \
		TCLCFLAGS="$(TCLCFLAGS)" TCLLFLAGS="$(TCLLFLAGS)" all
	cd doc/netmagis.org ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) install

distrib: clean
	rm -rf /tmp/netmagis-$(VERSION)
	mkdir /tmp/netmagis-$(VERSION)
	tar cf - * | tar xf - -C /tmp/netmagis-$(VERSION)
	tar -czf netmagis-$(VERSION).tgz -C /tmp netmagis-$(VERSION)
	rm -rf /tmp/netmagis-$(VERSION)

clean:
	cd common ; make clean
	cd database ; make clean
	cd servers ; make clean
	cd www ; make clean
	cd utils ; make clean
	cd detecteq ; make clean
	cd topo ; make clean
	rm -f netmagis-*.tgz
