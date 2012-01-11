NINSTALL	= ../ninstall

build:
	@echo ">>> Making build in `pwd`"

install: build
	@echo ">>> Making install in `pwd`"
	cd syslog ; make $(DIRS) install
	cd radius ; make $(DIRS) install

clean:
