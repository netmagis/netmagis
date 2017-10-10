NINSTALL	= ../../ninstall

#
# Prerequisites:
#	npm
#

build:	node_modules/webpack/bin/webpack.js webpack.config.js $(JSSRC)
	npm run build

node_modules/webpack/bin/webpack.js: package.json
	npm install --no-optional		# for fsevents warning

install: build
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)$(NMWWWDIR)
	$(NINSTALL) -m 0644 $(SUBST) static/*/* $(DESTDIR)$(NMWWWDIR)
	$(NINSTALL) -m 0644 $(SUBST) static/*.* $(DESTDIR)$(NMWWWDIR)
	$(NINSTALL) -m 0644 $(SUBST) dist/* $(DESTDIR)$(NMWWWDIR)

clean:
	rm -rf dist node_modules
