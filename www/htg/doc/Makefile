HTG = ../src/htg

.SUFFIXES:	.htgt .html

.htgt.html:
	$(HTG) < $*.htgt > $*.html

HTML =	index.html \
	struct.html \
	comm.html \
	bandeau.html \
	modeles.html \
	interne.html


all:	$(HTML)

clean:
	rm -f $(HTML)
