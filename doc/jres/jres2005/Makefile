.SUFFIXES: .fig .eps .pdf

.fig.eps:
	fig2dev -L eps $*.fig > $*.eps
.fig.pdf:
	fig2dev -L pdf $*.fig > $*.pdf

all:	allps allpdf

allps:	si.ps resume.ps

formatps:
	echo "\\pdfoutput=0" > format.tex

si.ps:	si.dvi
	dvips -f si.dvi > si.ps

si.dvi:	formatps si.tex si.bib bigpic.eps topo.eps schemas.eps
	latex si.tex
	bibtex si
	latex si.tex
	latex si.tex

resume.ps: resume.dvi
	dvips -f resume.dvi > resume.ps

resume.dvi:	formatps resume.tex
	latex resume.tex

allpdf:	si.pdf resume.pdf

formatpdf:
	echo "\\pdfoutput=1" > format.tex

si.pdf:	formatpdf si.tex si.bib bigpic.pdf topo.pdf schemas.pdf
	pdflatex si.tex
	bibtex si
	pdflatex si.tex
	pdflatex si.tex

resume.pdf: formatpdf format.tex resume.tex
	pdflatex resume.tex

clean:
	rm -f *.aux *.bbl *.blg *.dvi *.log *.pdf *.ps *.eps format.tex
