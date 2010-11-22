/*
 */

#include "graph.h"


/******************************************************************************
Example of output format


eq crc-rc1:_v4		router
eq crc-rc1:adm		router
eq hemato-rc1:_v4	router
eq ns1			host

cloud domaine-broadcast-1 \
	{crc-rc1 i/f vlan} 	# arg. de extractl2 pour le dom. de broadcast
	{titre... composé de tous les num de vlan et les desc associées}
	{cidr v4 et v6 de tous les réseaux}

# link to a cloud
link crc-rc1:adm ge-4/5/6.18 {130.79.201.253 2001:660....} \
	L103 \
	domaine-broadcast-1

# direct link between equipements
direct crc-rc1:_v4 ge-0/0/0.7 {130.79.201.253 2001:660....} \
	L116 \
	hemato-rc1:_v4 ge-1/2/3.7 {130.79.201.253 ...}

... (all link or direct)
******************************************************************************/

#define	CLOUDFORMAT	"bcastdom-%d"
#define MAXCLOUDNAME	200

#define	MAXNET		10		/* max # of nets displayed in a cloud */

#define	MAXIFPERIP	500		/* max # of L1 nodes per L3 in an eq */

/*
 * L3 node marking
 */

#define	MK_IPMATCH	(MK_LAST<<1)	/* has been selected by a cidr arg */
#define	MK_ISROUTER	(MK_LAST<<2)	/* node is a router */
#define	MK_VLANTRAVERSAL (MK_LAST<<3)	/* used temporarily in vlan traversal */
#define	MK_PROCESSED	(MK_LAST<<4)	/* node processed */

/*
 * L2 node marking
 */

#define	MK_OUTPUTLINK	(MK_LAST<<5)	/* ???? */


/******************************************************************************
???????????,,
******************************************************************************/

/*
 * Search for first interface (L1 node) marked with a L2 node marked
 */

void find_interface (struct node **l1node, struct node **l2node)
{
    struct node *n, *p ;
    struct linklist *ll ;

    *l1node = *l2node = NULL ;

    for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
    {
	if (n->nodetype == NT_L1 && MK_ISSET (n, MK_L2TRANSPORT))
	{
	    for (ll = n->linklist ; ll != NULL ; ll = ll->next)
	    {
		p = getlinkpeer (ll->link, n) ;
		if (p->nodetype == NT_L2 && MK_ISSET (p, MK_L2TRANSPORT))
		{
		    *l1node = n ;
		    *l2node = p ;
		    return ;
		}
	    }
	}
    }

    return ;
}

int find_networks (ip_t tabnet [], int maxtab)
{
    struct node *n ;
    int ntab, i ;
    int match ;

    ntab = 0 ;
    for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
    {
	if (n->nodetype == NT_L3 && MK_ISSET (n, MK_VLANTRAVERSAL))
	{
	    if (ntab < maxtab)
	    {
		ip_netof (&n->u.l3.addr, &tabnet [ntab]) ;
		match = 0 ;
		for (i = 0 ; i < ntab ; i++)
		{
		    if (ip_match (&tabnet [ntab], &tabnet [i], 1))
		    {
			match = 1 ;
			break ;
		    }
		}
		if (! match)
		    ntab++ ;
	    }
	    else break ;
	}
    }
    return ntab ;
}

/******************************************************************************
???????????,,
******************************************************************************/

void output_cloud (FILE *fp, struct node *n, char *cloudname, size_t size)
{
    static int cloudno = 0 ;
    struct node *l1node, *l2node ;
    vlanset_t vs ;
    ip_t tabnet [MAXNET] ;
    int ntab ;
    iptext_t addr ;
    int i ;

    cloudno++ ;
    snprintf (cloudname, size, CLOUDFORMAT, cloudno) ;

    fprintf (fp, "cloud %s", cloudname) ;

    /*
     * Reference to the broadcast domain
     * - get the first marked L1 interface
     * - name of equipement of this L1
     * - get the first marked L2 from this L1
     */

    find_interface (&l1node, &l2node) ;
    if (l1node == NULL || l2node == NULL)
    {
	/*
	 * Degenerated case such as an L3 node not connected to the
	 * rest of the world...
	 */
	if (l2node == NULL)
	    l2node = get_neighbour (n, NT_L2) ;

	if (l2node != NULL)
	    fprintf (fp, " {%s %s %d}", l2node->eq->name, "-", l2node->u.l2.vlan) ;
	else
	    fprintf (fp, " {%s %s %d}", "-", "-", 0) ;
    }
    else
	fprintf (fp, " {%s %s %d}",
			    l1node->eq->name, l1node->u.l1.ifname, l2node->u.l2.vlan) ;

    /*
     * Get all vlan used
     */

    traversed_vlans (vs) ;
    fprintf (fp, " {") ;
    print_vlanlist (fp, vs, 1) ;
    fprintf (fp, "}") ;

    /*
     * Get all network CIDR from L3 nodes
     */

    ntab = find_networks (tabnet, NTAB (tabnet)) ;
    fprintf (fp, " {") ;
    for (i = 0 ; i < ntab ; i++)
    {
	if (i != 0)
	    fprintf (fp, " ") ;
	ip_ntop (&tabnet [i], addr, 1) ;
	fprintf (fp, "%s", addr) ;
    }
    fprintf (fp, "}") ;

    fprintf (fp, "\n") ;
}

/******************************************************************************
Walk inside an equipement from an L3 node to all L1 nodes, tracing the path
******************************************************************************/

struct l3tol1
{
    struct node *l1 ;
    struct node *l2 ;
    struct node *r ;
} ;
typedef struct l3tol1 l3tol1_t ;

int get_l3tol1_L1 (FILE *fp, struct node *n, l3tol1_t *tab, int max, int idx) ;
int get_l3tol1_L2 (FILE *fp, struct node *n, l3tol1_t *tab, int max, int idx) ;
int get_l3tol1_bridge (FILE *fp, struct node *n, l3tol1_t *tab, int max, int idx) ;

int get_l3tol1_L1 (FILE *fp, struct node *n, l3tol1_t *tab, int max, int idx)
{
    if (! MK_ISSET (n, MK_L2TRANSPORT))
	return idx ;

    if (MK_ISSET (n, MK_OUTPUTLINK))
	return idx ;
    MK_SET (n, MK_OUTPUTLINK) ;

    tab [idx].l1 = n ;
    idx++ ;				/* we found an L1 */
    if (idx >= max)
    {
	fprintf (stderr, "More than %d interfaces in %s", max, n->eq->name) ;
	exit (1) ;
    }
    tab [idx].l2 = tab [idx-1].l2 ;
    tab [idx].r  = tab [idx-1].r ;

    return idx ;
}

int get_l3tol1_L2 (FILE *fp, struct node *n, l3tol1_t *tab, int max, int idx)
{
    struct linklist *ll ;

    if (! MK_ISSET (n, MK_L2TRANSPORT))
	return idx ;

    if (MK_ISSET (n, MK_OUTPUTLINK))
	return idx ;
    MK_SET (n, MK_OUTPUTLINK) ;

    for (ll = n->linklist ; ll != NULL ; ll = ll->next)
    {
	struct node *p ;

	p = getlinkpeer (ll->link, n) ;
	switch (p->nodetype)
	{
	    case NT_L1 :
		tab [idx].l2 = n ;
		idx = get_l3tol1_L1 (fp, p, tab, max, idx) ;
		break ;
	    case NT_BRIDGE :
		idx = get_l3tol1_bridge (fp, p, tab, max, idx) ;
		break ;
	    default :
		break ;
	}
    }
    return idx ;
}

int get_l3tol1_bridge (FILE *fp, struct node *n, l3tol1_t *tab, int max, int idx)
{
    struct linklist *ll ;

    if (! MK_ISSET (n, MK_L2TRANSPORT))
	return idx ;

    if (MK_ISSET (n, MK_OUTPUTLINK))
	return idx ;
    MK_SET (n, MK_OUTPUTLINK) ;

    for (ll = n->linklist ; ll != NULL ; ll = ll->next)
    {
	struct node *p ;

	p = getlinkpeer (ll->link, n) ;
	if (p->nodetype == NT_L2)
	    idx = get_l3tol1_L2 (fp, p, tab, max, idx) ;
    }
    return idx ;
}

int get_l3tol1 (FILE *fp, struct node *n, l3tol1_t *tab, int max)
{
    struct linklist *ll ;
    int idx ;

    /*
     * Search for routing instance if any
     */

    tab [0].r = get_neighbour (n, NT_ROUTER) ;
    idx = 0 ;

    for (ll = n->linklist ; ll != NULL ; ll = ll->next)
    {
	struct node *p ;

	p = getlinkpeer (ll->link, n) ;
	if (p->nodetype == NT_L2)
	{
	    struct node *m ;

	    for (m = mobj_head (nodemobj) ; m != NULL ; m = m->next)
		MK_CLEAR (m, MK_OUTPUTLINK) ;

	    idx = get_l3tol1_L2 (fp, p, tab, max, idx) ;
	}
    }
    return idx ;
}

/******************************************************************************
???????????,,
******************************************************************************/

void output_link (FILE *fp, struct node *n, char *cloudname)
{
    int nl1, i ;
    iptext_t ipaddr ;
    l3tol1_t tab [MAXIFPERIP] ;

    if (! MK_ISSELECTED (n))
	return ;

    nl1 = get_l3tol1 (fp, n, tab, NTAB(tab)) ;
    for (i = 0 ; i < nl1 ; i++)
    {
	l3tol1_t *p ;

	p = &tab [i] ;
	fprintf (fp, "link %s", n->eq->name) ;
	if (tab [i].r != NULL)
	    fprintf (fp, ":%s", p->r->u.router.name) ;

	fprintf (fp, " %s.%d", p->l1->u.l1.ifname, p->l2->u.l2.vlan) ;

	/* XXX : should we really print preflen ? */
	ip_ntop (&n->u.l3.addr, ipaddr, 1) ;
	fprintf (fp, " %s", ipaddr) ;

	if (p->l1->u.l1.link != NULL)
	    fprintf (fp, " %s", p->l1->u.l1.link) ;
	else
	    fprintf (fp, " (nolink)") ;

	fprintf (fp, " %s", cloudname) ;

	fprintf (fp, "\n") ;
    }
}

/******************************************************************************
???????????,,
******************************************************************************/

void output_direct (FILE *fp, struct node *n [2])
{
    int nl1 ;
    iptext_t ipaddr ;
    l3tol1_t tab [MAXIFPERIP] ;
    l3tol1_t *p ;
    int peer ;

    if (! (MK_ISSELECTED (n [0]) && MK_ISSELECTED (n [1])))
	return ;

    fprintf (fp, "direct ") ;

    for (peer = 0 ; peer < 2 ; peer++)
    {
	nl1 = get_l3tol1 (fp, n [peer], tab, NTAB(tab)) ;
	if (nl1 != 1)
	{
	    fprintf (stderr, "Direct link detected with 2 L1 on the same L3 node\n") ;
	    exit (1) ;
	}

	p = &tab [0] ;
	fprintf (fp, " %s", n [peer]->eq->name) ;
	if (tab [0].r != NULL)
	    fprintf (fp, ":%s", p->r->u.router.name) ;

	fprintf (fp, " %s.%d", p->l1->u.l1.ifname, p->l2->u.l2.vlan) ;

	/* XXX : should we really print preflen ? */
	ip_ntop (&n [peer]->u.l3.addr, ipaddr, 1) ;
	fprintf (fp, " %s", ipaddr) ;

	if (peer == 0)
	{
	    if (p->l1->u.l1.link != NULL)
		fprintf (fp, " %s", p->l1->u.l1.link) ;
	    else
		fprintf (fp, " (nolink)") ;
	}
    }

    fprintf (fp, "\n") ;
}

/******************************************************************************
???????????,,
******************************************************************************/

void walkl3 (FILE *fp, struct node *n)
{
    struct node *l2 ;
    struct node *m ;
    char cloudname [MAXCLOUDNAME] ;
    int l1count, l3count ;
    struct node *directl1 [2], *directl3 [2] ;
    int selected ;

    /*
     * Reset all non-L3 nodes
     */

    for (m = mobj_head (nodemobj) ; m != NULL ; m = m->next)
    {
	if (m->nodetype == NT_L3)
	    MK_CLEAR (m, MK_L2TRANSPORT) ;
	else
	{
	    MK_CLEAR (m, MK_L2TRANSPORT) ;
	    MK_CLEAR (m, MK_IPMATCH) ;
	    MK_CLEAR (m, MK_ISROUTER) ;
	    MK_CLEAR (m, MK_VLANTRAVERSAL) ;
	    MK_CLEAR (m, MK_PROCESSED) ;
	}
	vlan_zero (m->vlanset) ;
    }

    l2 = get_neighbour (n, NT_L2) ;
    if (l2 != NULL)
	transport_vlan_on_L2 (l2, l2->u.l2.vlan) ;

    /*
     * All reachable L2 nodes are marked.
     *
     * Count physical interfaces (L1 nodes) to see if this equipement
     * is connected via a direct link to another node, or if this
     * equipement is connected to a broadcast domain.
     *
     * Count marked L1 nodes. If there is only 2 of them, check if
     * linkname matches (if not "X", or EXTLINK).
     */

    l1count = 0 ;
    l3count = 0 ;

    selected = 0 ;
    for (m = mobj_head (nodemobj) ; m != NULL ; m = m->next)
    {
	if (m->nodetype == NT_L1 && MK_ISSET (m, MK_L2TRANSPORT))
	{
	    if (MK_ISSELECTED (m) || MK_ISSELECTED (m->eq))
		selected = 1 ;

	    if (l1count < 2)
		directl1 [l1count] = m ;
	    l1count++ ;
	}

	if (m->nodetype == NT_L3 && MK_ISSET (m, MK_L2TRANSPORT)
					&& MK_ISSET (m, MK_IPMATCH))
	{
	    if (MK_ISSELECTED (m) || MK_ISSELECTED (m->eq))
		selected = 1 ;

	    if (l3count < 2)
		directl3 [l3count] = m ;
	    l3count++ ;
	}
    }

    if (! selected)
	return ;

    if (l1count == 2 && l3count == 2 &&
		directl1 [0]->u.l1.link == directl1 [1]->u.l1.link)
    {
	/*
	 * This is a direct link between two L3 nodes
	 */

	output_direct (fp, directl3) ;

	MK_SET (directl3 [0], MK_PROCESSED) ;
	MK_SET (directl3 [1], MK_PROCESSED) ;
    }
    else
    {
	/*
	 * This is a cloud
	 */

	for (m = mobj_head (nodemobj) ; m != NULL ; m = m->next)
	{
	    if (m->nodetype == NT_L2 && MK_ISSET (m, MK_L2TRANSPORT))
	    {
		struct linklist *ll ;
		struct node *r ;

		for (ll = m->linklist ; ll != NULL ; ll = ll->next)
		{
		    r = getlinkpeer (ll->link, m) ;
		    if (r->nodetype == NT_L3 && MK_ISSET (r, MK_IPMATCH))
			MK_SET (r, MK_VLANTRAVERSAL) ;
		}
	    }
	}

	/*
	 * Output cloud
	 */

	output_cloud (fp, n, cloudname, sizeof cloudname) ;

	/*
	 * Output links to this cloud
	 */

	for (m = mobj_head (nodemobj) ; m != NULL ; m = m->next)
	{
	    if (m->nodetype == NT_L3 && MK_ISSET (m, MK_VLANTRAVERSAL))
	    {
		output_link (fp, m, cloudname) ;
		MK_CLEAR (m, MK_VLANTRAVERSAL) ;
		MK_SET (m, MK_PROCESSED) ;
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
    fprintf (stderr, "Usage : %s [-a|-n cidr|-e regexp|-E regexp|-t|-m]* cidr ... cidr\n", progname) ;
    exit (1) ;
}

int main (int argc, char *argv [])
{
    int i ;
    struct node *n ;
    struct eq *eq ;
    ip_t cidr ;
    int c, err ;
    char *prog, *errstr ;

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

    if (argc == 0)
	usage (prog) ;

    /*
     * Read the graph and select subgraph
     */

    bin_read (stdin, mobjlist) ;
    sel_mark () ;

    /*
     * First pass : mark all L3 nodes matching CIDR arguments
     */

    for (i = 0 ; i < argc ; i++)
    {
	if (! ip_pton (argv [i], &cidr))
	{
	    fprintf (stderr, "%s: Invalid cidr '%s'\n", prog, argv [i]) ;
	    exit (1) ;
	}

	for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
	    if (n->nodetype == NT_L3 && ip_match (&n->u.l3.addr, &cidr, 0))
		MK_SET (n, MK_IPMATCH) ;
    }

    /*
     * Output selection arguments
     */

    fprintf (stdout, "selection") ;
    for (i = 0 ; i < argc ; i++)
	fprintf (stdout, " %s", argv [i]) ;
    fprintf (stdout, "\n") ;

    /*
     * Second pass : identify all routing instances connected to those
     * L3 nodes we have marked before, and print equipements which are
     * routing instances.
     */

    for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
    {
	if (n->nodetype == NT_L3 && MK_ISSET (n, MK_IPMATCH))
	{
	    struct node *r ;

	    MK_SET (n->eq, MK_IPMATCH) ;

	    r = get_neighbour (n, NT_ROUTER) ;
	    if (r != NULL && ! MK_ISSET (r, MK_ISROUTER))
	    {
		MK_SET (n, MK_ISROUTER) ;
		MK_SET (r, MK_ISROUTER) ;
		MK_SET (n->eq, MK_ISROUTER) ;
		if (MK_ISSELECTED (n))
		    fprintf (stdout, "eq %s:%s router\n",
				    n->eq->name, r->u.router.name) ;
	    }
	}
    }

    /*
     * Third pass : print equipements which are not routing instances
     */

    for (eq = mobj_head (eqmobj) ; eq != NULL ; eq = eq->next)
	if (MK_ISSET (eq, MK_IPMATCH) && ! MK_ISSET (eq, MK_ISROUTER))
	    if (MK_ISSELECTED (eq))
		fprintf (stdout, "eq %s host\n", eq->name) ;

    /*
     * Fourth pass : identify broadcast domain for each L3
     */

    for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
    {
	if (n->nodetype == NT_L3
				&& MK_ISSET (n, MK_IPMATCH)
				&& ! MK_ISSET (n, MK_PROCESSED))
	    walkl3 (stdout, n) ;
    }

    sel_end () ;
    exit (0) ;
}
