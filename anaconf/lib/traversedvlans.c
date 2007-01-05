/*
 * $Id: traversedvlans.c,v 1.1.1.1 2007-01-05 15:12:00 pda Exp $
 */

#include "graph.h"

void traversed_vlans (vlanset_t vs)
{
    struct node *n ;

    vlan_zero (vs) ;
    for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
	if (n->nodetype == NT_L2 && (n->mark & MK_L2TRANSPORT))
	    vlan_set (vs, n->u.l2.vlan) ;
}
