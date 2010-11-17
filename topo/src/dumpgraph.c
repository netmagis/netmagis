/*
 */

#include "graph.h"

MOBJ *mobjlist [NB_MOBJ] ;

void usage (char *progname)
{
    fprintf (stderr, "Usage : %s [-n cidr|-e regexp|-E regexp]*\n", progname) ;
    exit (1) ;
}

int main (int argc, char *argv [])
{
    char *prog ;
    int c, err ;
    int allow_deny ;

    /*
     * First loop to build selection specifiers from arguments
     */

    prog = argv [0] ;
    err = 0 ;

    sel_init () ;

    while ((c = getopt (argc, argv, "n:e:E:")) != -1) {
	switch (c)
	{
	    case 'n' :
		if (! sel_network (optarg))
		{
		    fprintf (stderr, "%s: '%s' is not a valid cidr\n", prog, optarg) ;
		    err = 1 ;
		}
		break ;
	    case 'e' :
	    case 'E' :
		allow_deny = (c == 'e') ;
		if (! sel_regexp (optarg, allow_deny))
		{
		    fprintf (stderr, "%s: '%s' is not a valid regexp\n", prog, optarg) ;
		    err = 1 ;
		}
		break ;
	    case '?' :
	    default :
		usage (prog) ;
	}
    }

    if (err)
	exit (1) ;

    argc -= optind ;
    argv += optind ;

    if (argc != 0)
	usage (prog) ;

    /*
     * Read the graph, select a subgraph adn output the final result
     */

    bin_read (stdin, mobjlist) ;
    sel_mark () ;
    text_write (stdout) ;

    sel_end () ;
    exit (0) ;
}
