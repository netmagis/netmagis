/*
 * $Id: extractcoll.c,v 1.1.1.1 2007-01-05 15:12:00 pda Exp $
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <stdarg.h>
#include <assert.h>

#include <regex.h>

#define	RE_MODE	(REG_EXTENDED | REG_ICASE)

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
Marks all nodes/links (except L1 nodes) reached by this vlan
******************************************************************************/

int walkl3 (struct node *L3node)
{
    struct node *L2node ;
    int found ;

    found = 0 ;
    L2node = get_neighbour (L3node, NT_L2) ;
    if (L2node)
    {
	/* mark all nodes, except L1 ones */
	transport_vlan_on_L2 (L2node, L2node->u.l2.vlan) ;
	found = 1 ;
    }
    return found ;
}


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
			L1node->eq,
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
			    L1node->eq,
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
Output all collect points
******************************************************************************/

void output_all_collect (FILE *fp)
{
    struct node *n ;

    for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
	n->mark = 0 ;

    for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
	if (n->nodetype == NT_L2 && n->u.l2.stat != NULL)
	    output_collect_L2 (fp, n, 1) ;

    for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
	if (n->nodetype == NT_L1 && n->u.l1.stat != NULL && ! n->mark)
	    output_collect_L1 (fp, n, 1) ;
}


void mark_collect_L3 (ip_t *network)
{
    struct node *n ;

    /*
     * For each IP address found in the given CIDR,
     * mark all L2 nodes reached from this IP address.
     */

    for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
	if (n->nodetype == NT_L3 && ip_match (&n->u.l3.addr, network, 0))
	    (void) walkl3 (n) ;

}

void mark_collect_eq (char *regexp)
{
    struct node *n ;
    regex_t recomp ;		/* compiled regexp */

    (void) regcomp (&recomp, regexp, RE_MODE) ;

    /*
     * Mark all L1 or L2 nodes which are on these equipements
     */

    for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
    {
	if ((n->nodetype == NT_L1 && n->u.l1.stat != NULL)
	    || (n->nodetype == NT_L2 && n->u.l2.stat != NULL))
	{
	    if (regexec (&recomp, n->eq, 0, NULL, 0) == 0)
	    {
		n->mark = 1 ;
	    }
	}
    }

    regfree (&recomp) ;
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
    ip_t network ;
    int i ;

    /*
     * Analyzes arguments
     * Must be an even number.
     */

    if (argc == 1 || argc % 2 == 0)
	usage (argv [0]) ;

    /*
     * First loop only to analyze and validate arguments
     */

    for (i = 1 ; i < argc ; i += 2)
    {
	if (strcmp (argv [i], "-n") == 0)
	{
	    if (! ip_pton (argv [i+1], &network))
	    {
		fprintf (stderr, "%s: '%s' is not a valid cidr\n",
					argv [0], argv [i+1]) ;
		exit (1) ;
	    }
	}
	else if (strcmp (argv [i], "-e") == 0)
	{
	    regex_t rc ;

	    if (regcomp (&rc, argv [i+1], RE_MODE) != 0)
	    {
		fprintf (stderr, "%s: '%s' is not a valid regexp\n",
					argv [0], argv [i+1]) ;
		exit (1) ;
	    }
	    else regfree (&rc) ;
	}
	else usage (argv [0]) ;
    }

    /*
     * Read the graph
     */

    bin_read (stdin, mobjlist) ;

    for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
    {
	n->mark = 0 ;
	vlan_zero (n->vlanset) ;
    }


    /*
     * Second loop through the arguments to process only IP addresses
     */

    for (i = 1 ; i < argc ; i += 2)
    {
	if (strcmp (argv [i], "-n") == 0)
	{
	    (void) ip_pton (argv [i+1], &network) ;
	    mark_collect_L3 (&network) ;
	}
    }

    /*
     * Third loop through the arguments to process only regexp
     */

    for (i = 1 ; i < argc ; i += 2)
    {
	if (strcmp (argv [i], "-e") == 0)
	{
	    mark_collect_eq (argv [i+1]) ;
	}
    }

    /*
     * Output the final result
     */

    for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
    {
	if (n->nodetype == NT_L2 && n->mark)
	    output_collect_L2 (stdout, n, 0) ;
	if (n->nodetype == NT_L1 && n->mark)
	    output_collect_L1 (stdout, n, 0) ;
    }

    exit (0) ;
}
