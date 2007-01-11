/*
 * $Id: traversedvlans.c,v 1.2 2007-01-11 15:31:22 pda Exp $
 */

#include "graph.h"

void traversed_vlans (vlanset_t vs)
{
    struct node *n ;

    vlan_zero (vs) ;
    for (n = mobj_head (nodemobj) ; n != NULL ; n = n->next)
	if (n->nodetype == NT_L2 && MK_ISSET (n, MK_L2TRANSPORT))
	    vlan_set (vs, n->u.l2.vlan) ;
}
