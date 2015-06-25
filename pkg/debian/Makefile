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
	@missing_pkgs= ;                                                \
	 for cmd_pkg_pair in                                            \
	   "quilt         quilt"                                        \
	   "debuild       devscripts"                                   \
	   "dh_make       dh-make" ;                                    \
	 do                                                             \
	   set -- $$cmd_pkg_pair ;                                      \
	   which $$1 >/dev/null 2>&1 ||                                 \
	     missing_pkgs="$$missing_pkgs $$2" ;                        \
	 done ;                                                         \
	 test "$$missing_pkgs" && {                                     \
	   printf '%s\n' "missing packages : $$missing_pkgs"            \
	                 "you may install them with :"                  \
	                 "apt-get -y install$$missing_pkgs" ;           \
	   exit 1 ;                                                     \
	 } || : yeah. We have all the needed packages...
	sh ./gendeb $(VERSION)

release-arch:
	sh ./buildenv $(VERSION) $(ARCH)

clean:
	rm -rf netmagis*
