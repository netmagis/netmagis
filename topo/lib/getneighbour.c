/*
 */

#include "graph.h"

/*
 * Get a node's neighbour with a given type.
 * It is assumed that there is only one neighour with this type.
 */

struct node *get_neighbour (struct node *n, enum nodetype type)
{
    struct linklist *ll ;
    struct node *nh ;

    nh = NULL ;
    for (ll = n->linklist ; ll != NULL ; ll = ll->next)
    {
	nh = getlinkpeer(ll->link, n) ;
	if (nh->nodetype == type)
	    break ;
	nh = NULL ;
    }
    return nh ;
}
