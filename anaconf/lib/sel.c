/*
 * $Id: sel.c,v 1.1 2007-01-10 16:49:53 pda Exp $
 */

#include "graph.h"

#include <regex.h>

#define	RE_MODE	(REG_EXTENDED | REG_ICASE)


struct selnet
{
    ip_t addr ;
    struct selnet *next ;
} ;

struct selrex
{
    regex_t rc ;
    struct selrex *next ;
} ;

MOBJ *selnetmobj, *selrexmobj ;


void sel_init (void)
{
    selnetmobj = mobj_init (sizeof (struct selnet), MOBJ_MALLOC) ;
    selrexmobj = mobj_init (sizeof (struct selrex), MOBJ_MALLOC) ;
}

void sel_end (void)
{
    struct selnet *sn ;
    struct selrex *sr ;

    sn = mobj_head (selnetmobj) ;
    while (sn != NULL)
    {
	struct selnet *tmp ;

	tmp = sn->next ;
	mobj_free (selnetmobj, sn) ;
	sn = tmp ;
    }
    mobj_close (selnetmobj) ;

    sr = mobj_head (selrexmobj) ;
    while (sr != NULL)
    {
	struct selrex *tmp ;

	tmp = sr->next ;
	regfree (&sr->rc) ;
	mobj_free (selrexmobj, sn) ;
	sr = tmp ;
    }
    mobj_close (selrexmobj) ;
}

int sel_network (iptext_t addr)
{
    struct selnet *s ;
    ip_t a ;
    int r ;

    r = 0 ;
    if (ip_pton (addr, &a))
    {
	s = mobj_alloc (selnetmobj, 1) ;
	s->addr = a ;
	s->next = mobj_head (selnetmobj) ;
	mobj_sethead (selnetmobj, s) ;
	r = 1 ;
    }

    return r ;
}

int sel_regexp (char *rex)
{
    regex_t rc ;
    struct selrex *s ;
    int r ;

    r = 0 ;
    if (regcomp (&rc, rex, RE_MODE) == 0)
    {
	s = mobj_alloc (selrexmobj, 1) ;
	s->rc = rc ;
	s->next = mobj_head (selrexmobj) ;
	mobj_sethead (selrexmobj, s) ;
	r = 1 ;
    }

    return r ;
}

static void sel_mark_net (ip_t *net)
{
    struct node *n, *l2node ;

    for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
    {
	if (n->nodetype == NT_L3 && ip_match (&n->u.l3.addr, net, 0))
	{
	    l2node = get_neighbour (n, NT_L2) ;
	    if (l2node != NULL)
		transport_vlan_on_L2 (l2node, l2node->u.l2.vlan) ;
	}
    }

    for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
	if ((n->mark & MK_L2TRANSPORT) != 0)
	    n->mark = MK_SELECTED ;
}

static void sel_mark_regexp (regex_t *rc)
{
    struct eq *eq ;

    for (eq = mobj_head (eqmobj) ; eq != NULL ; eq = eq->next)
	if (regexec (rc, eq->name, 0, NULL, 0) == 0)
	    eq->mark = 1 ;
}


void sel_mark (void)
{
    struct selnet *sn ;
    struct selrex *sr ;
    struct node *n ;
    struct eq *eq ;

    if (mobj_head (selnetmobj) == NULL && mobj_head (selrexmobj) == NULL)
    {
	for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
	    n->mark = MK_SELECTED ;
    }
    else
    {
	for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
	{
	    n->mark = 0 ;
	    vlan_zero (n->vlanset) ;
	}

	for (eq = mobj_head (eqmobj) ; eq != NULL ; eq = eq->next)
	    eq->mark = 0 ;

	for (sn = mobj_head (selnetmobj) ; sn != NULL ; sn = sn->next)
	    sel_mark_net (&sn->addr) ;

	for (sr = mobj_head (selrexmobj) ; sr != NULL ; sr = sr->next)
	    sel_mark_regexp (&sr->rc) ;

	for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
	    if (n->eq->mark)
		n->mark |= MK_SELECTED ;
    }
}
