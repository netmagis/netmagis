/*
 * $Id: extractl1.c,v 1.2 2007-01-10 16:50:00 pda Exp $
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
	fprintf (fp, "%s", eq->name) ;
	for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
	{
	    if (n->eq == eq && n->nodetype == NT_L1 && n->mark == 0)
		fprintf (fp, " %s", n->u.l1.ifname) ;
	}
	fprintf (fp, "\n") ;
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
	if (n->nodetype == NT_L1 && n->mark == 0)
	{
	    peer = get_neighbour (n, NT_L1) ;
	    if (termif)
	    {
		/* we don't want terminal interfaces */
		if (peer == NULL)
		    n->mark = 1 ;
	    }
	    else
	    {
		/* we don't want backbone interfaces */
		if (peer != NULL)
		{
		    n->mark = 1 ;
		    peer->mark = 1 ;		/* optimization */
		}
	    }
	}
    }
}

/******************************************************************************
Main function
******************************************************************************/

MOBJ *mobjlist [NB_MOBJ] ;

int main (int argc, char *argv [])
{
    int termif, backif ;
    struct node *n ;

    termif = backif = 0 ;
    switch (argc)
    {
	case 1 :
	    termif = 1 ;
	    backif = 1 ;
	    break ;
	case 2 :
	    if (strcmp (argv [1], "-t") == 0)
		termif = 1 ;
	    else if (strcmp (argv [1], "-b") == 0)
		backif = 1 ;
	    else
	    {
		fprintf (stderr, "Usage : %s [-b|-t]\n", argv [0]) ;
		exit (1) ;
	    }
	    break ;
	default :
	    fprintf (stderr, "Usage : %s [-b|-t]\n", argv [0]) ;
	    exit (1) ;
	    break ;
    }

    /*
     * Read the graph
     */

    /* text_read (stdin) ; */
    bin_read (stdin, mobjlist) ;

    for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
	n->mark = 0 ;

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

    exit (0) ;
}
