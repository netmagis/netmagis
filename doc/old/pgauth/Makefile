#
# Makefile de la doc d'installation de l'application SOS
#
#
# Cibles possibles :
#
# all : génère install.dvi et install/install.html
# test : vérifie la syntaxe TeX de install.tex
#
# print : imprime install
#
# install.dvi : genere install
#
# clean : efface tout
#

LATEX = latex
LATEX2HTML = latex2html

SRCS = install.tex

FIGS = principe.ps

.SUFFIXES:	.fig .tex .dvi .ps .pdf .txt

.fig.ps:
	fig2dev -Leps $*.fig > $*.ps
.fig.tex:
	fig2dev -Llatex -l 2 $*.fig > $*.tex
.tex.dvi:
	$(LATEX) $*
.dvi.ps:
	dvips -f $*.dvi > $*.ps
.dvi.pdf:
	dvipdfm -p a4 $*
.dvi.txt:
	dvi2tty -o $*.txt $*.dvi

#
# Fin des regles classiques
#

all:	ps pdf # html

ps:	install.ps
pdf:	install.pdf
html:	install/install.html

test:	install.tex $(FIGS)
	$(LATEX) install

install.dvi:	install.tex $(FIGS)
	$(LATEX) install
	$(LATEX) install
	$(LATEX) install

install.ps:	install.dvi $(FIGS)

install.pdf:	install.dvi $(FIGS)

install.txt:	install.dvi
	dvi2tty -o install.txt install.dvi

install/install.html:	install.dvi
	$(LATEX2HTML) \
	    -verbosity 0 \
	    install

principe.ps: principe.fig engrenage.jpg

clean:
	cleantex -a $(SRCS)
	rm -f $(FIGS) *.ps *.bak *.pdf
	rm -rf install
