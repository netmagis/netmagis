/*
 * $Id: node.c,v 1.1.1.1 2007-01-05 15:12:00 pda Exp $
 */

#include "graph.h"

/******************************************************************************
Node management
******************************************************************************/

struct node *create_node (char *name, char *eq, enum nodetype nodetype)
{
    struct node *n ;
    char *s1, *s2 ;
    struct symtab *p ;

    p = symtab_get (name) ;

    s1 = symtab_to_name (p) ;
    s2 = symtab_to_name (symtab_get (eq)) ;
    n = mobj_alloc (nodemobj, 1) ;
    n->name = s1 ;
    n->eq = s2 ;
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

