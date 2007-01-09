/*
 * $Id: printvlans.c,v 1.2 2007-01-09 10:46:10 pda Exp $
 */

#include "graph.h"

void print_vlanlist (FILE *fp, vlanset_t vs)
{
    vlan_t v ;
    char *p ;
    struct vlan *tab ;

    tab = mobj_data (vlanmobj) ;
    for (v = 0 ; v < MAXVLAN ; v++)
    {
	if (vlan_isset (vs, v))
	{
	    fprintf (fp, " {%d ", v) ;

	    p = tab [v].name ;
#ifdef OLD
	    if (p != NULL)
	    {
		while (*p != '\0')
		{
		    if (*p == '{' || *p == '}')
			fputc ('\\', fp) ;
		    fputc (*p, fp) ;
		    p++ ;
		}
	    }
	    else fprintf (fp, "(no description)") ;
#else
	    if (p == NULL)
		p = "-" ;
#endif

	    fprintf (fp, "}") ;
	}
    }
}
