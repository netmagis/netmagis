#
# Makefile pour lancer l'installation de l'application dns
#

TCLSH	= /usr/local/bin/tclsh8.5

#DEBUG	= 1
DEBUG	= 0

AUTH    = {dbname=auth user=auth password=mot-de-passe-de-auth}
HOMEURL	= /applis/auth
NOLOGIN	= /local/etc/nologin.auth

DESTDIR	= /local/services/www$(HOMEURL)
PKGTCL	= /local/services/www/pkgtcl

HTG	= /local/services/www/htg/bin/htg

ROOT	= {pda jean}
GRPROOT = authadmin


#
# Motif de substitution à appliquer à chaque fichier installé
#

SUBST	= \
	-e 's|%TCLSH%|$(TCLSH)|' \
	-e 's|%DEBUG%|$(DEBUG)|' \
	-e 's|%DESTDIR%|$(DESTDIR)|' \
	-e 's|%PKGTCL%|$(PKGTCL)|' \
	-e 's|%HOMEURL%|$(HOMEURL)|' \
	-e 's|%ROOT%|$(ROOT)|' \
	-e 's|%GRPROOT%|$(GRPROOT)|' \
	-e 's|%NOLOGIN%|$(NOLOGIN)|' \
	-e 's|%AUTH%|$(AUTH)|'

#
# Les cibles
#

all: pre dirs autres html exec divers

pre:
	rm -rf $(DESTDIR)/*

dirs:
	if [ ! -d $(DESTDIR) ] ; then mkdir $(DESTDIR) ; fi
	find . -type d -print | \
	    while read d ; do \
		if [ ! -d $(DESTDIR)/$$d ] ; then mkdir -p $(DESTDIR)/$$d ; fi ; \
	    done

autres:
	find . \( -type f -o -type l \) -print | \
	    grep -v '.htgt$$' | \
	    grep -v '.gif$$' | \
	    grep -v Makefile | \
	    while read f ; do \
		echo $$f ; \
		sed $(SUBST) $$f > $(DESTDIR)/$$f ; \
	    done

html:
	find . -name "*.htgt" -print | \
	    while read f ; do \
		h=`echo $$f | sed 's/.htgt$$//'` ; \
		echo $$f ; \
		$(HTG) $$f | sed $(SUBST) > $(DESTDIR)/$$h.html ; \
	    done

exec:
	chmod +x $(DESTDIR)/bin/*

divers:
