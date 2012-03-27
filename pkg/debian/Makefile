#
# This makefile provides 3 targets:
# - build: generate binary debian packages which can be installed by gdebi
#   This target should not be called directly but from the top-level Makefile
#   through "make debian-build"
# - release: generate binary and source packages and create 2 tarballs : 
#		netmagis-$VERSION-debian-$ARCH.tar.gz
#		netmagis-$VERSION-debian-src.tar.gz
#   This target should not be called directly but from the top-level Makefile
# - clean: erase the generated files
# 
#

build:
	@echo ">>> Making build in `pwd`"
	sudo apt-get -y install devscripts dh-make
	sh ./gendeb $(VERSION)

release: clean build
	@echo ">>> Making release in `pwd`"
	ARCH=`echo netmagis-www*.deb | sed 's/.*_\([^.]*\)\.deb$$/\1/'`; \
	    tar czf netmagis-$(VERSION)-debian-$$ARCH.tar.gz *.deb
	tar czf netmagis-$(VERSION)-debian-src.tar.gz *.dsc *.orig.tar.gz *.debian.tar.gz

clean:
	rm -rf netmagis*
