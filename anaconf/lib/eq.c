/*
 * $Id: eq.c,v 1.1 2007-01-10 18:09:54 pda Exp $
 */

#include "graph.h"

/******************************************************************************
Equipement management
******************************************************************************/

/*
 * Look up equipement (in network format)
 */

struct eq *eq_lookup (char *name)
{
    struct eq *eq ;

    for (eq = mobj_head (eqmobj) ; eq != NULL ; eq = eq->next)
	if (strcmp (eq->name, name) == 0)
	    break ;
    return eq ;
}

struct eq *eq_get (char *name, int nameinsymtab)
{
    struct eq *eq ;

    eq = eq_lookup (name) ;
    if (eq == NULL)
    {
	eq = mobj_alloc (eqmobj, 1) ;
	if (! nameinsymtab)
	    name = symtab_to_name (symtab_get (name)) ;
	eq->name = name ;
	eq->next = mobj_head (eqmobj) ;
	mobj_sethead (eqmobj, eq) ;
    }
    return eq ;
}
