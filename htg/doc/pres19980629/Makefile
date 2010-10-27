
HTML2PS = html2ps
HTML2PSCONF = html2ps.conf
# MODELES = fond.tcl fond.htgm

HTG = ../../src/htg

FIGS = \
	princ.gif doccsi.gif

.SUFFIXES: .fig .gif

.fig.gif:
	fig2dev -L ppm $*.fig $*.ppm
	ppmtogif -transparent rgb:FF/FF/FF -sort -interlace < $*.ppm > $*.gif
	rm -f $*.ppm

all: preshtg01.html $(FIGS)

preshtg01.html: transp.htgt $(MODELES)
	$(HTG) $(MODELES) transp.htgt

preshtg.ps: preshtg01.html $(HTML2PSCONF)
	$(HTML2PS) -f $(HTML2PSCONF) preshtg*.html > preshtg.ps

clean:
	rm -f *.html $(FIGS) *.ppm *.bak *.ps
