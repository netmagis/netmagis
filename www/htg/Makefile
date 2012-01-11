NINSTALL	= ../../ninstall

TCLCFLAGS	= -I/usr/local/include/tcl8.5
TCLLFLAGS	= -L/usr/local/lib -ltcl85 -lm

build:
	@echo ">>> Making build in `pwd`"
	cd src ; make TCLCFLAGS="$(TCLCFLAGS)" TCLLFLAGS="$(TCLLFLAGS)" build

install: build
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)$(BINDIR)
	cd src ; make $(DIRS) install
	mkdir -p $(DESTDIR)$(NMLIBDIR)/htg
	tar cf - models doc | tar xf - -C $(DESTDIR)$(NMLIBDIR)/htg

clean:
	cd src ; make clean
