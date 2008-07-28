/*
 * $Id: dumpcoll.c,v 1.4 2008-07-28 14:10:53 pda Exp $
 */

#include <stdarg.h>
#include <assert.h>

#include "graph.h"

/******************************************************************************
Example of output format

traffic <id coll> <eq> <iface[.vlan]> <community>
wifi <eq> <iface> <community> <ssid> <mode>

traffic M123 crc-rc1 ge-1/2/3 toto
traffic M124 le7-rc1 ge-4/5/6.58 toto
wifi crc-ap1 Dot11Radio0 toto osiris open
wifi crc-ap1 Dot11Radio0 toto osiris-sec auth
******************************************************************************/

/******************************************************************************
Output interfaces (L2 or L1 with restrictions) marked for this network
******************************************************************************/

void output_L1 (FILE *fp, struct node *L1node, int dumpstat, int dumpwifi)
{
    struct ssid *ssid ;

    if (dumpstat && L1node->u.l1.stat)
    {
	/* traffic <id collect> <eq> <iface> <community> */
	fprintf (fp, "traffic %s %s %s %s\n",
			L1node->u.l1.stat,
			L1node->eq->name,
			L1node->u.l1.ifname,
			(L1node->eq->snmp == NULL) ? "-" : L1node->eq->snmp
		    ) ;
    }
    if (dumpwifi)
    {
	ssid = L1node->u.l1.radio.ssid ;
	while (ssid != NULL)
	{
	    char *m ;

	    switch (ssid->mode)
	    {
		case SSID_OPEN : m = "open" ; break ;
		case SSID_AUTH : m = "auth" ; break ;
		default :        m = "???" ;  break ;
	    }

	    /* wifi <eq> <iface> <community> <ssid> <mode> */
	    fprintf (fp, "wifi %s %s %s %s %s\n",
			    L1node->eq->name,
			    L1node->u.l1.ifname,
			    (L1node->eq->snmp == NULL) ? "-" : L1node->eq->snmp,
			    ssid->name,
			    m
			) ;
	    ssid = ssid->next ;
	}
    }
}

void output_L2 (FILE *fp, struct node *L2node, int dumpstat, int dumpwifi)
{
    struct node *L1node ;

    if (dumpstat && L2node->u.l2.stat != NULL)
    {
	L1node = get_neighbour (L2node, NT_L1) ;
	if (L1node)
	{
	    /* traffic <id collect> <eq> <iface>.<vlan> <community> */
	    fprintf (fp, "traffic %s %s %s.%d %s\n",
			    L2node->u.l2.stat,
			    L1node->eq->name,
			    L1node->u.l1.ifname, L2node->u.l2.vlan,
			    (L1node->eq->snmp == NULL) ? "-" : L1node->eq->snmp
			) ;
	}
    }
}

/******************************************************************************
Main function
******************************************************************************/

MOBJ *mobjlist [NB_MOBJ] ;

void usage (char *progname)
{
    fprintf (stderr, "Usage : %s [-s] [-w] [eq]\n", progname) ;
    exit (1) ;
}

int main (int argc, char *argv [])
{
    struct eq *eq ;
    char *eqname ;
    struct node *n ;
    int c ;
    char *prog ;
    int dumpstat, dumpwifi ;

    /*
     * Analyzes arguments
     */

    prog = argv [0] ;

    dumpstat = dumpwifi = 0 ;

    while ((c = getopt (argc, argv, "sw")) != -1)
    {
	switch (c)
	{
	    case 's' :
		dumpstat = 1 ;
		break ;
	    case 'w' :
		dumpwifi = 1 ;
		break ;
	    case '?' :
	    default :
		usage (prog) ;
		break ;
	}
    }

    argc -= optind ;
    argv += optind ;

    /*
     * Send traffic probes if no option is specified
     */

    if (dumpstat == 0 && dumpwifi == 0)
	dumpstat = 1 ;

    switch (argc)
    {
	case 0 :
	    eqname = NULL ;
	    break ;
	case 1 :
	    eqname = argv [0] ;
	    break ;
	default :
	    usage (prog) ;
	    break ;
    }

    /*
     * Read the graph
     */

    bin_read (stdin, mobjlist) ;

    /*
     * Lookup the equipment, if any
     */

    if (eqname != NULL)
    {
	eq = eq_lookup (eqname) ;
	if (eq == NULL)
	{
	    fprintf (stderr, "%s : equipement '%s' not found\n",
				prog, eqname) ;
	    exit (1) ;
	}
    }
    else eq = NULL ;

    /*
     * Traverse the graph
     */


    for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
    {
	if (eq == NULL || n->eq == eq)
	{
	    switch (n->nodetype)
	    {
		case NT_L1 :
		    output_L1 (stdout, n, dumpstat, dumpwifi) ;
		    break ;
		case NT_L2 :
		    output_L2 (stdout, n, dumpstat, dumpwifi) ;
		    break ;
		default :
		    break ;
	    }
	}
    }

    exit (0) ;
}
