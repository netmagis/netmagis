/*
 * $Id: dumpcoll.c,v 1.1.1.1 2007-01-05 15:12:00 pda Exp $
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

<id coll> <eq> <iface[.vlan]> <community>

M123 crc-rc1 ge-1/2/3 toto
M124 le7-rc1 ge-4/5/6.58 toto
******************************************************************************/

/******************************************************************************
Output interfaces (L2 or L1 with restrictions) marked for this network
******************************************************************************/

char *community (char *eqname)
{
    struct eq *eq ;
    char *r ;

    r = "-" ;
    for (eq = mobj_head (eqmobj) ; eq != NULL ; eq = eq->next)
    {
	if (eq->name == eqname)
	{
	    if (eq->snmp != NULL)
		r = eq->snmp ;
	    break ;
	}
    }
    return r ;
}

void output_L1 (FILE *fp, struct node *L1node)
{
    if (L1node->u.l1.stat)
    {
	/* <id collect> <eq> <iface> <community> */
	fprintf (fp, "%s %s %s %s\n",
			L1node->u.l1.stat,
			L1node->eq,
			L1node->u.l1.ifname,
			community (L1node->eq)
		    ) ;
    }
}

void output_L2 (FILE *fp, struct node *L2node)
{
    struct node *L1node ;

    if (L2node->u.l2.stat != NULL)
    {
	L1node = get_neighbour (L2node, NT_L1) ;
	if (L1node)
	{
	    /* <id collect> <eq> <iface>.<vlan> <community> */
	    fprintf (fp, "%s %s %s.%d %s\n",
			    L2node->u.l2.stat,
			    L1node->eq,
			    L1node->u.l1.ifname, L2node->u.l2.vlan,
			    community (L1node->eq)
			) ;
	}
    }
}

/******************************************************************************
Main function
******************************************************************************/

MOBJ *mobjlist [NB_MOBJ] ;

int main (int argc, char *argv [])
{
    char *eqname ;
    struct node *n ;

    /*
     * Analyzes arguments
     */

    switch (argc)
    {
	case 1 :
	    eqname = NULL ;
	    break ;
	case 2 :
	    eqname = argv [1] ;
	    break ;
	default :
	    fprintf (stderr, "Usage : %s [eq]\n", argv [0]) ;
	    exit (1) ;
	    break ;
    }

    /*
     * Read the graph
     */

    bin_read (stdin, mobjlist) ;

    /*
     * Traverse the graph
     */

    for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
    {
	if (eqname == NULL || strcmp (n->eq, eqname) == 0)
	{
	    switch (n->nodetype)
	    {
		case NT_L1 :
		    output_L1 (stdout, n) ;
		    break ;
		case NT_L2 :
		    output_L2 (stdout, n) ;
		    break ;
		default :
		    break ;
	    }
	}
    }

    exit (0) ;
}
