/*
 */

#include "graph.h"

void bin_read (FILE *fpin, MOBJ *graph [])
{
    struct graphhdr hdr ;
    int i ;

    if (fread (&hdr, sizeof hdr, 1, fpin) != 1)
	error (1, "Cannot read binary file") ;

    if (hdr.magic != MAGIC)
	error (0, "Bad magic in binary file") ;

    switch (hdr.version)
    {
	case VERSION1 :
	    error (0, "Cannot recognize version 1 binary files") ;
	case VERSION2 :
	    error (0, "Cannot recognize version 2 binary files") ;
	case VERSION3 :
	    error (0, "Cannot recognize version 3 binary files") ;
	case VERSION4 :
	    error (0, "Cannot recognize version 4 binary files") ;
	case VERSION5 :
	    error (0, "Cannot recognize version 5 binary files") ;
	case VERSION6 :
	    error (0, "Cannot recognize version 6 binary files") ;
	case VERSION7 :
	    error (0, "Cannot recognize version 7 binary files") ;
	case VERSION8 :
	    error (0, "Cannot recognize version 8 binary files") ;
	case VERSION9 :
	    error (0, "Cannot recognize version 9 binary files") ;
	case VERSION10 :
	    error (0, "Cannot recognize version 10 binary files") ;
	case VERSION11 :
	    for (i = 0 ; i < hdr.nbmobj ; i++)
	    {
		int objsiz, objcnt ;
		void *data ;

		objsiz = hdr.mobjhdr [i].objsiz ;
		objcnt = hdr.mobjhdr [i].objcnt ;

		graph [i] = mobj_init (objsiz, MOBJ_CONST) ;
		data = mobj_alloc (graph [i], objcnt) ;
		mobj_sethead (graph [i],
			(void *) (intptr_t) hdr.mobjhdr [i].listhead) ;
		if (fread (data, objsiz, objcnt, fpin) != objcnt)
		    error (1, "Cannot read mobj in binary file") ;
	    }
	    break ;
	default :
	    error (0, "Bad version in binary file") ;
    }

    rel_to_abs (graph) ;
}
