NINSTALL	= ../../ninstall

build:
	@echo ">>> Making build in `pwd`"

install:
	@echo ">>> Making install in `pwd`"
	case `uname -s` in \
		Linux)   cd debian  ; make $(DIRS) install ;; \
		FreeBSD) cd freebsd ; make $(DIRS) install ;; \
		*)       cd generic ; make $(DIRS) install ;; \
	esac

clean:
