/*
 * $Id: buildgraph.c,v 1.7 2007-06-27 15:03:36 pda Exp $
 */

#include "graph.h"

/******************************************************************************
Match physical interfaces between equipements (i.e. physical links)
******************************************************************************/

void l1graph (void)
{
    struct node *n ;
    struct linklist *physlist ;		/* head of physical list */
    struct linklist *l ;

    /*
     * First, locate all L1 nodes to extract physical links and create
     * an appropriate structure, referenced by head of list physlist.
     */

    physlist = NULL ;
    for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
    {
	if (n->nodetype == NT_L1 && strcmp (n->u.l1.link, EXTLINK) != 0)
	{
	    struct link *pl ;
	    struct linklist *ll ;
	    struct symtab *s ;

	    s = symtab_get (n->u.l1.link) ;
	    pl = symtab_to_link (s) ;
	    if (pl == NULL)
	    {
		/* never seen this link : initialize it */
		pl = symtab_to_link (s) = mobj_alloc (linkmobj, 1) ;
		pl->name = symtab_to_name (s) ;
		pl->node [0] = n ;
		pl->node [1] = NULL ;

		ll = mobj_alloc (llistmobj, 1) ;
		ll->link = pl ;
		ll->next = physlist ;
		physlist = ll ;
	    }
	    else
	    {
		if (pl->node [1] == NULL)
		{
		    /* this is the other end of the link */
		    pl->node [1] = n ;
		}
		else
		{
		    /* a link with more than two endpoints... */
		    inconsistency ("Link '%s' has two many endpoints",
						n->u.l1.link) ;
		}
	    }
	}
    }

    /*
     * Next, connect all links to nodes linklists
     */

    l = physlist ;
    while (l != NULL)
    {
	struct linklist *llnext ;

	llnext = l->next ;

	if (l->link->node [1] == NULL)
	    inconsistency ("Link '%s' seen only on one node", l->link->name) ;
	else /* the link has two endpoints */
	    (void) create_link (l->link->name,
					l->link->node [0]->name,
					l->link->node [1]->name) ;

	mobj_free (linkmobj, l->link) ;
	mobj_free (llistmobj, l) ;
	l = llnext ;
    }
}

/******************************************************************************
Computes the list of Vlan-ids transported on each link
******************************************************************************/

void l2graph (void)
{
    struct node *n ;
    vlanset_t verr ;
    struct node *ref [MAXVLAN] ;
    int i ;

    for (i = 0 ; i < MAXVLAN ; i++)
	ref [i] = NULL ;

    for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
	vlan_zero (n->vlanset) ;
    vlan_zero (verr) ;			/* vlan for which we already reported an error */

    for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
    {
	if (n->nodetype == NT_L2 && ! vlan_isset (n->vlanset, n->u.l2.vlan))
	{
	    vlan_t v ;
	    struct node *l1 ;

	    l1 = get_neighbour (n, NT_L1) ;

	    v = n->u.l2.vlan ;
	    if (v > 1 && ref [v] != NULL && ! vlan_isset (verr, v))
	    {
		inconsistency ("Vlan '%d' disconnected between %s:%s and %s:%s",
				v, ref [v]->eq->name, ref [v]->u.l1.ifname,
				n->eq->name, ((l1!=NULL) ? l1->u.l1.ifname : "?")) ;
		vlan_set (verr, v) ;
	    }
	    else ref [v] = l1 ;

	    transport_vlan_on_L2 (n, v) ;
	}
    }
}


/******************************************************************************
Update active vlans on each equipement
******************************************************************************/

void update_lvlans (void)
{
    struct vlan *tabvlan ;
    struct node *n ;
    struct eq *eq ;
    struct lvlan *lv ;
    int i ;

    tabvlan = mobj_data (vlanmobj) ;

    for (i = 1 ; i < MAXVLAN ; i++)
    {
	for (eq = mobj_head (eqmobj) ; eq != NULL ; eq = eq->next)
	    eq->mark = 0 ;

	for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
	    if (n->nodetype == NT_L2 && vlan_isset (n->vlanset, i))
		n->eq->mark = 1 ;

	for (eq = mobj_head (eqmobj) ; eq != NULL ; eq = eq->next)
	{
	    if (eq->mark)
	    {
		for (lv = tabvlan [i].lvlan ; lv != NULL ; lv = lv->next)
		    if (lv->eq == eq)
			break ;

		if (lv == NULL)
		{
		    lv = mobj_alloc (lvlanmobj, 1) ;
		    lv->next = tabvlan [i].lvlan ;
		    tabvlan [i].lvlan = lv ;
		    lv->eq = eq ;
		    lv->vlanid = i ;
		    lv->name = NULL ;
		    lv->mark = 0 ;
		}

		lv->mark |= LVLAN_INCOMING ;
	    }
	}
    }
}


/******************************************************************************
Inconsistency checking
******************************************************************************/

void check_inconsistencies (void)
{
}

/******************************************************************************
Removes L2PAT and BRPAT nodes, and links
******************************************************************************/

void remove_link_to_me (struct node *from, struct node *me)
{
    struct node *other ;
    struct linklist *ll, *llprev, *llnext ;

    llprev = NULL ;
    ll = from->linklist ;
    while (ll != NULL)
    {
	llnext = ll->next ;

	other = getlinkpeer (ll->link, from) ;
	if (other == me)
	{
	    /* Remove only the linklist entry. */
	    mobj_free (llistmobj, ll) ;
	    if (llprev == NULL)
		from->linklist = llnext ;
	    else
		llprev->next = llnext ;
	}
	else llprev = ll ;
	ll = llnext ;
    }
}

void remove_l2pat_brpat (void)
{
    struct node *n, *nprev, *nnext, *other ;
    struct linklist *ll, *llnext ;

    nprev = NULL ;
    n = mobj_head (nodemobj) ; 
    while (n != NULL)
    {
	nnext = n->next ;

	if (n->nodetype == NT_L2PAT || n->nodetype == NT_BRPAT)
	{
	    /*
	     * Remove all links starting from this node, and
	     * symmetrical links.
	     */

	    ll = n->linklist ;
	    while (ll != NULL)
	    {
		llnext = ll->next ;

		/*
		 * Remove only the linklist entries pointing to us
		 * The link entry is shared, we will remove it later
		 * (in a few lines)
		 */

		other = getlinkpeer (ll->link, n) ;
		remove_link_to_me (other, n) ;

		/*
		 * Remove the link and the linklist entries.
		 */

		mobj_free (linkmobj, ll->link) ;
		mobj_free (llistmobj, ll) ;

		ll = llnext ;
	    }

	    /*
	     * Next in node list
	     */

	    if (nprev == NULL)
		mobj_sethead (nodemobj, nnext) ;
	    else
		nprev->next = nnext ;

	    mobj_free (nodemobj, n) ;
	}
	else nprev = n ;

	n = nnext ;
    }
}

/******************************************************************************
Attach network addresses to vlans
******************************************************************************/

void add_net_to_vlan (vlan_t vlan, ip_t *addr_in_net)
{
    ip_t net ;
    struct netlist *nl ;
    struct vlan *tab ;
    struct network *n ;

    tab = mobj_data (vlanmobj) ;
    ip_netof (addr_in_net, &net) ;
    n = net_get_n (&net) ;
    for (nl = tab [vlan].netlist ; nl != NULL ; nl = nl->next)
	if (&nl->net->addr == &n->addr)	/* pointer comparison */
	    break ;
    if (nl == NULL)
    {
	nl = mobj_alloc (nlistmobj, 1) ;
	nl->net = n ;
	nl->next = tab [vlan].netlist ;
	tab [vlan].netlist = nl ;
    }
}

void attach_net_to_vlan (void)
{
    struct node *n ;
    int vlan ;

    for (vlan = 2 ; vlan < MAXVLAN ; vlan++)
	for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
	    if (n->nodetype == NT_L3 && vlan_isset (n->vlanset, vlan))
		add_net_to_vlan (vlan, &n->u.l3.addr) ;
}


/******************************************************************************
Main function
******************************************************************************/

MOBJ *newmobj [NB_MOBJ] ;

int main (int argc, char *argv [])
{
    text_read (stdin) ;
    l1graph () ;
    check_links () ;
    l2graph () ;
    update_lvlans () ;
    check_inconsistencies () ;
    remove_l2pat_brpat () ;
    attach_net_to_vlan () ;
    duplicate_graph (newmobj, mobjlist) ;
    bin_write (stdout, newmobj) ;
    exit (0) ;
}
