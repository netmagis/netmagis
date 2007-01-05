/*
 * $Id: mobj.c,v 1.1.1.1 2007-01-05 15:12:00 pda Exp $
 */

#include "graph.h"

#define	MOBJ_MINSIZE	16

MOBJ *mobj_init (int objsiz, enum mobj_mode mode)
{
    MOBJ *d ;

    if (mode != MOBJ_MALLOC && mode != MOBJ_CONST && mode != MOBJ_REALLOC)
	error (0, "Invalid mode for a mobj object") ;

    d = malloc (sizeof *d) ;
    if (d != NULL)
    {
	d->mode = mode ;
	d->objsiz = objsiz ;
	d->maxidx = 0 ;
	d->curidx = 0 ;
	d->head = NULL ;
	d->data = NULL ;
    }
    else error (1, "Cannot allocate memory for mobj object") ;
    return d ;
}

void mobj_close (MOBJ *d)
{
    if (d->data != NULL)
	free (d->data) ;
    free (d) ;
}

void mobj_free (MOBJ *d, void *data)
{
    switch (d->mode)
    {
	case MOBJ_CONST :
	    if (data != d->data)
		error (0, "Cannot free memory inside a MOBJ_CONST object") ;
	    if (d->data != NULL)
		free (d->data) ;
	    d->curidx = d->maxidx = 0 ;
	    d->head = d->data = NULL ;
	    break ;
	case MOBJ_MALLOC :
	    free (data) ;
	    d->curidx -= 1 ;			/* XXX */
	    break ;
	case MOBJ_REALLOC :
	    if (data != d->data)
		error (0, "Cannot free memory inside a MOBJ_REALLOC object") ;
	    if (d->data != NULL)
		free (d->data) ;
	    d->curidx = d->maxidx = 0 ;
	    d->head = d->data = NULL ;
	    break ;
	default :
	    error (0, "Invalid mode for MOBJ object allocation") ;
    }
}

static void mobj_realloc (MOBJ *d, int nelem)
{
    if (d->maxidx == 0)
	d->maxidx = MOBJ_MINSIZE ;

    if ((d->curidx + nelem) > d->maxidx * 2)
	d->maxidx = d->curidx + nelem ;
    else
	d->maxidx *= 2 ;

    d->data = realloc (d->data, d->maxidx * d->objsiz) ;
}

void *mobj_alloc (MOBJ *d, int nelem)
{
    void *data ;

    data = NULL ;			/* by default : error */
    switch (d->mode)
    {
	case MOBJ_CONST :
	    if ((d->curidx + nelem) > d->maxidx)
	    {
		if (d->data == NULL)
		    mobj_realloc (d, nelem) ;
		else error (1, "Cannot realloc memory for a MOBJ_CONST object") ;
	    }
	    data = d->data + d->curidx * d->objsiz ;
	    break ;
	case MOBJ_MALLOC :
	    data = malloc (nelem * d->objsiz) ;
	    break ;
	case MOBJ_REALLOC :
	    if ((d->curidx + nelem) > d->maxidx)
		mobj_realloc (d, nelem) ;
	    data = d->data + d->curidx * d->objsiz ;
	    break ;
	default :
	    error (0, "Invalid mode for MOBJ object allocation") ;
    }

    if (data != NULL)
	memset (data, 0, nelem * d->objsiz) ;

    d->curidx += nelem ;

    return data ;
}

void *mobj_data (MOBJ *d)
{
    return d->data ;
}

void *mobj_head (MOBJ *d)
{
    return d->head ;
}

void mobj_sethead (MOBJ *d, void *head)
{
    d->head = head ;
}

void mobj_empty (MOBJ *d)
{
    switch (d->mode)
    {
	case MOBJ_CONST :
	case MOBJ_REALLOC :
	    d->curidx = 0 ;
	    break ;
	default :
	    error (0, "Invalid mode for MOBJ object emptying") ;
    }
}

int mobj_size (MOBJ *d)
{
    return d->objsiz ;
}

int mobj_count (MOBJ *d)
{
    return d->curidx ;
}

int mobj_read (FILE *fp, MOBJ *d, int nelem)
{
    int r ;

    r = 0 ;
    if (d->data == NULL)
    {
	d->data = malloc (nelem * d->objsiz) ;
	if (d->data != NULL)
	{
	    if (fread (d->data, d->objsiz, nelem, fp) == nelem)
	    {
		d->maxidx = d->curidx = nelem ;
		r = 1 ;
	    }
	    else
	    {
		free (d->data) ;
		d->data = NULL ;
	    }
	}
    }

    return r ;
}

int mobj_write (FILE *fp, MOBJ *d)
{
    int r ;

    r = 0 ;
    if (d->data == NULL)
	error (0, "Cannot write MOBJ") ;

    if (fwrite (d->data, d->objsiz, d->curidx, fp) == d->curidx)
	r = 1 ;

    return r ;
}
