NINSTALL	= ../ninstall

build:
	@echo ">>> Making build in `pwd`"

install: build
	@echo ">>> Making install in `pwd`"
	cd syslog ; $(MAKE) install
	cd radius ; $(MAKE) install

clean:
