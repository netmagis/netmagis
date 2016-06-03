NINSTALL	= ../../ninstall

JSSRC = $(find src -type f)

#
# Prerequisites:
#	npm
#

build:	node_modules/webpack/bin/webpack.js webpack.config.js $(JSSRC)
	# node_modules/.bin/webpack
	npm run build

node_modules/webpack/bin/webpack.js: package.json
	npm install

install:
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)$(BINDIR)
	$(NINSTALL) -m 0755 \
		-e "s|%NMLIBDIR%|$(NMLIBDIR)|" \
		-e "s|%BINDIR%|$(BINDIR)|" $(SUBST) \
		$(SCRIPTS) $(DESTDIR)$(BINDIR)

clean:
	rm -rf dist node_modules
