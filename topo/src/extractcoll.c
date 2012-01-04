/*
 */

#include "graph.h"

/******************************************************************************
Example of output format

trafic      <id coll> <eq> <community> <phys iface> <vlan id|->
nbassocwifi <id coll> <eq> <community> <phys iface> <ssid>
nbauthwifi  <id coll> <eq> <community> <phys iface> <ssid>
portmac    <id coll> <eq> <community> <eqtype> <if1,if2...> <vlan id>
ipmac   <id coll> <eq> <community>

trafic M123 crc-rc1 commsnmp ge-1/2/3 58
trafic M125 crc-cc1 commsnmp GigaMachin-4/5/6 58
trafic M125 toto-ce1 commsnmp GigaMachin-0/1 -
nbassocwifi Mtruc.asso titi-ap1 commsnmp Dot11Radio0 osiris
nbauthwifi  Mtruc.auth titi-ap1 commsnmp Dot11Radio0 osiris
portmac  Pcrc-cc1.123 crc-cc1 commsnmp cisco Gi0/1,Gi0/2,Gi0/3 123
ipmac Icrc-rc1 crc-rc1 public

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
Output ipmac
******************************************************************************/

void output_ipmac (FILE *fp, struct eq *eq)
{
    /* ipmac <id coll> <eq> <community> */
    fprintf (fp, "ipmac I%s %s %s\n",
		    eq->name,
		    eq->name,
		    eq->snmp
		) ;
}


/******************************************************************************
Output portmac
******************************************************************************/

void output_portmac (FILE *fp, struct node *bridgenode)
{
    struct linklist *ll ;
    struct node *n ;
    vlanset_t vlanset;
    vlan_t v;
    int done = 0;
    
    /* get all VLAN ids */
    vlan_zero(vlanset);
    for (ll = bridgenode->linklist ; ll != NULL ; ll = ll->next)
    {
    	struct link *l ; struct node *other ;

	l = ll->link ;
	other = getlinkpeer (l, bridgenode) ;
	if(other->nodetype == NT_L2)
		vlan_set (vlanset, other->u.l2.vlan);
    }

    /* for each VLAN found */
    for (v = 0 ; v < MAXVLAN ; v++)
    {
    	if(vlan_isset (vlanset, v)) 
	{
	    /* process each L2 node */
	    for (ll = bridgenode->linklist ; ll != NULL ; ll = ll->next)
	    {
		struct link *l ;
		struct node *L2node ;

		l = ll->link ;
		L2node = getlinkpeer (l, bridgenode) ;

		/* examine associated L1 */
		if(L2node->nodetype == NT_L2)
		{
		    struct node *L1node ;

		    L1node = get_neighbour (L2node, NT_L1) ;

		    /* only edge L1 interface */
		    if(L1node != NULL
			    && MK_ISSELECTED (L1node)
			    && !MK_ISSET(L1node, MK_PORTMAC)
			    && strcmp (L1node->u.l1.link, EXTLINK) == 0)
		    {
			    char *ifname = L1node->u.l1.ifname;

			    if(!done)
			    {
				/* portmac <id_collect> <eq> <comm> <eqtype> <iflist> <vlan> */
				fprintf (fp, "portmac P%s.%d %s %s %s",
					    bridgenode->eq->name,
					    v,
					    bridgenode->eq->name,
					    bridgenode->eq->snmp,
					    bridgenode->eq->type
					) ;

				done = 1 ;
			    }
			    fprintf(fp, " %s", ifname) ;

			    /* mark node */
			    MK_SET(L1node, MK_PORTMAC) ;
		    }
		}
	    }

	    if(done)
	    {
		/* output vlan id */
	        fprintf(fp, " %d\n", v) ;
	    	done = 0 ;
	    }


	    /* clear mark */
	    for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
	    {
		if(n->nodetype == NT_L1)
		    MK_CLEAR (n, MK_PORTMAC) ;
	    }

	}
    }
}


/******************************************************************************
Main function
******************************************************************************/

void usage (char *progname)
{
    fprintf (stderr, "Usage : %s [-a|-n cidr|-e regexp|-E regexp|-t|-m]* [-s] [-w] [-p] [eq]\n", progname) ;
    exit (1) ;
}

MOBJ *mobjlist [NB_MOBJ] ;

int main (int argc, char *argv [])
{
    char *prog, *errstr ;
    int c, err ;
    char *eqname ;
    struct eq *eq, *neq ;
    struct node *n ;
    int dumpstat, dumpwifi, dumppmac, dumpipmac ;

    /*
     * Analyzes arguments
     */

    prog = argv [0] ;
    err = 0 ;
    dumpstat = 0 ;
    dumpwifi = 0 ;
    dumppmac = 0 ;
    dumpipmac = 0 ;

    sel_init () ;

    while ((c = getopt (argc, argv, "an:e:E:timpsw")) != -1)
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
	    case 'p' :
		dumppmac = 1 ;
		break ;
	    case 'i' :
		dumpipmac = 1 ;
		break ;
	    case '?' :
	    default :
		usage (prog) ;
	}
    }

    if (err)
	exit (1) ;

    if (dumpstat == 0 && dumpwifi == 0 && dumppmac == 0 && dumpipmac == 0)
    {
	dumpstat = 1 ;
	dumpwifi = 1 ;
	dumppmac = 1 ;
	dumpipmac = 1 ;
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

    if (dumppmac)
    {
	for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
	{
	    if ((eq == NULL || n->eq == eq)
			&& n->nodetype == NT_BRIDGE
		    	&& n->eq->portmac
			&& MK_ISSELECTED (n->eq))
			output_portmac (stdout, n) ;
	}
    }

    if (dumpipmac)
    {
	if (eq == NULL)
	{
	    for (neq = mobj_head (eqmobj) ; neq != NULL ; neq = neq->next)
	    {
		if(neq->ipmac && MK_ISSELECTED (neq))
		    output_ipmac (stdout, neq) ;
	    }
	}
	else
	{
	    if(eq->ipmac && MK_ISSELECTED (eq))
		output_ipmac (stdout, eq) ;
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
