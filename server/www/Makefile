NINSTALL	= ../../ninstall

JSSRC = $(find src -type f)

### TODO
### APPS = dist/app_add.js ....

#
# Prerequisites:
#	npm
#

build:	node_modules/webpack/bin/webpack.js webpack.config.js $(JSSRC)
	npm run build

node_modules/webpack/bin/webpack.js: package.json
	npm install

install: build
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)$(NMLIBDIR)/www
	$(NINSTALL) -m 0644 $(SUBST) dist/* $(DESTDIR)$(NMLIBDIR)/www
	$(NINSTALL) -m 0644 $(SUBST) html/*.html $(DESTDIR)$(NMLIBDIR)/www

clean:
	rm -rf dist node_modules
