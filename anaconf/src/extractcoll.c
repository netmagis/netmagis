/*
 * $Id: extractcoll.c,v 1.2 2007-01-10 16:50:00 pda Exp $
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

<id coll> <eq> <phys iface> <vlan id>

M123 crc-rc1 ge-1/2/3 58
M124 le7-rc1 ge-4/5/6 58
M125 crc-cc1 GigaMachin-4/5/6 58
M125 toto-ce1 GigaMachin-0/1 -
******************************************************************************/

/******************************************************************************
Output interfaces (L2 or L1 with restrictions) marked for this network
******************************************************************************/

void output_collect_L1 (FILE *fp, struct node *L1node, int mark)
{
    if (L1node->u.l1.stat)
    {
	/* <id collect> <eq> <iface> - */
	fprintf (fp, "%s %s %s -\n",
			L1node->u.l1.stat,
			L1node->eq->name,
			L1node->u.l1.ifname
		    ) ;
	L1node->mark = mark ;
    }
}

void output_collect_L2 (FILE *fp, struct node *L2node, int mark)
{
    struct node *L1node ;

    L1node = get_neighbour (L2node, NT_L1) ;
    if (L1node)
    {
	/*
	 * L2 is a collect point
	 */

	if (L2node->u.l2.stat != NULL)
	{
	    /* <id collect> <eq> <iface> <vlan> */
	    fprintf (fp, "%s %s %s %d\n",
			    L2node->u.l2.stat,
			    L1node->eq->name,
			    L1node->u.l1.ifname,
			    L2node->u.l2.vlan
			) ;
	    L2node->mark = mark ;
	}

	/*
	 * L1 is a collect point and a native Ethernet (not-802.1Q) interface
	 */

	if (L1node->u.l1.stat && L1node->u.l1.l1type == L1T_ETHER)
	    output_collect_L1 (fp, L1node, mark) ;
    }
}

/******************************************************************************
Main function
******************************************************************************/

void usage (char *progname)
{
    fprintf (stderr, "Usage : %s [-n cidr|-e eq]+\n", progname) ;
    exit (1) ;
}

MOBJ *mobjlist [NB_MOBJ] ;

int main (int argc, char *argv [])
{
    struct node *n ;
    int i ;

    /*
     * Analyzes arguments
     * Must be an even number.
     */

    if (argc == 1 || argc % 2 == 0)
	usage (argv [0]) ;

    /*
     * First loop only to build selection specifiers
     */

    sel_init () ;

    for (i = 1 ; i < argc ; i += 2)
    {
	if (strcmp (argv [i], "-n") == 0)
	{
	    if (! sel_network (argv [i+1]))
	    {
		fprintf (stderr, "%s: '%s' is not a valid cidr\n",
					argv [0], argv [i+1]) ;
		exit (1) ;
	    }
	}
	else if (strcmp (argv [i], "-e") == 0)
	{
	    if (! sel_regexp (argv [i+1]))
	    {
		fprintf (stderr, "%s: '%s' is not a valid regexp\n",
					argv [0], argv [i+1]) ;
		exit (1) ;
	    }
	}
	else usage (argv [0]) ;
    }

    /*
     * Read the graph and process selection
     */

    bin_read (stdin, mobjlist) ;

    for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
    {
	n->mark = 0 ;
	vlan_zero (n->vlanset) ;
    }

    sel_mark () ;

    /*
     * Output the final result
     */

    for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
    {
	if (n->nodetype == NT_L2 && (n->mark & MK_SELECTED))
	    output_collect_L2 (stdout, n, 0) ;
	if (n->nodetype == NT_L1 && (n->mark & MK_SELECTED))
	    output_collect_L1 (stdout, n, 0) ;
    }

    sel_end () ;

    exit (0) ;
}
