/*
 * $Id: sel.c,v 1.2 2007-01-11 15:31:22 pda Exp $
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

static void sel_mark_net (ip_t *addr)
{
    struct node *n, *l2node ;
    struct network *net ;

    for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
    {
	if (n->nodetype == NT_L3 && ip_match (&n->u.l3.addr, addr, 0))
	{
	    MK_SELECT (n) ;
	    l2node = get_neighbour (n, NT_L2) ;
	    if (l2node != NULL)
		transport_vlan_on_L2 (l2node, l2node->u.l2.vlan) ;
	}
    }

    for (net = mobj_head (netmobj) ; net != NULL ; net = net->next)
	if (ip_match (&net->addr, addr, 0))
	    MK_SELECT (net) ;

    for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
	if ((n->mark & MK_L2TRANSPORT) != 0)
	    MK_SELECT (n) ;
}

static void sel_mark_regexp (regex_t *rc)
{
    struct eq *eq ;

    for (eq = mobj_head (eqmobj) ; eq != NULL ; eq = eq->next)
	if (regexec (rc, eq->name, 0, NULL, 0) == 0)
	    MK_SELECT (eq) ;
}


void sel_mark (void)
{
    struct selnet *sn ;
    struct selrex *sr ;
    struct node *n ;
    struct eq *eq ;
    struct vlan *vlantab ;
    struct network *net ;
    int i ;

    vlantab = mobj_data (vlanmobj) ;

    if (mobj_head (selnetmobj) == NULL && mobj_head (selrexmobj) == NULL)
    {
	for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
	    n->mark = MK_SELECTED ;
	for (eq = mobj_head (eqmobj) ; eq != NULL ; eq = eq->next)
	    eq->mark = MK_SELECTED ;
	for (i = 0 ; i < MAXVLAN ; i++)
	    vlantab [i].mark = MK_SELECTED ;
	for (net = mobj_head (netmobj) ; net != NULL ; net = net->next)
	    net->mark = MK_SELECTED ;

    }
    else
    {
	/*
	 * Preparation
	 */

	for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
	{
	    n->mark = 0 ;
	    vlan_zero (n->vlanset) ;
	}

	for (eq = mobj_head (eqmobj) ; eq != NULL ; eq = eq->next)
	    eq->mark = 0 ;

	for (i = 0 ; i < MAXVLAN ; i++)
	    vlantab [i].mark = 0 ;

	for (net = mobj_head (netmobj) ; net != NULL ; net = net->next)
	    net->mark = 0 ;

	/*
	 * Select nodes based on network cidr
	 * Select routed networks based on network cidr
	 */

	for (sn = mobj_head (selnetmobj) ; sn != NULL ; sn = sn->next)
	    sel_mark_net (&sn->addr) ;

	/*
	 * Select equipements based on regexp
	 */

	for (sr = mobj_head (selrexmobj) ; sr != NULL ; sr = sr->next)
	    sel_mark_regexp (&sr->rc) ;

	/*
	 * Select equipements where node are selected
	 */

	for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
	    if (n->mark)
		MK_SELECT (n->eq) ;

	/*
	 * Select Vlans where L2 node are selected
	 */

	for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
	    if (n->nodetype == NT_L2 && MK_ISSELECTED (n))
		MK_SELECT (&vlantab [n->u.l2.vlan]) ;
    }
}
