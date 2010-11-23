/*
 */

#include "graph.h"

#include <regex.h>

#define	RE_MODE	(REG_EXTENDED | REG_ICASE)

/*
 * Selection criteria
 */

enum crittype
{
    CT_ALL,			/* for root only */
    CT_NET,			/* all ifaces in this broadcast domain */
    CT_REX,			/* all eq matching (or not) this regexp */
    CT_TERM,			/* only keep terminal ifaces */
    CT_OWN,			/* only keep ifaces where we own all vlans */
} ;

struct selnet
{
    ip_t addr ;
} ;

struct selrex
{
    int allow_deny ;
    regex_t rc ;
} ;

struct sel
{
    enum crittype crittype ;
    union
    {
	struct selnet net ;
	struct selrex rex ;
    } u ;
    struct sel *next ;
} ;

MOBJ *selmobj ;

/******************************************************************************
Initialization functions
******************************************************************************/

void sel_init (void)
{
    selmobj = mobj_init (sizeof (struct sel), MOBJ_MALLOC) ;
}

static void sel_free (MOBJ *m)
{
    struct sel *sl, *tmp ;

    sl = mobj_head (m) ;
    while (sl != NULL)
    {
	tmp = sl->next ;
	mobj_free (m, sl) ;
	sl = tmp ;
    }
    mobj_close (m) ;
}

void sel_end (void)
{
    sel_free (selmobj) ;
}

/******************************************************************************
Register each criterium
******************************************************************************/

char *sel_register (int opt, char *arg)
{
    struct sel *sl ;
    ip_t a ;
    regex_t rc ;
    char *r ;
    static char errstr [100] ;

    errstr [0] = '\0' ;
    MOBJ_ALLOC_INSERT (sl, selmobj) ;
    switch (opt)
    {
	case 'a' :
	    sl->crittype = CT_ALL ;
	    break ;
	case 'n' :
	    if (ip_pton (arg, &a))
	    {
		sl->crittype = CT_NET ;
		sl->u.net.addr = a ;
	    }
	    else sprintf (errstr, "'%s' is not a valid cidr", arg) ;
	    break ;
	case 'e' :
	case 'E' :
	    if (regcomp (&rc, arg, RE_MODE) == 0)
	    {
		sl->crittype = CT_REX ;
		sl->u.rex.allow_deny = (opt == 'e') ;
		sl->u.rex.rc = rc ;
	    }
	    else sprintf (errstr, "'%s' is not a valid regexp", arg) ;
	    break ;
	case 't' :
	    sl->crittype = CT_TERM ;
	    break ;
	case 'm' :
	    sl->crittype = CT_OWN ;
	    break ;
	default :
	    sprintf (errstr, "internal error : '-%c' is not a valid option", opt) ;
    }

    r = (errstr [0] == '\0') ? NULL : errstr ;
    return r ;
}

/******************************************************************************
Marking functions
******************************************************************************/

static void sel_mark_net (ip_t *addr)
{
    struct node *n, *l2node ;
    struct network *net ;

    for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
    {
	if (n->nodetype == NT_L3 && ip_match (&n->u.l3.addr, addr, 1))
	{
	    MK_SELECT (n) ;
	    l2node = get_neighbour (n, NT_L2) ;
	    if (l2node != NULL)
		transport_vlan_on_L2 (l2node, l2node->u.l2.vlan) ;
	}
    }

    for (net = mobj_head (netmobj) ; net != NULL ; net = net->next)
	if (ip_match (&net->addr, addr, 1))
	    MK_SELECT (net) ;

    for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
	if (MK_ISSET (n, MK_L2TRANSPORT))
	    MK_SELECT (n) ;
}

static void sel_mark_eq (struct eq *eq, int allow_deny)
{
    struct node *n ;

    if (allow_deny)
	MK_SELECT (eq) ;
    else MK_DESELECT (eq) ;

    for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
    {
	if (n->eq == eq)
	{
	    if (allow_deny)
		MK_SELECT (n) ;
	    else MK_DESELECT (n) ;
	}
    }
}

static void sel_mark_regexp (regex_t *rc, int allow_deny)
{
    struct eq *eq ;

    for (eq = mobj_head (eqmobj) ; eq != NULL ; eq = eq->next)
	if (regexec (rc, eq->name, 0, NULL, 0) == 0)
	    sel_mark_eq (eq, allow_deny) ;
}

static void sel_unmark_nonterminal (void)
{
    struct node *n ;

    for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
    {
	if (n->nodetype == NT_L1
			&& MK_ISSELECTED (n)
			&& strcmp (n->u.l1.link, EXTLINK) != 0)
	{
	    MK_DESELECT (n) ;
	}
    }
}

static void sel_unmark_notmine (void)
{
    struct node *n ;

    for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
    {
	if (n->nodetype == NT_L1 && MK_ISSELECTED (n))
	{
	    struct linklist *ll ;
	    int mine ;

	    /*
	     * Check all L2 neighbors to check if vlan-id have
	     * been transported on this L1.
	     */

	    mine = 1 ;
	    for (ll = n->linklist ; ll != NULL ; ll = ll->next)
	    {
		struct link *l ;
		struct node *other ;

		l = ll->link ;
		other = getlinkpeer (l, n) ;
		if (other->nodetype == NT_L2 && ! MK_ISSET (other, MK_L2TRANSPORT))
		{
		    mine = 0 ;
		    break ;
		}
	    }

	    if (! mine)
		MK_DESELECT (n) ;
	}
    }
}


void sel_mark (void)
{
    struct sel *sl ;
    struct node *n ;
    struct eq *eq ;
    struct vlan *vlantab ;
    struct network *net ;
    int i ;
    MOBJ *tmobj ;		/* temporary mobj to reverse list */

    /*
     * Create temporary list, ordered
     */

    tmobj = mobj_init (sizeof (struct sel), MOBJ_MALLOC) ;
    for (sl = mobj_head (selmobj) ; sl != NULL ; sl = sl->next)
    {
	struct sel *tsl ;
	MOBJ_ALLOC_INSERT (tsl, tmobj) ;
	tsl->crittype = sl->crittype ;
	tsl->u = sl->u ;
    }

    /*
     * Initialize graph : everything must be clear
     */

    vlantab = mobj_data (vlanmobj) ;

    for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
    {
	n->mark = 0 ;
	vlan_zero (n->vlanset) ;
    }

    for (eq = mobj_head (eqmobj) ; eq != NULL ; eq = eq->next)
	eq->mark = 0 ;

    for (i = 0 ; i < MAXVLAN ; i++)
	vlantab [i].mark = 0 ;

    for (net = mobj_head (netmobj) ; net != NULL ; net = net->next)
	net->mark = 0 ;

    /*
     * Traverse the selection criteria mobj
     */

    for (sl = mobj_head (tmobj) ; sl != NULL ; sl = sl->next)
    {
	switch (sl->crittype)
	{
	    case CT_ALL :
		/*
		 * Select all objects in the graph
		 */

		for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
		    n->mark = MK_SELECTED ;
		for (eq = mobj_head (eqmobj) ; eq != NULL ; eq = eq->next)
		    eq->mark = MK_SELECTED ;
		for (i = 0 ; i < MAXVLAN ; i++)
		    vlantab [i].mark = MK_SELECTED ;
		for (net = mobj_head (netmobj) ; net != NULL ; net = net->next)
		    net->mark = MK_SELECTED ;
		break ;

	    case CT_NET :
		/*
		 * Select nodes based on network cidr
		 * Select routed networks based on network cidr
		 */

		sel_mark_net (&sl->u.net.addr) ;
		break ;

	    case CT_REX :
		/*
		 * Select equipements based on regexp
		 */

		sel_mark_regexp (&sl->u.rex.rc, sl->u.rex.allow_deny) ;
		break ;

	    case CT_TERM :
		/*
		 * Keep only terminal interfaces
		 */

		sel_unmark_nonterminal () ;
		break ;

	    case CT_OWN :
		/*
		 * Keep only "my" interfaces : those which transport
		 * only "my" networks/Vlans
		 */

		sel_unmark_notmine () ;
		break ;

	    default :
		break ;
	}
    }

    /*
     * Selects all equipements where at least one L1 interface is marked
     */

    for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
	if (n->nodetype == NT_L1 && MK_ISSELECTED (n))
	    MK_SELECT (n->eq) ;

    /*
     * Select Vlans where L2 node have been selected in the
     * L2 traversal.
     */

    for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
	if (n->nodetype == NT_L2 && MK_ISSET (n, MK_L2TRANSPORT))
	    MK_SELECT (&vlantab [n->u.l2.vlan]) ;

    /*
     * Close the temporary mobj
     */

    sel_free (tmobj) ;
}
