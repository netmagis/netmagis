/*
 * $Id: textwrite.c,v 1.2 2007-01-09 10:46:10 pda Exp $
 */

#include "graph.h"

/******************************************************************************
Output graph in textual form
******************************************************************************/

static void text_write_eq (FILE *fp)
{
    struct eq *e ;

    for (e = mobj_head (eqmobj) ; e != NULL ; e = e->next)
	fprintf (fp, "eq %s type %s model %s snmp %s\n",
				e->name,
				e->type,
				e->model,
				(e->snmp == NULL ? "-" : e->snmp)
			    ) ;
}

static void text_write_nodes (FILE *fp)
{
    struct node *n ;
    iptext_t ipaddr ;

    for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
    {
	switch (n->nodetype)
	{
	    case NT_L1 :
		fprintf (fp, "node %s type L1 eq %s name %s link %s encap %s stat %s desc %s\n",
				n->name,
				n->eq,
				n->u.l1.ifname,
				n->u.l1.link,
				(n->u.l1.l1type == L1T_TRUNK ? "trunk" : "ether"),
				(n->u.l1.stat == NULL ? "-" : n->u.l1.stat),
				(n->u.l1.ifdesc == NULL ? "-" : n->u.l1.ifdesc)
			    ) ;
		break ;
	    case NT_L2 :
		fprintf (fp, "node %s type L2 eq %s vlan %d stat %s\n",
				n->name,
				n->eq,
				n->u.l2.vlan,
				(n->u.l2.stat == NULL ? "-" : n->u.l2.stat)
			    ) ;
		break ;
	    case NT_L3 :
		if (! ip_ntop (&n->u.l3.addr, ipaddr, 1))
		{
		    inconsistency ("Invalid address for node '%s'", n->name) ;
		    exit (1) ;
		}
		fprintf (fp, "node %s type L3 eq %s addr %s\n",
				n->name,
				n->eq,
				ipaddr
			    ) ;
		break ;
	    case NT_BRIDGE :
		fprintf (fp, "node %s type bridge eq %s\n",
				n->name,
				n->eq
			    ) ;
		break ;
	    case NT_ROUTER :
		fprintf (fp, "node %s type router eq %s instance %s\n",
				n->name,
				n->eq,
				n->u.router.name
			    ) ;
		break ;
	    case NT_L2PAT :
		fprintf (fp, "node %s type L2pat ERROR\n",
				n->name) ;
		break ;
	    case NT_BRPAT :
		fprintf (fp, "node %s type brpat ERROR\n",
				n->name) ;
		break ;
	    default :
		inconsistency ("Incoherent node '%s'", n->name) ;
		exit (1) ;
	}
    }
}

static void text_write_links (FILE *fp)
{
    struct node *n ;

    for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
	n->mark = 0 ;

    for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
    {
	struct linklist *ll ;

	for (ll = n->linklist ; ll != NULL ; ll = ll->next)
	{
	    struct link *l ;
	    struct node *n1, *n2 ;

	    l = ll->link ;
	    n1 = l->node [0] ;
	    n2 = l->node [1] ;
	    if (n1->mark == 0 && n2->mark == 0)
	    {
		fprintf (fp, "link %s %s", n1->name, n2->name) ;
		if (l->name != NULL)
		    fprintf (fp, " name %s", l->name) ;
		fprintf (fp, "\n") ;
	    }
	}

	n->mark = 1 ;
    }
}

static void text_write_rnet (FILE *fp)
{
    struct rnet *n ;
    struct route *r ;
    iptext_t addr, vrrpaddr, netaddr, gwaddr ;

    for (n = mobj_head (rnetmobj) ; n != NULL ; n = n->next)
    {
	ip_ntop (&n->net->addr, addr, 1) ;
	fprintf (fp, "rnet %s %s %s %s %s",
				addr,
				n->router->name,
				n->l3->name,
				n->l2->name,
				n->l1->name) ;

	if (n->vrrpaddr.preflen == 0)
	    fprintf (fp, " - -") ;
	else
	{
	    ip_ntop (&n->vrrpaddr, vrrpaddr, 0) ;
	    fprintf (fp, " %s %d", vrrpaddr, n->vrrpprio) ;
	}

	for (r = n->routelist ; r != NULL ; r = r->next)
	{
	    ip_ntop (&r->net, netaddr, 1) ;
	    ip_ntop (&r->gw, gwaddr, 0) ;
	    fprintf (fp, " %s %s", netaddr, gwaddr) ;
	}
	fprintf (fp, "\n") ;
    }
}

static void text_write_vlans (FILE *fp)
{
    vlan_t v ;
    struct vlan *tab ;

    tab = mobj_data (vlanmobj) ;
    for (v = 0 ; v < MAXVLAN ; v++)
    {
	if (tab [v].name != NULL)
	{
	    iptext_t n ;
	    struct netlist *nl ;

	    fprintf (fp, "vlan %d desc %s", v, tab [v].name) ;
	    for (nl = tab [v].netlist ; nl != NULL ; nl = nl->next)
	    {
		ip_ntop (&nl->net->addr, n, 1) ;
		fprintf (fp, " net %s", n) ;
	    }
	    fprintf (fp, "\n") ;
	}
    }
}

void text_write (FILE *fp)
{
    text_write_eq (fp) ;
    text_write_nodes (fp) ;
    text_write_links (fp) ;
    text_write_rnet (fp) ;
    text_write_vlans (fp) ;
}
