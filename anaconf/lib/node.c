/*
 * $Id: node.c,v 1.2 2007-01-10 16:49:53 pda Exp $
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
    n = mobj_alloc (nodemobj, 1) ;
    n->name = s ;
    n->eq = eq ;
    n->nodetype = nodetype ;

    n->linklist = NULL ;

    n->next = mobj_head (nodemobj) ;
    mobj_sethead (nodemobj, n) ;

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

