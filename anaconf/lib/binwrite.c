/*
 * $Id: binwrite.c,v 1.1.1.1 2007-01-05 15:12:00 pda Exp $
 */

#include "graph.h"

static struct graphhdr hdr = { MAGIC, VERSION2, NB_MOBJ, } ;

void bin_write (FILE *fpout, MOBJ *graph [])
{
    int i ;

    abs_to_rel (graph) ;

    for (i = 0 ; i < NB_MOBJ ; i++)
    {
	hdr.mobjhdr [i].objsiz = mobj_size (graph [i]) ;
	hdr.mobjhdr [i].objcnt = mobj_count (graph [i]) ;
	hdr.mobjhdr [i].listhead = (int) mobj_head (graph [i]) ;
    }

    if (fwrite (&hdr, sizeof hdr, 1, fpout) != 1)
	error (1, "Cannot write file header") ;

    for (i = 0 ; i < NB_MOBJ ; i++)
    {
	void *data ;
	int size, count ;

	data = mobj_data (graph [i]) ;
	size = hdr.mobjhdr [i].objsiz ;
	count = hdr.mobjhdr [i].objcnt ;
	if (fwrite (data, size, count, fpout) != count)
	    error (1, "Cannot write mobj data") ;
    }

    rel_to_abs (graph) ;
}
