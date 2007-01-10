/*
 * $Id: extracteq.c,v 1.3 2007-01-10 16:50:00 pda Exp $
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
	if (peer2->nodetype == NT_L2)
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

int main (int argc, char *argv [])
{
    struct node *n ;
    char *eqname ;
    struct eq *eq ;

    switch (argc)
    {
	case 2 :
	    eqname = argv [1] ;
	    break ;
	default :
	    fprintf (stderr, "Usage : %s eq\n", argv [0]) ;
	    exit (1) ;
	    break ;
    }

    /*
     * Read the graph
     */

    bin_read (stdin, mobjlist) ;

    /*
     * Search for arguments
     */


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

    output_eq (stdout, eq) ;

    for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
	if (n->eq == eq && n->nodetype == NT_L1)
	    output_iface (stdout, n) ;

    exit (0) ;
}
