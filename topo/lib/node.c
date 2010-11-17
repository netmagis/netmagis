/*
 */

#include "graph.h"

/******************************************************************************
Node management
******************************************************************************/

struct node *create_node (char *name, struct eq *eq, enum nodetype nodetype)
{
    struct node *n ;
    char *s ;
    struct symtab *p ;

    p = symtab_get (name) ;

    s = symtab_to_name (p) ;
    MOBJ_ALLOC_INSERT (n, nodemobj) ;
    memset (n, 0, sizeof n) ;
    n->name = s ;
    n->eq = eq ;
    n->nodetype = nodetype ;
    n->linklist = NULL ;
    symtab_to_node (p) = n ;

    return n ;
}

char *new_nodename (char *eqname)
{
    static int maxindex = 0 ;
    static char name [MAXLINE] ;

    do
    {
	sprintf (name, "%s:%d", eqname, ++maxindex) ;
    } while (symtab_lookup (name) != NULL) ;

    return name ;
}

