/*
 * $Id: dupgraph.c,v 1.1.1.1 2007-01-05 15:12:00 pda Exp $
 */

#include "graph.h"

#define	TRANSNEW(tab,i,optr) \
		do { \
		    (tab) [(i)] = *(optr) ; \
		    transaddr_add (& (tab) [(i)], (optr)) ; \
		    (i)++ ; \
		} while (0)

#define	TRANSPTR(ptr)	 	((ptr) = transaddr_get (ptr))
#define	TRANSHEAD(m1,m2)	mobj_sethead (m1,transaddr_get(mobj_head(m2)))

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
    struct route *newroutetab ;
    int maxroute ;
    char **oldvdesc, **newvdesc ;

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
	error (0, "Panic. Wrong number of symtab objects") ;
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
	error (0, "Panic. Wrong number of strtab objects") ;

    /*
     * Nodelist
     */

    newnodetab = mobj_data (new [NODEMOBJIDX]) ;

    j = 0 ;
    for (onode = mobj_head (old [NODEMOBJIDX]) ; onode != NULL ; onode = onode->next)
	TRANSNEW (newnodetab, j, onode) ;
    if (j != mobj_count (old [NODEMOBJIDX]))
	error (0, "Panic. Wrong number of nodes") ;
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
	error (0, "Panic. Wrong number of linklist") ;
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
	error (0, "Panic. Wrong number of link") ;
    maxlink = j ;

    /*
     * Equipements
     */

    neweqtab = mobj_data (new [EQMOBJIDX]) ;

    j = 0 ;
    for (oeq = mobj_head (old [EQMOBJIDX]) ; oeq != NULL ; oeq = oeq->next)
	TRANSNEW (neweqtab, j, oeq) ;
    if (j != mobj_count (old [EQMOBJIDX]))
	error (0, "Panic. Wrong number of equipements") ;
    maxeq = j ;

    /*
     * Vlan descriptions
     */

    oldvdesc = mobj_data (old [VDESCMOBJIDX]) ;
    newvdesc = mobj_data (new [VDESCMOBJIDX]) ;

    for (i = 0 ; i < MAXVLAN ; i++)
	newvdesc [i] = oldvdesc [i] ;

    /*
     * Networks
     */

    newnettab = mobj_data (new [NETMOBJIDX]) ;

    j = 0 ;
    for (onet = mobj_head (old [NETMOBJIDX]) ; onet != NULL ; onet = onet->next)
	TRANSNEW (newnettab, j, onet) ;
    if (j != mobj_count (old [NETMOBJIDX]))
	error (0, "Panic. Wrong number of networks") ;
    maxnet = j ;

    /*
     * Route entries
     */

    newroutetab = mobj_data (new [ROUTEMOBJIDX]) ;

    j = 0 ;
    for (i = 0 ; i < maxnet ; i++)
    {
	struct route *or ;

	for (or = newnettab [i].routelist ; or != NULL ; or = or->next)
	    TRANSNEW (newroutetab, j, or) ;
    }
    if (j != mobj_count (old [ROUTEMOBJIDX]))
	error (0, "Panic. Wrong number of route entries") ;
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
		TRANSPTR (newnodetab [i].u.l1.link) ;
		TRANSPTR (newnodetab [i].u.l1.stat) ;
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
     * Equipements
     */

    for (i = 0 ; i < maxeq ; i++)
    {
	TRANSPTR (neweqtab [i].name) ;
	TRANSPTR (neweqtab [i].type) ;
	TRANSPTR (neweqtab [i].model) ;
	TRANSPTR (neweqtab [i].snmp) ;
	TRANSPTR (neweqtab [i].next) ;
    }
    TRANSHEAD (new [EQMOBJIDX], old [EQMOBJIDX]) ;

    /*
     * Vlan descriptions
     */

    for (i = 0 ; i < MAXVLAN ; i++)
	TRANSPTR (newvdesc [i]) ;

    /*
     * Networks
     */

    for (i = 0 ; i < maxnet ; i++)
    {
	TRANSPTR (newnettab [i].router) ;
	TRANSPTR (newnettab [i].l3) ;
	TRANSPTR (newnettab [i].l2) ;
	TRANSPTR (newnettab [i].l1) ;
	TRANSPTR (newnettab [i].routelist) ;
	TRANSPTR (newnettab [i].next) ;
    }
    TRANSHEAD (new [NETMOBJIDX], old [NETMOBJIDX]) ;

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
