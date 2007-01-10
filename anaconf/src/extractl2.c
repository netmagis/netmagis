/*
 * $Id: extractl2.c,v 1.4 2007-01-10 16:50:00 pda Exp $
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <stdarg.h>
#include <assert.h>

#include "graph.h"

/******************************************************************************
Example of output format


vlans 2 4 ...
eq crc-cc1 cisco/WS-C4506
eq atrium-ce1 cisco/WS-C3750G-24TS
eq crc-rc1 juniper/M20
... (all equipements first)

link L12 crc-cc1 GigabitEthernet4/5 crc-rc1 ge-0/0/0
... (all links)
******************************************************************************/

int match_iface (struct node *nl2, char *ifname)
{
    int r ;

    if (ifname != NULL)
    {
	struct linklist *ll ;

	r = 0 ;
	for (ll = nl2->linklist ; ll != NULL ; ll = ll->next)
	{
	    struct link *l ;
	    struct node *other ;

	    l = ll->link ;
	    other = getlinkpeer (l, nl2) ;
	    if (other->nodetype == NT_L1 && other->u.l1.ifname == ifname)
	    {
		r = 1 ;
		break ;
	    }
	}
    }
    else r = 1 ;

    return r ;
}

/******************************************************************************
Marks all nodes/links (except L1 nodes) reached by this vlan
******************************************************************************/

int walkl2 (vlan_t vlan, struct eq *eq, char *ifname)
{
    struct node *n ;
    int vlan_found ;

    vlan_found = 0 ;
    for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
	vlan_zero (n->vlanset) ;

    for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
    {
	if (n->nodetype == NT_L2
		&& (eq == NULL || n->eq == eq)
		&& match_iface (n, ifname)
		&& n->u.l2.vlan == vlan
		&& ! vlan_isset (n->vlanset, vlan) )
	{
	    transport_vlan_on_L2 (n, n->u.l2.vlan) ;
	    vlan_found = 1 ;
	}
    }
    return vlan_found ;
}


/******************************************************************************
Output equipements
******************************************************************************/

void output_eq (FILE *fp)
{
    struct node *n ;

    for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
    {
	if (n->nodetype == NT_L1 && (n->mark & MK_L2TRANSPORT))
	{
	    if (! n->eq->mark)
	    {
		n->eq->mark = 1 ;
		fprintf (fp, "eq %s %s/%s\n",
			    n->eq->name, n->eq->type, n->eq->model) ;
	    }
	}
    }
}

/******************************************************************************
Output links
******************************************************************************/

/*
 * Output marked links
 */

void output_links (FILE *fp)
{
    struct node *n ;

    for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
    {
	if (n->nodetype == NT_L1 && (n->mark & MK_L2TRANSPORT))
	{
	    struct linklist *ll ;

	    for (ll = n->linklist ; ll != NULL ; ll = ll->next)
	    {
		struct link *l ;
		struct node *n1, *n2 ;

		l = ll->link ;
		n1 = l->node [0] ;
		n2 = l->node [1] ;
		if ((n1->mark & MK_L2TRANSPORT) && (n2->mark & MK_L2TRANSPORT)
			&& n1->nodetype == NT_L1 && n2->nodetype == NT_L1)
		{
		    if (l->name == NULL)
			inconsistency ("Link between %s and %s without name",
						n1->name, n2->name) ;
		    fprintf (fp, "link %s %s %s %s %s\n",
					l->name,
					n1->eq->name, n1->u.l1.ifname,
					n2->eq->name, n2->u.l1.ifname
				    ) ;
		}
	    }
	    n->mark = 0 ;		/* link has been processed */
	}
    }
}

/******************************************************************************
Output traversed vlans
******************************************************************************/

/*
 * Output marked links
 */

void output_vlans (FILE *fp, vlanset_t vs)
{
    fprintf (fp, "vlans") ;
    print_vlanlist (fp, vs, 0) ;
    fprintf (fp, "\n") ;
}

/******************************************************************************
Main function
******************************************************************************/

MOBJ *mobjlist [NB_MOBJ] ;

int main (int argc, char *argv [])
{
    struct node *n ;
    struct eq *eq ;
    char *eqname ;
    char *ifname ;
    char *vlanid ; vlan_t vlan ;
    vlanset_t vs ;

    switch (argc)
    {
	case 2 :
	    eqname = NULL ;
	    ifname = NULL ;
	    vlanid = argv [1] ;
	    break ;
	case 3 :
	    eqname = argv [1] ;
	    ifname = NULL ;
	    vlanid = argv [2] ;
	    break ;
	case 4 :
	    eqname = argv [1] ;
	    ifname = argv [2] ;
	    vlanid = argv [3] ;
	    break ;
	default :
	    fprintf (stderr, "Usage : %s [eq [iface]] vlanid\n", argv [0]) ;
	    exit (1) ;
	    break ;
    }

    /*
     * Read the graph
     */

    /* text_read (stdin) ; */
    bin_read (stdin, mobjlist) ;

    /*
     * Search for arguments
     */

    eq = NULL ;
    if (eqname != NULL)
    {
	/*
	 * Chercher l'équipement, et remplacer le nom cherché par
	 * celui qui est dans le noeud, afin que les recherches
	 * soient plus efficaces (simple comparaison de pointeurs).
	 */

	eq = eq_lookup (eqname) ;
	if (eq == NULL)
	{
	    fprintf (stderr, "equipement '%s' not found\n", eqname) ;
	    exit (1) ;
	}

	if (ifname != NULL)
	{
	    for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
		if (n->nodetype == NT_L1
			&& n->eq == eq
			&& strcmp (n->u.l1.ifname, ifname) == 0)
		    break ;
	    if (n == NULL)
	    {
		fprintf (stderr, "interface '%s' not found on '%s'\n", ifname, eqname) ;
		exit (1) ;
	    }
	    ifname = n->u.l1.ifname ;
	}
    }

    /*
     * Pass 1 : walk the graph through each vlan given on the command line
     * and mark all visited nodes for these vlans
     */

    for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
	n->mark = 0 ;

    vlan = atoi (vlanid) ;

    if (! walkl2 (vlan, eq, ifname))
    {
	fprintf (stderr, "%s: vlan not found\n", argv [0]) ;
	exit (1) ;
    }

    /*
     * Pass 2 : print traversed vlans (except 0 and 1)
     */

    traversed_vlans (vs) ;
    output_vlans (stdout, vs) ;

    /*
     * Pass 3 : output all equipements
     */

    output_eq (stdout) ;

    /*
     * Pass 4 : visit all L1 nodes marked, check marked remote L1 nodes
     * and output links
     */

    output_links (stdout) ;

    exit (0) ;
}
