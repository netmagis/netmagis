/*
 * $Id: printvlans.c,v 1.1.1.1 2007-01-05 15:12:00 pda Exp $
 */

#include "graph.h"

void print_vlanlist (FILE *fp, vlanset_t vs)
{
    vlan_t v ;
    char *p ;

    for (v = 0 ; v < MAXVLAN ; v++)
    {
	if (vlan_isset (vs, v))
	{
	    fprintf (fp, " {%d ", v) ;

	    p = vlandesc [v] ;
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

	    fprintf (fp, "}") ;
	}
    }
}
