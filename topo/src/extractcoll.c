/*
 */

#include "graph.h"

/******************************************************************************
Example of output format

trafic      <id coll> <eq> <community> <phys iface> <vlan id|->
nbassocwifi <id coll> <eq> <community> <phys iface> <ssid>
nbauthwifi  <id coll> <eq> <community> <phys iface> <ssid>


trafic M123 crc-rc1 commsnmp ge-1/2/3 58
trafic M125 crc-cc1 commsnmp GigaMachin-4/5/6 58
trafic M125 toto-ce1 commsnmp GigaMachin-0/1 -
nbassocwifi Mtruc.asso titi-ap1 commsnmp Dot11Radio0 osiris
nbauthwifi  Mtruc.auth titi-ap1 commsnmp Dot11Radio0 osiris
******************************************************************************/

/******************************************************************************
Output wifi probes marked for this network
******************************************************************************/

void output_ssidprobe (FILE *fp, struct ssidprobe *sp)
{
    char *t ;

    switch (sp->mode)
    {
	case SSIDPROBE_ASSOC : t = "nbassocwifi" ; break ;
	case SSIDPROBE_AUTH  : t = "nbauthwifi"  ; break ;
	default : t = "???" ; break ;
    }

    /* nbassocwifi <id coll> <eq> <community> <phys iface> <ssid> */
    fprintf (fp, "%s %s %s %s %s %s\n",
		    t,
		    sp->name,
		    sp->eq->name,
		    sp->eq->snmp,
		    sp->l1->u.l1.ifname,
		    sp->ssid->name
		) ;
}

/******************************************************************************
Output interfaces (L2 or L1 with restrictions) marked for this network
******************************************************************************/

void output_collect_L1 (FILE *fp, struct node *L1node)
{
    if (L1node->u.l1.stat)
    {
	/* trafic <id collect> <eq> <comm> <phys iface> - */
	fprintf (fp, "trafic %s %s %s %s -\n",
			L1node->u.l1.stat,
			L1node->eq->name,
			L1node->eq->snmp,
			L1node->u.l1.ifname
		    ) ;
	L1node->mark = 0 ;
    }
}

void output_collect_L2 (FILE *fp, struct node *L2node)
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
	    /* trafic <id collect> <eq> <comm> <phys iface> <vlan id> */
	    fprintf (fp, "trafic %s %s %s %s %d\n",
			    L2node->u.l2.stat,
			    L1node->eq->name,
			    L1node->eq->snmp,
			    L1node->u.l1.ifname,
			    L2node->u.l2.vlan
			) ;
	    L2node->mark = 0 ;
	}

	/*
	 * L1 is a collect point and a native Ethernet (not-802.1Q) interface
	 */

	if (L1node->u.l1.stat && L1node->u.l1.l1type == L1T_ETHER)
	    output_collect_L1 (fp, L1node) ;
    }
}

/******************************************************************************
Main function
******************************************************************************/

void usage (char *progname)
{
    fprintf (stderr, "Usage : %s [-a|-n cidr|-e regexp|-E regexp|-t|-m]* [-s] [-w] [eq]\n", progname) ;
    exit (1) ;
}

MOBJ *mobjlist [NB_MOBJ] ;

int main (int argc, char *argv [])
{
    char *prog, *errstr ;
    int c, err ;
    char *eqname ;
    struct eq *eq ;
    struct node *n ;
    int dumpstat, dumpwifi ;

    /*
     * Analyzes arguments
     */

    prog = argv [0] ;
    err = 0 ;
    dumpstat = 0 ;
    dumpwifi = 0 ;

    sel_init () ;

    while ((c = getopt (argc, argv, "an:e:E:tmsw")) != -1)
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
	    case 's' :
		dumpstat = 1 ;
		break ;
	    case 'w' :
		dumpwifi = 1 ;
		break ;
	    case '?' :
	    default :
		usage (prog) ;
	}
    }

    if (err)
	exit (1) ;

    if (dumpstat == 0 && dumpwifi == 0)
    {
	dumpstat = 1 ;
	dumpwifi = 1 ;
    }

    argc -= optind ;
    argv += optind ;

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
     * Lookup the equipment, if any
     */

    if (eqname != NULL)
    {
	eq = eq_lookup (eqname) ;
	if (eq == NULL)
	{
	    fprintf (stderr, "%s : equipement '%s' not found\n", prog, eqname) ;
	    exit (1) ;
	}
    }
    else eq = NULL ;

    /*
     * Output the wifi probes first, since stat dump will reset marks
     */

    if (dumpwifi)
    {
	struct ssidprobe *sp ;

	for (sp = mobj_head (ssidprobemobj) ; sp != NULL ; sp = sp->next)
	{
	    if (eq == NULL || sp->eq == eq)
		if (MK_ISSELECTED (sp->l1))
		    output_ssidprobe (stdout, sp) ;
	}
    }

    if (dumpstat)
    {
	for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
	{
	    if (eq == NULL || n->eq == eq)
	    {
		if (n->nodetype == NT_L2 && MK_ISSELECTED (n))
		    output_collect_L2 (stdout, n) ;
		if (n->nodetype == NT_L1 && MK_ISSELECTED (n))
		    output_collect_L1 (stdout, n) ;
	    }
	}
    }

    sel_end () ;
    exit (0) ;
}
