/*
 */

#include "graph.h"

/*
 * Possible combinations of type nodes
 */

void check_links (void)
{
    struct node *n ;
    static enum nodetype linkcheck [] [2] =
    {
	{ NT_L1, NT_L1},
	{ NT_L1, NT_L2},
	{ NT_L2, NT_L3},
	{ NT_L2, NT_BRIDGE},
	{ NT_L3, NT_ROUTER},
	{ NT_L2PAT, NT_L1},
	{ NT_L2PAT, NT_BRPAT},
	{ NT_BRPAT, NT_L2},
    } ;

    for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
	vlan_zero (n->vlanset) ;

    for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
    {
	struct linklist *ll ;

	for (ll = n->linklist ; ll != NULL ; ll = ll->next)
	{
	    struct link *l ;

	    l = ll->link ;
	    if (! (vlan_isset (l->node [0]->vlanset, 0) ||
		vlan_isset (l->node [1]->vlanset, 0) ) )
	    {
		int i ;

		for (i = 0 ; i < NTAB (linkcheck) ; i++)
		{
		    if (((l->node [0]->nodetype == linkcheck [i] [0]) &&
			 (l->node [1]->nodetype == linkcheck [i] [1]))
			 ||
		        ((l->node [0]->nodetype == linkcheck [i] [1]) &&
			 (l->node [1]->nodetype == linkcheck [i] [0]))    )
			break ;
		}
		if (i >= NTAB (linkcheck))
		{
		    inconsistency ("Link between incompatible node types ('%s' and '%s')",
				l->node [0]->name, l->node [1]->name) ;
		}
	    }
	}

	vlan_set (n->vlanset, 0) ;
    }
}


