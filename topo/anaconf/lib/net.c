/*
 * $Id$
 */

#include "graph.h"

/******************************************************************************
Network address management
******************************************************************************/

/*
 * Look up address (in network format)
 */

struct network *net_lookup_n (ip_t *addr)
{
    struct network *n ;

    for (n = mobj_head (netmobj) ; n != NULL ; n = n->next)
	if (ip_equal (&n->addr, addr))
	    break ;

    return n ;
}

/*
 * Insert address (in network format) if not found
 */

struct network *net_get_n (ip_t *addr)
{
    struct network *n ;

    n = net_lookup_n (addr) ;
    if (n == NULL)
    {
	MOBJ_ALLOC_INSERT (n, netmobj) ;
	n->addr = *addr ;
    }
    return n ;
}

/*
 * Look up address (in presentation format)
 */

struct network *net_lookup_p (char *addr)
{
    struct network *n ;
    ip_t a ;

    n = NULL ;
    if (ip_pton (addr, &a))
	n = net_lookup_n (&a) ;

    return n ;
}

/*
 * Insert address (in presentation format) if not found
 */

struct network *net_get_p (char *addr)
{
    struct network *n ;
    ip_t a ;

    n = NULL ;
    if (ip_pton (addr, &a))
	n = net_get_n (&a) ;

    return n ;
}
