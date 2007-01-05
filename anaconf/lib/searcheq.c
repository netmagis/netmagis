/*
 * $Id: searcheq.c,v 1.1.1.1 2007-01-05 15:12:00 pda Exp $
 */

#include "graph.h"

/*
 * Name must be a string in the symbol table
 */

struct eq *search_eq (char *name)
{
    struct eq *e ;

    for (e = mobj_head (eqmobj) ; e != NULL ; e = e->next)
	if (e->name == name)		/* all names are in the symbol table */
	    break ;
    return e ;
}

