/*
 * $Id: dupgraph.c,v 1.7 2008-06-14 21:05:49 pda Exp $
 */

#include "graph.h"

/******************************************************************************
 * Address translation API
 */

/*
 * Declaration of &tab[i] as a new address which corresponds
 * to old address optr, and copy the contents of the old address
 * into the new address. Increments the counter i.
 */

#define	TRANSNEW(tab,i,optr) \
		do { \
		    (tab) [(i)] = *(optr) ; \
		    transaddr_add (& (tab) [(i)], (optr)) ; \
		    (i)++ ; \
		} while (0)

/*
 * Get the new address associated with the old address (ptr)
 */

#define	TRANSPTR(ptr)	 	((ptr) = transaddr_get (ptr))

/*
 * Set the address of the head of a new mobj m1 to be the translation
 * of the address of the old mobj m2.
 */

#define	TRANSHEAD(m1,m2)	mobj_sethead (m1,transaddr_get(mobj_head(m2)))

/******************************************************************************
 * Address translation implementation
 */

#define	HASHADDRSIZE	16789

struct transaddr
{
    void *old ;
    void *new ;
    struct transaddr *next ;
} ;

struct transaddr *transaddr [HASHADDRSIZE] ;

static void transaddr_init (void)
{
    int i ;

    for (i = 0 ; i < HASHADDRSIZE ; i++)
	transaddr [i] = NULL ;
}

static int transaddr_hash (void *addr)
{
    return ((((unsigned long int) addr) & 0xfffffe) >> 2) % HASHADDRSIZE ;
}

static void *transaddr_get (void *old)
{
    int h ;
    struct transaddr *tp ;

    h = transaddr_hash (old) ;
    for (tp = transaddr [h] ; tp != NULL ; tp = tp->next)
	if (tp->old == old)
	    return tp->new ;
    return NULL ;
}

static void transaddr_add (void *new, void *old)
{
    int h ;
    struct transaddr *tp ;

    if (old == NULL || new == NULL)
	return ;

    if (transaddr_get (old) == NULL)
    {
	h = transaddr_hash (old) ;
	tp = malloc (sizeof *tp) ;
	if (tp == NULL)
	    error (1, "Cannot malloc memory for address translation") ;

	tp->new = new ;
	tp->old = old ;
	tp->next = transaddr [h] ;
	transaddr [h] = tp ;
    }
}



/******************************************************************************
 * Main part of the dupgraph module
 */

static void dup_all_mobj (MOBJ *new [], MOBJ *old [])
{
    int i, j ;
    int maxhash ;
    char *newstrtab ;
    struct symtab **oldhash, **newhash, *newsymtab ;
    int maxsym ;
    struct node *onode, *newnodetab ;
    int maxnode ;
    struct linklist *newllisttab ;
    int maxllist ;
    struct link *newlinktab ;
    int maxlink ;
    struct eq *oeq, *neweqtab ;
    int maxeq ;
    struct network *onet, *newnettab ;
    int maxnet ;
    struct netlist *newnlisttab ;
    int maxnlist ;
    struct lvlan *newlvlantab ;
    int maxlvlan ;
    struct rnet *ornet, *newrnettab ;
    int maxrnet ;
    struct route *newroutetab ;
    int maxroute ;
    struct vlan *oldvlan, *newvlan ;
    int maxssid ;
    struct ssid *ossid, *newssidtab ;

    /*************************************************************
     * First pass : copy all structures
     */

    /*
     * Hash table
     */

    oldhash = mobj_data (old [HASHMOBJIDX]) ;
    newhash = mobj_data (new [HASHMOBJIDX]) ;

    maxhash = mobj_count (old [HASHMOBJIDX]) ;
    for (i = 0 ; i < maxhash ; i++)
	newhash [i] = oldhash [i] ;

    /*
     * Symbol table
     */

    newsymtab = mobj_data (new [SYMMOBJIDX]) ;

    j = 0 ;
    for (i = 0 ; i < maxhash ; i++)
    {
	struct symtab *os ;

	for (os = oldhash [i] ; os != NULL ; os = os->next)
	    TRANSNEW (newsymtab, j, os) ;
    }
    if (j != mobj_count (old [SYMMOBJIDX]))
	error (0, "Panic. Wrong number of symtab mobj") ;
    maxsym = j ;

    /*
     * String table
     * Prerequisite : symtab
     */

    newstrtab = mobj_data (new [STRMOBJIDX]) ;

    j = 0 ;
    for (i = 0 ; i < maxsym ; i++)
    {
	strcpy (& newstrtab [j], newsymtab [i].name) ;
	transaddr_add (& newstrtab [j], newsymtab [i].name) ;
	j += strlen (newsymtab [i].name) + 1 ;
    }
    if (j != mobj_count (old [STRMOBJIDX]))
	error (0, "Panic. Wrong number of strtab mobj") ;

    /*
     * Ssid list
     */

    newssidtab = mobj_data (new [SSIDMOBJIDX]) ;

    j = 0 ;
    for (onode = mobj_head (old [NODEMOBJIDX]) ; onode != NULL ; onode = onode->next)
	if (onode->nodetype == NT_L1)
	    for (ossid = onode->u.l1.radio.ssid ; ossid != NULL ; ossid = ossid->next)
		TRANSNEW (newssidtab, j, ossid) ;
    if (j != mobj_count (old [SSIDMOBJIDX]))
	error (0, "Panic. Wrong number of ssid mobj") ;
    maxssid = j ;

    /*
     * Nodelist
     */

    newnodetab = mobj_data (new [NODEMOBJIDX]) ;

    j = 0 ;
    for (onode = mobj_head (old [NODEMOBJIDX]) ; onode != NULL ; onode = onode->next)
	TRANSNEW (newnodetab, j, onode) ;
    if (j != mobj_count (old [NODEMOBJIDX]))
	error (0, "Panic. Wrong number of node mobj") ;
    maxnode = j ;

    /*
     * All linklists
     */

    newllisttab = mobj_data (new [LLISTMOBJIDX]) ;

    j = 0 ;
    for (i = 0 ; i < maxnode ; i++)
    {
	struct linklist *ll ;

	for (ll = newnodetab [i].linklist ; ll != NULL ; ll = ll->next)
	    TRANSNEW (newllisttab, j, ll) ;
    }
    if (j != mobj_count (old [LLISTMOBJIDX]))
	error (0, "Panic. Wrong number of linklist mobj") ;
    maxllist = j ;

    /*
     * Link
     */

    newlinktab = mobj_data (new [LINKMOBJIDX]) ;

    j = 0 ;
    for (i = 0 ; i < maxllist ; i++)
    {
	if (transaddr_get (newllisttab [i].link) == NULL)
	    TRANSNEW (newlinktab, j, newllisttab [i].link) ;
    }
    if (j != mobj_count (old [LINKMOBJIDX]))
	error (0, "Panic. Wrong number of link mobj") ;
    maxlink = j ;

    /*
     * Equipements
     */

    neweqtab = mobj_data (new [EQMOBJIDX]) ;

    j = 0 ;
    for (oeq = mobj_head (old [EQMOBJIDX]) ; oeq != NULL ; oeq = oeq->next)
	TRANSNEW (neweqtab, j, oeq) ;
    if (j != mobj_count (old [EQMOBJIDX]))
	error (0, "Panic. Wrong number of eq mobj") ;
    maxeq = j ;

    /*
     * Vlans
     */

    oldvlan = mobj_data (old [VLANMOBJIDX]) ;
    newvlan = mobj_data (new [VLANMOBJIDX]) ;

    for (i = 0 ; i < MAXVLAN ; i++)
	newvlan [i] = oldvlan [i] ;

    /*
     * Networks
     */

    newnettab = mobj_data (new [NETMOBJIDX]) ;

    j = 0 ;
    for (onet = mobj_head (old [NETMOBJIDX]) ; onet != NULL ; onet = onet->next)
	TRANSNEW (newnettab, j, onet) ;
    if (j != mobj_count (old [NETMOBJIDX]))
	error (0, "Panic. Wrong number of network mobj") ;
    maxnet = j ;

    /*
     * Network lists
     */

    newnlisttab = mobj_data (new [NLISTMOBJIDX]) ;

    j = 0 ;
    for (i = 0 ; i < MAXVLAN ; i++)
    {
	struct netlist *nl ;

	for (nl = newvlan [i].netlist ; nl != NULL ; nl = nl->next)
	    TRANSNEW (newnlisttab, j, nl) ;
    }
    if (j != mobj_count (old [NLISTMOBJIDX]))
	error (0, "Panic. Wrong number of netlist mobj") ;
    maxnlist = j ;

    /*
     * Local vlan declarations
     */

    newlvlantab = mobj_data (new [LVLANMOBJIDX]) ;

    j = 0 ;
    for (i = 0 ; i < MAXVLAN ; i++)
    {
	struct lvlan *nv ;

	for (nv = newvlan [i].lvlan ; nv != NULL ; nv = nv->next)
	    TRANSNEW (newlvlantab, j, nv) ;
    }
    if (j != mobj_count (old [LVLANMOBJIDX]))
	error (0, "Panic. Wrong number of lvlan mobj") ;
    maxlvlan = j ;

    /*
     * Routed networks
     */

    newrnettab = mobj_data (new [RNETMOBJIDX]) ;

    j = 0 ;
    for (ornet = mobj_head (old [RNETMOBJIDX]) ; ornet != NULL ; ornet = ornet->next)
	TRANSNEW (newrnettab, j, ornet) ;
    if (j != mobj_count (old [RNETMOBJIDX]))
	error (0, "Panic. Wrong number of rnet mobj") ;
    maxrnet = j ;

    /*
     * Route entries
     */

    newroutetab = mobj_data (new [ROUTEMOBJIDX]) ;

    j = 0 ;
    for (i = 0 ; i < maxrnet ; i++)
    {
	struct route *or ;

	for (or = newrnettab [i].routelist ; or != NULL ; or = or->next)
	    TRANSNEW (newroutetab, j, or) ;
    }
    if (j != mobj_count (old [ROUTEMOBJIDX]))
	error (0, "Panic. Wrong number of route mobj") ;
    maxroute = j ;

    /*************************************************************
     * Second pass : update all pointers in new arrays
     */

    /*
     * Hash table
     */

    for (i = 0 ; i < maxhash ; i++)
	TRANSPTR (newhash [i]) ;

    /*
     * Symbol table
     */

    for (i = 0 ; i < maxsym ; i++)
    {
	TRANSPTR (newsymtab [i].name) ;
	TRANSPTR (newsymtab [i].node) ;
	TRANSPTR (newsymtab [i].link) ;
	TRANSPTR (newsymtab [i].next) ;
    }

    /*
     * Ssid
     */

    for (i = 0 ; i < maxssid ; i++)
    {
	TRANSPTR (newssidtab [i].name) ;
	TRANSPTR (newssidtab [i].next) ;
    }
    TRANSHEAD (new [SSIDMOBJIDX], old [SSIDMOBJIDX]) ;


    /*
     * Equipements
     */

    for (i = 0 ; i < maxeq ; i++)
    {
	TRANSPTR (neweqtab [i].name) ;
	TRANSPTR (neweqtab [i].type) ;
	TRANSPTR (neweqtab [i].model) ;
	TRANSPTR (neweqtab [i].snmp) ;
	TRANSPTR (neweqtab [i].location) ;
	TRANSPTR (neweqtab [i].next) ;
    }
    TRANSHEAD (new [EQMOBJIDX], old [EQMOBJIDX]) ;

    /*
     * Nodes
     */

    for (i = 0 ; i < maxnode ; i++)
    {
	TRANSPTR (newnodetab [i].name) ;
	TRANSPTR (newnodetab [i].eq) ;
	TRANSPTR (newnodetab [i].linklist) ;
	TRANSPTR (newnodetab [i].next) ;

	switch (newnodetab [i].nodetype)
	{
	    case NT_L1 :
		TRANSPTR (newnodetab [i].u.l1.ifname) ;
		TRANSPTR (newnodetab [i].u.l1.ifdesc) ;
		TRANSPTR (newnodetab [i].u.l1.link) ;
		TRANSPTR (newnodetab [i].u.l1.stat) ;
		TRANSPTR (newnodetab [i].u.l1.radio.ssid) ;
		break ;
	    case NT_L2 :
		TRANSPTR (newnodetab [i].u.l2.stat) ;
		break ;
	    case NT_L3 :
	    case NT_BRIDGE :
		break ;
	    case NT_ROUTER :
		TRANSPTR (newnodetab [i].u.router.name) ;
		break ;
	    case NT_L2PAT :
	    case NT_BRPAT :
		error (0, "An L2PAT/BRPAT should not occur here") ;
		break ;
	}
    }
    TRANSHEAD (new [NODEMOBJIDX], old [NODEMOBJIDX]) ;

    /*
     * Linklist
     */

    for (i = 0 ; i < maxllist ; i++)
    {
	TRANSPTR (newllisttab [i].link) ;
	TRANSPTR (newllisttab [i].next) ;
    }

    /*
     * Links
     */

    for (i = 0 ; i < maxlink ; i++)
    {
	TRANSPTR (newlinktab [i].name) ;
	TRANSPTR (newlinktab [i].node [0]) ;
	TRANSPTR (newlinktab [i].node [1]) ;
    }

    /*
     * Networks
     */

    for (i = 0 ; i < maxnet ; i++)
    {
	TRANSPTR (newnettab [i].next) ;
    }
    TRANSHEAD (new [NETMOBJIDX], old [NETMOBJIDX]) ;

    /*
     * Network lists
     */

    for (i = 0 ; i < maxnlist ; i++)
    {
	TRANSPTR (newnlisttab [i].net) ;
	TRANSPTR (newnlisttab [i].next) ;
    }

    /*
     * Local vlan declarations
     */

    for (i = 0 ; i < maxlvlan ; i++)
    {
	TRANSPTR (newlvlantab [i].eq) ;
	TRANSPTR (newlvlantab [i].name) ;
	TRANSPTR (newlvlantab [i].next) ;
    }

    /*
     * Vlan
     */

    for (i = 0 ; i < MAXVLAN ; i++)
    {
	TRANSPTR (newvlan [i].name) ;
	TRANSPTR (newvlan [i].netlist) ;
	TRANSPTR (newvlan [i].lvlan) ;
    }
    TRANSHEAD (new [VLANMOBJIDX], old [VLANMOBJIDX]) ;

    /*
     * Routed networks
     */

    for (i = 0 ; i < maxrnet ; i++)
    {
	TRANSPTR (newrnettab [i].net) ;
	TRANSPTR (newrnettab [i].router) ;
	TRANSPTR (newrnettab [i].l3) ;
	TRANSPTR (newrnettab [i].l2) ;
	TRANSPTR (newrnettab [i].l1) ;
	TRANSPTR (newrnettab [i].routelist) ;
	TRANSPTR (newrnettab [i].next) ;
    }
    TRANSHEAD (new [RNETMOBJIDX], old [RNETMOBJIDX]) ;

    /*
     * Route entries
     */

    for (i = 0 ; i < maxroute ; i++)
    {
	TRANSPTR (newroutetab [i].next) ;
    }
}


void duplicate_graph (MOBJ *new [], MOBJ *old [])
{
    int i ;

    transaddr_init () ;
    for (i = 0 ; i < NB_MOBJ ; i++)
    {
	new [i] = mobj_init (mobj_size (old [i]), MOBJ_CONST) ;
	mobj_alloc (new [i], mobj_count (old [i])) ;
    }
    dup_all_mobj (new, old) ;
}
