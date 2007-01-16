/*
 * $Id: extracteq.c,v 1.7 2007-01-16 09:51:43 pda Exp $
 */

#include "graph.h"

/******************************************************************************
Example of output format


eq crc-cc1 cisco/WS-C4506
iface GigaEthernet0/1 <M123 ou ->  <Ether ou Trunk> {X / L33 crc-rc1 ge-0/0/0}
    {0 {} <ip> ...} {7 <vlan-desc-en-hexa> 130.79.....} ...
<all ifaces>
******************************************************************************/

#define	LB	'{'
#define	RB	'}'

/******************************************************************************
Output routines
******************************************************************************/

void output_eq (FILE *fp, struct eq *eq)
{
    fprintf (fp, "eq %s %s %s\n", eq->name, eq->type, eq->model) ;
}

void output_iface (FILE *fp, struct node *n)
{
    char *ifname ;
    char *stat ;
    char *type ;
    struct node *peer ;
    struct linklist *ll1, *ll2, *ll3 ;

    ifname = n->u.l1.ifname ;
    stat = (n->u.l1.stat == NULL) ? "-" : n->u.l1.stat ;
    type = (n->u.l1.l1type == L1T_TRUNK) ? "Trunk" : "Ether" ;

    fprintf (fp, "iface %s %s %s", ifname, stat, type) ;

    peer = get_neighbour (n, NT_L1) ;
    if (peer == NULL)
	fprintf (fp, " {X}") ;
    else
    {
	for (ll1 = n->linklist ; ll1 != NULL ; ll1 = ll1->next)
	    if (getlinkpeer (ll1->link, n) == peer)
		break ;
	if (ll1 != NULL)
	    fprintf (fp, " {%s %s %s}",
			    ll1->link->name,
			    peer->eq->name,
			    peer->u.l1.ifname) ;
    }

    /*
     * Search all L2 interfaces
     */

    for (ll2 = n->linklist ; ll2 != NULL ; ll2 = ll2->next)
    {
	struct node *peer2 ;

	peer2 = getlinkpeer (ll2->link, n) ;
	if (peer2->nodetype == NT_L2 && MK_ISSELECTED (peer2))
	{
	    vlan_t vlanid ;
	    char *desc ;
	    int first ;

	    vlanid = peer2->u.l2.vlan ;
	    stat = (peer2->u.l2.stat == NULL) ? "-" : peer2->u.l2.stat ;
	    desc = ((struct vlan *) mobj_data (vlanmobj)) [vlanid].name ;
	    if (desc == NULL)
		desc = "-" ;
	    fprintf (fp, " %c%d %s %s", LB, vlanid, desc, stat) ;

	    /*
	     * Search all L3 interfaces
	     */

	    first = 1 ;
	    for (ll3 = peer2->linklist ; ll3 != NULL ; ll3 = ll3->next)
	    {
		struct node *peer3 ;

		peer3 = getlinkpeer (ll3->link, peer2) ;
		if (peer3->nodetype == NT_L3)
		{
		    iptext_t a ;

		    if (ip_ntop (&peer3->u.l3.addr, a, 1))
		    {
			if (first)
			    fprintf (fp, " %c", LB) ;
			else
			    fprintf (fp, " ") ;
			fprintf (fp, "%s", a) ;
			first = 0 ;
		    }
		}
	    }
	    if (first == 0)
		fprintf (fp, "%c", RB) ;

	    fprintf (fp, "%c", RB) ;
	}
    }

    fprintf (fp, "\n") ;
}

/******************************************************************************
Main function
******************************************************************************/

MOBJ *mobjlist [NB_MOBJ] ;

void usage (char *progname)
{
    fprintf (stderr, "Usage : %s [-n cidr|-e regexp]* eq\n", progname) ;
    exit (1) ;
}

int main (int argc, char *argv [])
{
    struct node *n ;
    char *eqname, *prog ;
    struct eq *eq ;
    int c, err ;
    int selected ;

    prog = argv [0] ;
    err = 0 ;

    sel_init () ;

    while ((c = getopt (argc, argv, "n:e:")) != -1) {
	switch (c)
	{
	    case 'n' :
		if (! sel_network (optarg))
		{
		    fprintf (stderr, "%s: '%s' is not a valid cidr\n", prog, optarg) ;
		    err = 1 ;
		}
		break ;
	    case 'e' :
		if (! sel_regexp (optarg))
		{
		    fprintf (stderr, "%s: '%s' is not a valid regexp\n", prog, optarg) ;
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

    if (argc != 1)
	usage (prog) ;

    eqname = argv [0] ;

    /*
     * Read the graph
     */

    bin_read (stdin, mobjlist) ;
    sel_mark () ;

    /*
     * Search selected equipement, or a selected node inside this equipement
     */

    eq = eq_lookup (eqname) ;
    selected = 0 ;
    if (eq != NULL)
    {
	if (MK_ISSELECTED (eq))
	    selected = 1 ;
	else
	{
	    for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
	    {
		if (n->eq == eq && MK_ISSELECTED (n))
		{
		    selected = 1 ;
		    break ;
		}
	    }
	}
    }

    if (! selected)
    {
	fprintf (stderr, "%s: equipement '%s' not found\n", prog, eqname) ;
	exit (1) ;
    }

    /*
     * Output the final result
     */

    output_eq (stdout, eq) ;

    for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
	if (n->eq == eq && n->nodetype == NT_L1 && MK_ISSELECTED (n))
	    output_iface (stdout, n) ;

    sel_end () ;
    exit (0) ;
}
