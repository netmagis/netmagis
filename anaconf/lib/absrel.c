/*
 * $Id: absrel.c,v 1.1.1.1 2007-01-05 15:12:00 pda Exp $
 */

#include "graph.h"

#define	CONVREL(ptr,base)	((void *) ((ptr) == NULL ? -1 : \
					(((__typeof__ (base))(ptr)) - (base))))
#define	ABSTOREL(ptr,base)	((ptr)= CONVREL ((ptr), (base)))
#define	PROLOGREL(m,d,base)	\
	do { \
	    void *_x ; \
	    m = mobj_count (d) ; \
	    _x = mobj_head (d) ; \
	    mobj_sethead ((d), CONVREL (_x, (base))) ; \
	} while (0)


void abs_to_rel (MOBJ *graph [])
{
    int i, max ;

    struct symtab **hashtab 	= mobj_data (graph [HASHMOBJIDX]) ;
    struct symtab *symtab	= mobj_data (graph [SYMMOBJIDX]) ;
    char *strtab		= mobj_data (graph [STRMOBJIDX]) ;
    struct node *nodetab	= mobj_data (graph [NODEMOBJIDX]) ;
    struct link *linktab	= mobj_data (graph [LINKMOBJIDX]) ;
    struct linklist *llisttab	= mobj_data (graph [LLISTMOBJIDX]) ;
    struct eq *eqtab		= mobj_data (graph [EQMOBJIDX]) ;
    char **vdesctab		= mobj_data (graph [VDESCMOBJIDX]) ;
    struct network *nettab	= mobj_data (graph [NETMOBJIDX]) ;
    struct route *routetab	= mobj_data (graph [ROUTEMOBJIDX]) ;

    PROLOGREL (max, graph [HASHMOBJIDX], hashtab) ;
    for (i = 0 ; i < max ; i++)
    {
	ABSTOREL (hashtab [i], symtab) ;
    }

    PROLOGREL (max, graph [SYMMOBJIDX], symtab) ;
    for (i = 0 ; i < max ; i++)
    {
	ABSTOREL (symtab [i].name, strtab) ;
	ABSTOREL (symtab [i].node, nodetab) ;
	ABSTOREL (symtab [i].link, linktab) ;
	ABSTOREL (symtab [i].next, symtab) ;
    }

    PROLOGREL (max, graph [STRMOBJIDX], strtab) ;
    /* nothing for strmobj */

    PROLOGREL (max, graph [NODEMOBJIDX], nodetab) ;
    for (i = 0 ; i < max ; i++)
    {
	ABSTOREL (nodetab [i].name, strtab) ;
	ABSTOREL (nodetab [i].eq, strtab) ;
	ABSTOREL (nodetab [i].next, nodetab) ;
	ABSTOREL (nodetab [i].linklist, llisttab) ;

	switch (nodetab [i].nodetype)
	{
	    case NT_L1 :
		ABSTOREL (nodetab [i].u.l1.ifname, strtab) ;
		ABSTOREL (nodetab [i].u.l1.link, strtab) ;
		ABSTOREL (nodetab [i].u.l1.stat, strtab) ;
		break ;
	    case NT_L2 :
		ABSTOREL (nodetab [i].u.l2.stat, strtab) ;
		break ;
	    case NT_ROUTER :
		ABSTOREL (nodetab [i].u.router.name, strtab) ;
		break ;
	    default :
		break ;
	}
    }

    PROLOGREL (max, graph [LINKMOBJIDX], linktab) ;
    for (i = 0 ; i < max ; i++)
    {
	ABSTOREL (linktab [i].name, strtab) ;
	ABSTOREL (linktab [i].node [0], nodetab) ;
	ABSTOREL (linktab [i].node [1], nodetab) ;
    }

    PROLOGREL (max, graph [LLISTMOBJIDX], llisttab) ;
    for (i = 0 ; i < max ; i++)
    {
	ABSTOREL (llisttab [i].link, linktab) ;
	ABSTOREL (llisttab [i].next, llisttab) ;
    }

    PROLOGREL (max, graph [EQMOBJIDX], eqtab) ;
    for (i = 0 ; i < max ; i++)
    {
	ABSTOREL (eqtab [i].name, strtab) ;
	ABSTOREL (eqtab [i].type, strtab) ;
	ABSTOREL (eqtab [i].model, strtab) ;
	ABSTOREL (eqtab [i].snmp, strtab) ;
	ABSTOREL (eqtab [i].next, eqtab) ;
    }

    PROLOGREL (max, graph [VDESCMOBJIDX], vdesctab) ;
    for (i = 0 ; i < max ; i++)
    {
	ABSTOREL (vdesctab [i], strtab) ;
    }

    PROLOGREL (max, graph [NETMOBJIDX], nettab) ;
    for (i = 0 ; i < max ; i++)
    {
	ABSTOREL (nettab [i].router, nodetab) ;
	ABSTOREL (nettab [i].l3, nodetab) ;
	ABSTOREL (nettab [i].l2, nodetab) ;
	ABSTOREL (nettab [i].l1, nodetab) ;
	ABSTOREL (nettab [i].routelist, routetab) ;
	ABSTOREL (nettab [i].next, nettab) ;
    }

    PROLOGREL (max, graph [ROUTEMOBJIDX], routetab) ;
    for (i = 0 ; i < max ; i++)
    {
	ABSTOREL (routetab [i].next, routetab) ;
    }
}
