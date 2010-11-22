/*
 */

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

#define	MK_PRINTED	(MK_LAST << 1)

int match_iface (struct node *nl2, char *ifname) {
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
    {
	vlan_zero (n->vlanset) ;
	MK_CLEAR (n, MK_L2TRANSPORT) ;
    }

    for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
    {
	if (n->nodetype == NT_L2
		&& MK_ISSELECTED (n)
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
    struct eq *eq ;

    for (eq = mobj_head (eqmobj) ; eq != NULL ; eq = eq->next)
	MK_CLEAR (eq, MK_PRINTED) ;

    for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
    {
	if (n->nodetype == NT_L2
			&& MK_ISSELECTED (n)
			&& MK_ISSET (n, MK_L2TRANSPORT))
	{
	    eq = n->eq ;
	    if (! MK_ISSET (eq, MK_PRINTED))
	    {
		fprintf (fp, "eq %s %s/%s\n", eq->name, eq->type, eq->model) ;
		MK_SET (eq, MK_PRINTED) ;
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
	if (n->nodetype == NT_L2
			&& MK_ISSELECTED (n)
			&& MK_ISSET (n, MK_L2TRANSPORT))
	{
	    struct node *l1node ;

	    l1node = get_neighbour (n, NT_L1) ;
	    if (l1node != NULL)
	    {
		struct linklist *ll ;

		for (ll = l1node->linklist ; ll != NULL ; ll = ll->next)
		{
		    struct link *l ;
		    struct node *n1, *n2 ;

		    l = ll->link ;
		    n1 = l->node [0] ;
		    n2 = l->node [1] ;
		    if (n1->nodetype == NT_L1 && n2->nodetype == NT_L1
				&& MK_ISSET (n1, MK_L2TRANSPORT)
				&& MK_ISSET (n2, MK_L2TRANSPORT)
				&& MK_ISSELECTED (n1)
				&& MK_ISSELECTED (n2)
				&& MK_ISSET (n1->eq, MK_PRINTED)
				&& MK_ISSET (n2->eq, MK_PRINTED)
				)
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
		MK_CLEAR (l1node, MK_L2TRANSPORT) ;	/* link has been processed */
	    }
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

void usage (char *progname)
{
    fprintf (stderr, "Usage : %s [-a|-n cidr|-e regexp|-E regexp|-t|-m]* [eq [iface]] vlanid\n", progname) ;
    exit (1) ;
}

int main (int argc, char *argv [])
{
    struct node *n ;
    struct eq *eq ;
    char *eqname ;
    char *ifname ;
    char *vlanid ; vlan_t vlan ;
    vlanset_t vs ;
    int c, err ;
    char *prog, *errstr ;
    struct vlan *tabvlan ;

    prog = argv [0] ;
    err = 0 ;

    sel_init () ;

    while ((c = getopt (argc, argv, "an:e:E:tm")) != -1)
    {
	switch (c)
	{
	    case 'a' :
	    case 'n' :
	    case 'e' :
	    case 'E' :
	    case 't' :
	    case 'm' :
		if ((errstr = sel_register (c, optarg)) != NULL)
		{
		    fprintf (stderr, "%s: %s\n", prog, errstr) ;
		    err = 1 ;
		}
		break ;
	    case '?' :
	    default :
		usage (prog) ;
	}
    }

    if (err)
	exit (1) ;

    argc -= optind ;
    argv += optind ;

    switch (argc)
    {
	case 1 :
	    eqname = NULL ;
	    ifname = NULL ;
	    vlanid = argv [0] ;
	    break ;
	case 2 :
	    eqname = argv [0] ;
	    ifname = NULL ;
	    vlanid = argv [1] ;
	    break ;
	case 3 :
	    eqname = argv [0] ;
	    ifname = argv [1] ;
	    vlanid = argv [2] ;
	    break ;
	default :
	    usage (prog) ;
    }

    /*
     * Read the graph
     */

    bin_read (stdin, mobjlist) ;
    sel_mark () ;

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
	    fprintf (stderr, "%s: equipement '%s' not found\n", prog, eqname) ;
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
		fprintf (stderr, "%s: interface '%s' not found on '%s'\n",
					prog, ifname, eqname) ;
		exit (1) ;
	    }
	    ifname = n->u.l1.ifname ;
	}
    }

    /*
     * Pass 1 : walk the graph through each vlan given on the command line
     * and mark all visited nodes for these vlans
     */

    tabvlan = mobj_data (vlanmobj) ;
    vlan = atoi (vlanid) ;

    if (! walkl2 (vlan, eq, ifname))
    {
	fprintf (stderr, "%s: vlan '%d' not found\n", prog, vlan) ;
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

    sel_end () ;
    exit (0) ;
}
