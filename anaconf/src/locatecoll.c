/*
 * $Id: locatecoll.c,v 1.1.1.1 2007-01-05 15:12:00 pda Exp $
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <stdarg.h>
#include <assert.h>

#include "graph.h"

/******************************************************************************
Locate a "collect point", i.e. returns the equipement or/and an IP address

Example of output format (only one line)

<eq> [ <ipv4/ipv6)> ]
******************************************************************************/

struct node *locate_coll (char *coll)
{
    struct node *n ;

    for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
    {
	if ((n->nodetype == NT_L1 &&
		n->u.l1.stat != NULL && strcmp (n->u.l1.stat, coll) == 0) ||
	    (n->nodetype == NT_L2 &&
		n->u.l2.stat != NULL && strcmp (n->u.l2.stat, coll) == 0))
	{
	    break ;
	}
    }
    return n ;
}

/******************************************************************************
Locate an L3 node on this vlan
******************************************************************************/

struct node *search_L3 (struct node *n)
{
    struct node *m ;

    /*
     * Pass 1 : reset all marks
     */

    for (m = mobj_head (nodemobj) ; m != NULL ; m = m->next)
    {
	m->mark = 0 ;
	vlan_zero (m->vlanset) ;
    }

    /*
     * Pass 2 : transport Vlan in the graph, if needed
     */

    switch (n->nodetype)
    {
	case NT_L1 :
	    switch (n->u.l1.l1type)
	    {
		case L1T_TRUNK :
		    break ;
		case L1T_ETHER :
		    m = get_neighbour (n, NT_L2) ;
		    if (m != NULL)
			transport_vlan_on_L2 (m, m->u.l2.vlan) ;
		    break ;
		default :
		    break ;
	    }
	    break ;
	case NT_L2 :
	    transport_vlan_on_L2 (n, n->u.l2.vlan) ;
	    break ;
	default :
	    break ;
    }

    /*
     * Pass 3 : look for any marked L3 interface
     */

    for (m = mobj_head (nodemobj) ; m != NULL ; m = m->next)
	if (m->nodetype == NT_L3 && m->mark)
	    break ;

    return m ;
}

/******************************************************************************
Main function
******************************************************************************/

MOBJ *mobjlist [NB_MOBJ] ;

int main (int argc, char *argv [])
{
    char *coll ;
    struct node *n ;

    /*
     * Analyzes arguments
     */

    switch (argc)
    {
	case 2 :
	    coll = argv [1] ;
	    break ;
	default :
	    fprintf (stderr, "Usage : %s collect-id\n", argv [0]) ;
	    exit (1) ;
    }

    /*
     * Read the graph
     */

    bin_read (stdin, mobjlist) ;

    /*
     * Search the collect-id
     */

    n = locate_coll (coll) ;

    if (n != NULL)
    {
	struct node *m ;

	m = search_L3 (n) ;
	printf ("%s", n->eq) ;
	if (m != NULL)
	{
	    iptext_t ip ;

	    /* assert (m->type == NT_L3) */
	    if (ip_ntop (&m->u.l3.addr, ip, 0))
		printf (" %s", ip) ;
	}
	printf ("\n") ;
    }

    exit (0) ;
}
