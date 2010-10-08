/*
 * $Id$
 */

#include "graph.h"

#define	MK_IFACE	(MK_LAST << 1)

/******************************************************************************
Example of output format

Output a list of known interfaces for each equipment under the form
    option -t : output list of terminal interfaces
    option -b : output list of backbone interfaces
    without option : output list of all interfaces

atrium-ce1 GigabitEthernet1/0 GigabitEthernet1/1 ...
xxx-ce1 ...

******************************************************************************/

#define	TERMINAL	1

/******************************************************************************
Output equipements and interfaces
******************************************************************************/

void output_eq_ifaces (FILE *fp)
{
    struct eq *eq ;
    struct node *n ;

    for (eq = mobj_head (eqmobj) ; eq != NULL ; eq = eq->next)
    {
	if (MK_ISSELECTED (eq))
	{
	    fprintf (fp, "%s", eq->name) ;
	    for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
	    {
		if (n->eq == eq
			&& n->nodetype == NT_L1
			&& ! MK_ISSET (n, MK_IFACE))
		    fprintf (fp, " %s", n->u.l1.ifname) ;
	    }
	    fprintf (fp, "\n") ;
	}
    }
}

/******************************************************************************
Mark interface
******************************************************************************/

void mark_ifaces (int termif)
{
    struct node *n, *peer ;

    for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
    {
	if (n->nodetype == NT_L1 && ! MK_ISSET (n, MK_IFACE))
	{
	    peer = get_neighbour (n, NT_L1) ;
	    if (termif)
	    {
		/* we don't want terminal interfaces */
		if (peer == NULL)
		    MK_SET (n, MK_IFACE) ;
	    }
	    else
	    {
		/* we don't want backbone interfaces */
		if (peer != NULL)
		{
		    MK_SET (n, MK_IFACE) ;
		    MK_SET (peer, MK_IFACE) ;		/* optimization */
		}
	    }
	}
    }
}

/******************************************************************************
Main function
******************************************************************************/

MOBJ *mobjlist [NB_MOBJ] ;

void usage (char *progname)
{
    fprintf (stderr, "Usage : %s [-n cidr|-e regexp]* [-b|-t]\n", progname) ;
    exit (1) ;
}


int main (int argc, char *argv [])
{
    int termif, backif ;
    int c, err ;
    char *prog ;


    prog = argv [0] ;
    err = 0 ;
    termif = backif = 0 ;

    sel_init () ;

    while ((c = getopt (argc, argv, "n:e:tb")) != -1) {
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
	    case 't' :
		termif = 1 ;
		break ;
	    case 'b' :
		backif = 1 ;
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

    if (argc != 0)
	usage (prog) ;

    if (termif == 0 && backif == 0)
    {
	termif = 1 ;
	backif = 1 ;
    }

    /*
     * Read the graph and select a subgraph
     */

    bin_read (stdin, mobjlist) ;
    sel_mark () ;

    /*
     * Grep interface type
     */

    if (! termif)			/* we don't want terminal interfaces */
	mark_ifaces (TERMINAL) ;

    if (! backif)			/* we don't want backbone interfaces */
	mark_ifaces (! TERMINAL) ;

    /*
     * Output graph
     */

    output_eq_ifaces (stdout) ;

    sel_end () ;
    exit (0) ;
}
