/*
 */

#include "graph.h"

/******************************************************************************
Example of output format


eq crc-cc1 cisco/WS-C4506 45464748
iface GigaEthernet0/1
    <radio>
    <M123 ou ->
    <Ether ou Trunk ou Disabled>
    {X / L33 crc-rc1 ge-0/0/0}
    <nativevlan ou -1> 
    <desc> {0 {} <ip> ...} {7 <vlan-desc-en-hexa> 130.79.....} ...
<all ifaces>
vlan <id> <desc> <voip>

with <radio> = {<channel> <power> <ssid> <ssid> ...} ou {}
******************************************************************************/

#define	LB	'{'
#define	RB	'}'

/******************************************************************************
Output routines
******************************************************************************/

void output_eq (FILE *fp, struct eq *eq)
{
    fprintf (fp, "eq %s %s %s %s\n", eq->name, eq->type, eq->model,
			    (eq->location == NULL ? "-" : eq->location)
		) ;
}

void output_iface (FILE *fp, struct node *n)
{
    char *ifname ;
    char *stat ;
    char *type ;
    char *desc ;
    struct node *peer ;
    struct linklist *ll1, *ll2, *ll3 ;
    vlan_t native ;

    ifname = n->u.l1.ifname ;
    stat = (n->u.l1.stat == NULL) ? "-" : n->u.l1.stat ;
    switch (n->u.l1.l1type)
    {
	case L1T_DISABLED :
	    type = "Disabled" ;
	    break ;
	case L1T_TRUNK :
	    type = "Trunk" ;
	    break ;
	case L1T_ETHER :
	    type = "Ether" ;
	    break ;
    }
    desc = (n->u.l1.ifdesc == NULL) ? "-" : n->u.l1.ifdesc ;

    fprintf (fp, "iface %s", ifname) ;

    /*
     * Check radio parameters
     */

    fprintf (fp, " %c", LB) ;
    if (n->u.l1.radio.ssid != NULL)
    {
	struct ssid *s ;

	switch (n->u.l1.radio.channel)
	{
	    case CHAN_DFS :
		fprintf (fp, "dfs") ;
		break ;
	    default :
		fprintf (fp, "%d", n->u.l1.radio.channel) ;
	}
	fprintf (fp, " %d", n->u.l1.radio.power) ;
	for (s = n->u.l1.radio.ssid ; s != NULL ; s = s->next)
	    fprintf (fp, " %s", s->name) ;
    }

    fprintf (fp, "%c %s %s %s", RB, stat, type, desc) ;

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
     * Search all L2 interfaces to detect native vlan if any
     */

    native = -1 ;
    for (ll2 = n->linklist ; ll2 != NULL ; ll2 = ll2->next)
    {
	struct node *peer2 ;

	peer2 = getlinkpeer (ll2->link, n) ;
	if (peer2->nodetype == NT_L2 && MK_ISSELECTED (peer2))
	{
	    if (peer2->u.l2.native)
		native = peer2->u.l2.vlan ;
	}
    }
    fprintf (fp, " %d", native) ;

    /*
     * Search all L2 interfaces
     */

    for (ll2 = n->linklist ; ll2 != NULL ; ll2 = ll2->next)
    {
	struct node *peer2 ;

	peer2 = getlinkpeer (ll2->link, n) ;
	if (peer2->nodetype == NT_L2 && MK_ISSELECTED (peer2))
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

void output_vlan (FILE *fp, vlan_t v, struct vlan *vobj, struct eq *eq)
{
    struct lvlan *lv ;
    int found ;

    /*
     * Is this vlan present on this equipement ?
     */

    found = 0 ;
    for (lv = vobj->lvlan ; lv != NULL ; lv = lv->next)
    {
	if (lv->eq == eq)
	{
	    found = 1;
	    break ;
	}
    }

    if (found)
	fprintf (fp, "vlan %d %s %d\n", v, vobj->name, vobj->voice) ;
}

/******************************************************************************
Main function
******************************************************************************/

MOBJ *mobjlist [NB_MOBJ] ;

void usage (char *progname)
{
    fprintf (stderr, "Usage : %s [-a|-n cidr|-e regexp|-E regexp|-t|-m]* eq [iface]\n", progname) ;
    exit (1) ;
}

int main (int argc, char *argv [])
{
    struct node *n ;
    char *prog, *errstr ;
    char *eqname, *iface ;
    struct eq *eq ;
    int c, err ;
    vlan_t v ;
    struct vlan *vlantab ;

    prog = argv [0] ;
    err = 0 ;

    sel_init () ;

    while ((c = getopt (argc, argv, "an:e:E:tm")) != -1)
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
	    case '?' :
	    default :
		usage (prog) ;
	}
    }

    if (err)
	exit (1) ;

    argc -= optind ;
    argv += optind ;

    switch (argc)   
    {
	case 1 :
	    eqname = argv [0] ;
	    iface = NULL ;
	    break ;
	case 2 :
	    eqname = argv [0] ;
	    iface = argv [1] ;
	    break ;
	default :
	    usage (prog) ;
    }

    /*
     * Read the graph
     */

    bin_read (stdin, mobjlist) ;
    sel_mark () ;

    /*
     * Search selected equipement
     */

    eq = eq_lookup (eqname) ;
    if (eq != NULL && MK_ISSELECTED (eq))
    {
	/*
	 * Output the final result
	 */

	output_eq (stdout, eq) ;

	for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
	    if (n->eq == eq && n->nodetype == NT_L1 && MK_ISSELECTED (n))
		if (iface == NULL || strcmp (iface, n->u.l1.ifname) == 0)
		    output_iface (stdout, n) ;

	vlantab = mobj_data (vlanmobj) ;
	for (v = 0 ; v < MAXVLAN ; v++)
	    if (vlantab [v].name != NULL && MK_ISSELECTED (&vlantab [v]))
		output_vlan (stdout, v, &vlantab [v], eq) ;
    }

    sel_end () ;
    exit (0) ;
}
