/*
 */

#include "graph.h"

/******************************************************************************
Symbol table management
******************************************************************************/

#define	MAXHASH		32749

struct symtab **hashtable ;

void symtab_init (void)
{
    int i ;

    hashtable = mobj_alloc (hashmobj, MAXHASH) ;
    for (i = 0 ; i < MAXHASH ; i++)
	hashtable [i] = NULL ;
}

/*
 * Computes the hash value for a name
 *
 * Input :
 *   name : name
 * Output :
 *   return value : hash value
 *
 * Note : the hash value is the concatenation of the 2 lowest bits
 *   of each byte.
 *
 * History :
 *   2004/03/30 : pda/jean : design
 */

static int hash (char *name)
{
    unsigned int s ;

    s = 0 ;
    while (*name != '\0')
	s = (s << 2) | (*name++ & 0x3) ;
    return s % MAXHASH ;
}

/*
 * Lookup a name in the symbol table, and returns the name found, which
 * is garanteed to be unique.
 *
 * Input :
 *   name : name
 * Output :
 *   return value : name
 *
 * Note : the memory pointed to by the parameter "name" can be
 *   deallocated by the caller.
 *
 * History :
 *   2004/03/30 : pda/jean : design
 */

struct symtab *symtab_lookup (char *name)
{
    int h ;
    struct symtab *p ;

    h = hash (name) ;
    p = hashtable [h] ;
    while (p != NULL)
    {
	if (strcmp (p->name, name) == 0)
	    break ;
	p = p->next ;
    }
    return p ;
}

struct symtab *symtab_get (char *name)
{
    int h ;
    struct symtab *p ;

    p = symtab_lookup (name) ;
    if (p == NULL)
    {
	p = mobj_alloc (symmobj, 1) ;
	p->name = mobj_alloc (strmobj, strlen (name) + 1) ;
	strcpy (p->name, name) ;

	h = hash (name) ;
	p->next = hashtable [h] ;
	hashtable [h] = p ;
    }
    return p ;
}
