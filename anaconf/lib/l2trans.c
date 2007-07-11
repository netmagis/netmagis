/*
 * $Id: l2trans.c,v 1.4 2007-07-11 20:21:04 pda Exp $
 */

#include "graph.h"

static void transport_vlan_on_L1 (struct node *n, vlan_t v) ;
static void transport_vlan_on_L2pat (struct node *n, vlan_t v, struct node *prev) ;
static void transport_vlan_on_brpat (struct node *n, vlan_t v, struct node *prev) ;
static void transport_vlan_on_bridge (struct node *n) ;

void transport_vlan_on_L2 (struct node *n, vlan_t v) ;


/******************************************************************************
Computes the list of Vlan-ids transported on each link
******************************************************************************/

static int match_vlan (vlan_t v, struct vlanlist *list)
{
    int found ;

    found = 0 ;
    while (list != NULL)
    {
	if (v >= list->min && v <= list->max)
	{
	    found = 1 ;
	    break ;
	}
	list = list->next ;
    }
    return found ;
}


static void transport_vlan_on_L1 (struct node *n, vlan_t v)
{
    struct linklist *ll ;
    int l2seen, l2pat ;

    if (vlan_isset (n->vlanset, v))
	return ;
    vlan_set (n->vlanset, v) ;

    MK_SET (n, MK_L2TRANSPORT) ;

    /*
     * First pass : avoid L2pat nodes, since we only want to
     * instanciate them if there is no L2 node for this vlan.
     */

    l2pat = 0 ;
    l2seen = 0 ;

    for (ll = n->linklist ; ll != NULL ; ll = ll->next)
    {
	struct link *l ;
	struct node *other ;

	l = ll->link ;
	other = getlinkpeer (l, n) ;

	switch (other->nodetype)
	{
	    case NT_L1 :
		transport_vlan_on_L1 (other, v) ;
		break ;
	    case NT_L2 :
		if (n->u.l1.l1type == L1T_TRUNK)
		{
		    if (other->u.l2.vlan == v)
		    {
			l2seen = 1 ;
			transport_vlan_on_L2 (other, v) ;
		    }
		}
		else
		{
		    l2seen = 1 ;
		    transport_vlan_on_L2 (other, other->u.l2.vlan) ;
		}
		break ;
	    case NT_L3 :
		inconsistency ("L1-L3 : Should not happen") ;
		exit (2) ;
		break ;
	    case NT_BRIDGE :
		inconsistency ("L1-BRIDGE : Should not happen") ;
		exit (2) ;
		break ;
	    case NT_ROUTER :
		inconsistency ("L1-ROUTER : Should not happen") ;
		exit (2) ;
		break ;
	    case NT_L2PAT :
		l2pat = 1 ;
		break ;
	    case NT_BRPAT :
		inconsistency ("L1-BRPAT : Should not happen") ;
		exit (2) ;
		break ;
	}
    }

    /*
     * Second pass : if there is no L2 node for this vlan,
     * look for an L2pat to instanciate.
     */

    if (l2pat && ! l2seen)
    {
	for (ll = n->linklist ; ll != NULL ; ll = ll->next)
	{
	    struct link *l ;
	    struct node *other ;

	    l = ll->link ;
	    other = getlinkpeer (l, n) ;

	    if (other->nodetype == NT_L2PAT)
	    {
		if (n->u.l1.l1type == L1T_TRUNK)
		{
		    if (match_vlan (v, other->u.l2pat.allowed))
			transport_vlan_on_L2pat (other, v, n) ;
		}
		else
		{
		    inconsistency ("L1(ether)-L2PAT : Should not happen") ;
		    exit (2) ;
		}
	    }
	}
    }
}

static void transport_vlan_on_L2pat (struct node *n, vlan_t v, struct node *prev)
{
    struct linklist *ll ;
    struct node *l2node ;

    if (vlan_isset (n->vlanset, v))
	return ;
    vlan_set (n->vlanset, v) ;

    /*
     * Instanciate this L2pat into a L2
     */

    l2node = create_node (new_nodename (n->eq->name), n->eq,  NT_L2) ;
    l2node->u.l2.vlan = v ;
    l2node->u.l2.stat = NULL ;
    (void) create_link (NULL, prev->name, l2node->name) ;

    vlan_set (l2node->vlanset, v) ;
    MK_SET (l2node, MK_L2TRANSPORT) ;
    for (ll = n->linklist ; ll != NULL ; ll = ll->next)
    {
	struct link *l ;
	struct node *other ;

	l = ll->link ;
	other = getlinkpeer (l, n) ;

	switch (other->nodetype)
	{
	    case NT_L1 :
		if (other->u.l1.l1type == L1T_TRUNK)
		{
		    if (other != prev)
			(void) create_link (NULL, l2node->name, other->name) ;
		    transport_vlan_on_L1 (other, v) ;
		}
		else
		{
		    inconsistency ("L2PAT-L1(ether) : Should not happen") ;
		    exit (2) ;
		}
		break ;
	    case NT_L2 :
		inconsistency ("L2PAT-L2 : Should not happen") ;
		exit (2) ;
		break ;
	    case NT_L3 :
		inconsistency ("L2PAT-L3 : Should not happen") ;
		exit (2) ;
		break ;
	    case NT_BRIDGE :
		inconsistency ("L2PAT-BRIDGE : Should not happen") ;
		exit (2) ;
		break ;
	    case NT_ROUTER :
		inconsistency ("L2PAT-ROUTER : Should not happen") ;
		exit (2) ;
		break ;
	    case NT_L2PAT :
		inconsistency ("L2PAT-L2PAT : Should not happen") ;
		exit (2) ;
		break ;
	    case NT_BRPAT :
		/*
		 *			 brpat
		 *			 |      vlan transported
		 *			 |      |  L2 just created
		 *			 |      |  |
		 *			 v      v  v
		 */
		transport_vlan_on_brpat (other, v, l2node) ;
		break ;
	}
    }
}

static void transport_vlan_on_brpat (struct node *n, vlan_t v, struct node *prev)
{
    struct linklist *ll ;
    struct node *bridgenode ;

    if (vlan_isset (n->vlanset, v))
	return ;
    vlan_set (n->vlanset, v) ;

    /*
     * Instanciate this brpat into a bridge
     */

    bridgenode = create_node (new_nodename (n->eq->name), n->eq,  NT_BRIDGE) ;
    (void) create_link (NULL, prev->name, bridgenode->name) ;
    vlan_set (bridgenode->vlanset, v) ;

    for (ll = n->linklist ; ll != NULL ; ll = ll->next)
    {
	struct link *l ;
	struct node *other ;

	l = ll->link ;
	other = getlinkpeer (l, n) ;

	switch (other->nodetype)
	{
	    case NT_L1 :
		inconsistency ("BRPAT-L1 : Should not happen") ;
		exit (2) ;
		break ;
	    case NT_L2 :
		if (other->u.l2.vlan == v && other != prev)
		{
		    (void) create_link (NULL, bridgenode->name, other->name) ;
		    transport_vlan_on_L2 (other, v) ;
		}
		break ;
	    case NT_L3 :
		inconsistency ("BRPAT-L3 : Should not happen") ;
		exit (2) ;
		break ;
	    case NT_BRIDGE :
		inconsistency ("BRPAT-BRIDGE : Should not happen") ;
		exit (2) ;
		break ;
	    case NT_ROUTER :
		inconsistency ("BRPAT-ROUTER : Should not happen") ;
		exit (2) ;
		break ;
	    case NT_L2PAT :
		if (match_vlan (v, other->u.l2pat.allowed))
		    transport_vlan_on_L2pat (other, v, bridgenode) ;
		break ;
	    case NT_BRPAT :
		inconsistency ("BRPAT-BRPAT : Should not happen") ;
		exit (2) ;
		break ;
	}
    }
}

void transport_vlan_on_bridge (struct node *n)
{
    struct linklist *ll ;
    vlan_t v ;

    if (vlan_isset (n->vlanset, 0))
	return ;
    vlan_set (n->vlanset, 0) ;

    MK_SET (n, MK_L2TRANSPORT) ;
    for (ll = n->linklist ; ll != NULL ; ll = ll->next)
    {
	struct link *l ;
	struct node *other ;

	l = ll->link ;
	other = getlinkpeer (l, n) ;

	switch (other->nodetype)
	{
	    case NT_L1 :
		inconsistency ("BRIDGE-L1 : Should not happen") ;
		exit (2) ;
		break ;
	    case NT_L2 :
		v = other->u.l2.vlan ;
		transport_vlan_on_L2 (other, v) ;
		break ;
	    case NT_L3 :
		inconsistency ("BRIDGE-L3 : Should not happen") ;
		exit (2) ;
		break ;
	    case NT_BRIDGE :
		inconsistency ("BRIDGE-BRIDGE : Should not happen") ;
		exit (2) ;
		break ;
	    case NT_ROUTER :
		inconsistency ("BRIDGE-ROUTER : Should not happen") ;
		exit (2) ;
		break ;
	    case NT_L2PAT :
		inconsistency ("BRIDGE-L2PAT : Should not happen") ;
		exit (2) ;
		break ;
	    case NT_BRPAT :
		inconsistency ("BRIDGE-BRPAT : Should not happen") ;
		exit (2) ;
		break ;
	}
    }
}

void transport_vlan_on_L3 (struct node *n, vlan_t v)
{
    if (vlan_isset (n->vlanset, v))
	return ;
    vlan_set (n->vlanset, v) ;

    MK_SET (n, MK_L2TRANSPORT) ;
}

void transport_vlan_on_L2 (struct node *n, vlan_t v)
{
    struct linklist *ll ;
    int brpat, brseen ;

    if (vlan_isset (n->vlanset, v))
	return ;
    vlan_set (n->vlanset, v) ;

    MK_SET (n, MK_L2TRANSPORT) ;

    /*
     * First pass : avoid BRpat nodes, since we only want to
     * instanciate them if there is no bridge node for this vlan.
     */

    brpat = 0 ;
    brseen = 0 ;

    for (ll = n->linklist ; ll != NULL ; ll = ll->next)
    {
	struct link *l ;
	struct node *other ;

	l = ll->link ;
	other = getlinkpeer (l, n) ;

	switch (other->nodetype)
	{
	    case NT_L1 :
		if (other->u.l1.l1type == L1T_TRUNK)
		    transport_vlan_on_L1 (other, v) ;
		else
		    transport_vlan_on_L1 (other, 0) ;
		break ;
	    case NT_L2 :
		inconsistency ("L2-L2 : Should not happen") ;
		break ;
	    case NT_L3 :
		transport_vlan_on_L3 (other, v) ;
		break ;
	    case NT_BRIDGE :
		brseen = 1 ;
		transport_vlan_on_bridge (other) ;
		break ;
	    case NT_ROUTER :
		inconsistency ("L2-ROUTER : Should not happen") ;
		exit (2) ;
		break ;
	    case NT_L2PAT :
		break ;
	    case NT_BRPAT :
		brpat = 1 ;
		break ;
	}
    }

    /*
     * Second pass : if there is no bridge node for this vlan,
     * look for an BRpat to instanciate.
     */

    if (brpat && ! brseen)
    {
	for (ll = n->linklist ; ll != NULL ; ll = ll->next)
	{
	    struct link *l ;
	    struct node *other ;

	    l = ll->link ;
	    other = getlinkpeer (l, n) ;

	    if (other->nodetype == NT_BRPAT)
	    {
		/*
		 *                       brpat
		 *                       |      vlan transported
		 *                       |      |  current L2
		 *                       |      |  |
		 *                       v      v  v
		 */
		transport_vlan_on_brpat (other, v, n) ;
	    }
	}
    }
}
