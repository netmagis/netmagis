#
# This makefile provides 2 targets:
# - release: generate binary and source packages and create 2 tarballs : 
#		netmagis-$VERSION-debian-$ARCH.tar.gz
#		netmagis-$VERSION-debian-src.tar.gz
#   This target should not be called directly but from the top-level Makefile
# - clean: erase the generated files
# 
#

release: clean
	@echo ">>> Making release in `pwd`"
	@which debuild >/dev/null 2>&1 || \
	    ( echo 1>&2 "You need the 'devscripts' package: apt-get -y install devscripts" && exit 1 )
	@which dh_make >/dev/null 2>&1 || \
	    ( echo 1>&2 "You need the 'dh-make' package: apt-get -y install dh-make" && exit 2 )
	sh ./gendeb $(VERSION)

clean:
	rm -rf netmagis*
