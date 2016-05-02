NINSTALL	= ../../ninstall

install:
	@echo ">>> Making install in `pwd`"
	mkdir -p $(DESTDIR)$(ETCDIR)
	$(NINSTALL) -m 0644 \
			-e "s|%ETCDIR%|$(ETCDIR)|" \
			-e "s|%CAFILE%|$(CAFILE)|" \
			-e "s|%NMLIBDIR%|$(NMLIBDIR)|" \
			-e "s|%NMVARDIR%|$(NMVARDIR)|" \
			$(SUBST) netmagis.conf.sample $(DESTDIR)$(ETCDIR)
