/*
 */

#include "graph.h"

#define	MK_LINK		(MK_LAST << 1)
#define	MK_PRINTED	(MK_LAST << 2)

/******************************************************************************
Output graph in textual form
******************************************************************************/

static void text_write_eq (FILE *fp)
{
    struct node *n ;
    struct eq *eq ;

    for (eq = mobj_head (eqmobj) ; eq != NULL ; eq = eq->next)
	MK_CLEAR (eq, MK_PRINTED) ;

    for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
    {
	int selected ;

	eq = n->eq ;
	selected = MK_ISSELECTED (n) || MK_ISSELECTED (eq) ;
	if (selected && ! MK_ISSET (eq, MK_PRINTED))
	{
	    fprintf (fp, "eq %s type %s model %s snmp %s location %s manual %d\n",
				eq->name,
				eq->type,
				eq->model,
				(eq->snmp == NULL ? "-" : eq->snmp),
				(eq->location == NULL ? "-" : eq->location),
				eq->manual
			    ) ;
	    MK_SET (eq, MK_PRINTED) ;
	}
    }
}

static void text_write_nodes (FILE *fp)
{
    struct node *n ;
    iptext_t ipaddr ;
    char *l1type ;

    for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
    {
	if (MK_ISSELECTED (n))
	{
	    switch (n->nodetype)
	    {
		case NT_L1 :
		    switch (n->u.l1.l1type)
		    {
			case L1T_DISABLED :
			    l1type = "disabled" ;
			    break ;
			case L1T_TRUNK :
			    l1type = "trunk" ;
			    break ;
			case L1T_ETHER :
			    l1type = "ether" ;
			    break ;
		    }

		    fprintf (fp, "node %s type L1 eq %s name %s link %s encap %s stat %s desc %s",
				    n->name,
				    n->eq->name,
				    n->u.l1.ifname,
				    n->u.l1.link,
				    l1type,
				    (n->u.l1.stat == NULL ? "-" : n->u.l1.stat),
				    (n->u.l1.ifdesc == NULL ? "-" : n->u.l1.ifdesc)
				) ;
		    if (n->u.l1.radio.ssid != NULL)
		    {
			struct radio *r ;
			struct ssid *s ;

			r = &(n->u.l1.radio) ;
			fprintf (fp, "radio ") ;
			switch (r->channel)
			{
			    case CHAN_DFS :
				fprintf (fp, " dfs") ;
				break ;
			    default :
				fprintf (fp, " %d", r->channel) ;
				break ;
			}
			fprintf (fp, " %d", r->power) ;

			for (s = r->ssid ; s != NULL ; s = s->next)
			{
			    char *m ;

			    switch (s->mode)
			    {
				case SSID_OPEN : m = "open" ; break ;
				case SSID_AUTH : m = "auth" ; break ;
				default :        m = "???" ;  break ;
			    }
			    fprintf (fp, " ssid %s %s", s->name, m) ;
			}
		    }
		    fprintf (fp, "\n") ;
		    break ;
		case NT_L2 :
		    fprintf (fp, "node %s type L2 eq %s vlan %d stat %s native %d\n",
				    n->name,
				    n->eq->name,
				    n->u.l2.vlan,
				    (n->u.l2.stat == NULL ? "-" : n->u.l2.stat),
				    n->u.l2.native
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
				    n->eq->name,
				    ipaddr
				) ;
		    break ;
		case NT_BRIDGE :
		    fprintf (fp, "node %s type bridge eq %s\n",
				    n->name,
				    n->eq->name
				) ;
		    break ;
		case NT_ROUTER :
		    fprintf (fp, "node %s type router eq %s instance %s\n",
				    n->name,
				    n->eq->name,
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
}

static void text_write_links (FILE *fp)
{
    struct node *n ;

    for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
	MK_CLEAR (n, MK_LINK) ;

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
	    if (MK_ISSELECTED (n1) && MK_ISSELECTED (n2))
	    {
		if (! (MK_ISSET (n1, MK_LINK) || MK_ISSET (n2, MK_LINK)))
		{
		    fprintf (fp, "link %s %s", n1->name, n2->name) ;
		    if (l->name != NULL)
			fprintf (fp, " name %s", l->name) ;
		    fprintf (fp, "\n") ;
		}
	    }
	}
	MK_SET (n, MK_LINK) ;
    }
}

static void text_write_rnet (FILE *fp)
{
    struct rnet *n ;
    struct route *r ;
    iptext_t addr, vrrpaddr, netaddr, gwaddr ;

    for (n = mobj_head (rnetmobj) ; n != NULL ; n = n->next)
    {
	if (MK_ISSELECTED (n->net))
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
}

static void text_write_vlans (FILE *fp)
{
    vlan_t v ;
    struct vlan *tab ;

    tab = mobj_data (vlanmobj) ;
    for (v = 0 ; v < MAXVLAN ; v++)
    {
	if (tab [v].name != NULL && MK_ISSELECTED (&tab [v]))
	{
	    iptext_t n ;
	    struct netlist *nl ;

	    fprintf (fp, "vlan %d desc %s voice %d", v,
					tab [v].name, tab [v].voice) ;
	    for (nl = tab [v].netlist ; nl != NULL ; nl = nl->next)
	    {
		ip_ntop (&nl->net->addr, n, 1) ;
		fprintf (fp, " net %s", n) ;
	    }
	    fprintf (fp, "\n") ;
	}
    }
}

static void text_write_lvlans (FILE *fp)
{
    vlan_t v ;
    struct vlan *tab ;
    struct lvlan *lv ;

    tab = mobj_data (vlanmobj) ;
    for (v = 0 ; v < MAXVLAN ; v++)
    {
	for (lv = tab [v].lvlan ; lv != NULL ; lv = lv->next)
	{
	    fprintf (fp, "lvlan %s %d desc %s declared %s incoming %s\n",
			    lv->eq->name, v,
			    (lv->name == NULL ? "-" : lv->name),
			    ((lv->mark & LVLAN_DECLARED) ? "yes" : "no"),
			    ((lv->mark & LVLAN_INCOMING) ? "yes" : "no")) ;
	}
    }
}

static void text_write_ssidprobes (FILE *fp)
{
    struct ssidprobe *sp ;

    for (sp = mobj_head (ssidprobemobj) ; sp != NULL ; sp = sp->next)
    {
	char *m ;

	switch (sp->mode)
	{
	    case SSIDPROBE_ASSOC : m = "assoc" ; break ;
	    case SSIDPROBE_AUTH  : m = "auth"  ; break ;
	    default              : m = "???"   ; break ;
	}

	fprintf (fp, "ssidprobe %s eq %s iface %s ssidname %s mode %s\n",
			    sp->name,
			    sp->eq->name,
			    sp->l1->name ,
			    sp->ssid->name,
			    m) ;
    }
}

void text_write (FILE *fp)
{
    text_write_eq (fp) ;
    text_write_nodes (fp) ;
    text_write_links (fp) ;
    text_write_rnet (fp) ;
    text_write_vlans (fp) ;
    text_write_lvlans (fp) ;
    text_write_ssidprobes (fp) ;
}
