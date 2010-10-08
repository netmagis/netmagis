/*
 * $Id$
 */

#include "graph.h"

void print_vlanlist (FILE *fp, vlanset_t vs, int desc)
{
    vlan_t v ;
    char *p ;
    struct vlan *tab ;

    tab = mobj_data (vlanmobj) ;
    for (v = 0 ; v < MAXVLAN ; v++)
    {
	if (vlan_isset (vs, v))
	{
	    if (desc)
	    {
		fprintf (fp, " {%d ", v) ;
		p = tab [v].name ;
		if (p == NULL)
		    p = "-" ;
		fprintf (fp, "%s}", p) ;
	    }
	    else fprintf (fp, " %d ", v) ;
	}
    }
}
