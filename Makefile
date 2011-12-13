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
VERSION		= 2.1b1

usage:
	@echo "available targets:"
	@echo "	all"
	@echo "	all-topo"
	@echo "	all-www"
	@echo "	install-common"
	@echo "	install-database"
	@echo "	install-servers"
	@echo "	install-www"
	@echo "	install-utils"
	@echo "	install-detecteq"
	@echo "	install-topo"
	@echo "	install-metro"
	@echo "	install-netmagis.org"
	@echo "	distrib"
	@echo "	freebsd-ports"
	@echo "	clean"
	@echo "	nothing"

all:	all-www all-topo

all-www:
	cd www ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) \
		TCLCFLAGS="$(TCLCFLAGS)" TCLLFLAGS="$(TCLLFLAGS)" all

all-topo:
	cd topo ; make all

install-common:
	cd common ; \
	    make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) VERSION=$(VERSION) install

install-database:
	cd database ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) install

install-servers:
	cd servers ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) install

install-www: all-www
	cd www ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) \
		TCLCFLAGS="$(TCLCFLAGS)" TCLLFLAGS="$(TCLLFLAGS)" install

install-utils:
	cd utils ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) install

install-topo: all-topo
	cd topo ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) install

install-detecteq:
	cd detecteq ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) install

install-metro:
	cd metro ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) install

install-netmagis.org:
	# compilation of htg if needed
	cd www ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) \
		TCLCFLAGS="$(TCLCFLAGS)" TCLLFLAGS="$(TCLLFLAGS)" all
	cd doc/netmagis.org ; make DESTDIR=$(DESTDIR) TCLSH=$(TCLSH) install
	cd doc/install ; make DESTDIR=$(DESTDIR)/install-$(VERSION) \
		TCLSH=$(TCLSH) install

distrib: clean
	rm -rf /tmp/netmagis-$(VERSION)
	mkdir /tmp/netmagis-$(VERSION)
	tar cf - --exclude "pkg/*" \
		--exclude "doc/jres/*" \
		--exclude "doc/netmagis.org" \
		* \
	    | tar xf - -C /tmp/netmagis-$(VERSION)
	tar -czf netmagis-$(VERSION).tar.gz -C /tmp netmagis-$(VERSION)
	rm -rf /tmp/netmagis-$(VERSION)

freebsd-ports:
	@if [ `uname -s` != FreeBSD ] ; then \
	    echo "Please, make this target on a FreeBSD host" ; \
	    echo "once netmagis-$(VERSION).tar.gz is on the master site" ; \
	    exit 1 ; \
	fi
	for i in pkg/freebsd/netmagis-* ; do (cd $$i ; make clean) ; done
	cd pkg/freebsd/netmagis-common ; make makesum
	tar -czf netmagis-freebsd-ports-$(VERSION).tar.gz -C pkg/freebsd .

clean:
	cd common ; make clean
	cd database ; make clean
	cd servers ; make clean
	cd www ; make clean
	cd utils ; make clean
	cd detecteq ; make clean
	cd topo ; make clean
	cd metro ; make clean
	rm -f netmagis-*.tar.gz

nothing:
