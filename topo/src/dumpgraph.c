/*
 */

#include "graph.h"

MOBJ *mobjlist [NB_MOBJ] ;

void usage (char *progname)
{
    fprintf (stderr, "Usage : %s [-a|-n cidr|-e regexp|-E regexp|-t|-m]* [-o obj]\n", progname) ;
    exit (1) ;
}

int main (int argc, char *argv [])
{
    char *prog, *errstr ;
    int c, err ;
    char *object ;

    /*
     * First loop to build selection specifiers from arguments
     */

    prog = argv [0] ;
    err = 0 ;
    object = NULL ;

    sel_init () ;

    while ((c = getopt (argc, argv, "an:e:E:tmo:")) != -1)
    {
	switch (c)
	{
	    case 'a' :
	    case 'n' :
	    case 'e' :
	    case 'E' :
	    case 't' :
	    case 'm' :
		if ((errstr = sel_register (c, optarg)) != NULL)
		{
		    fprintf (stderr, "%s: %s\n", prog, errstr) ;
		    err = 1 ;
		}
		break ;
	    case 'o':
		object = optarg ;
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
    text_write (stdout, object) ;

    sel_end () ;
    exit (0) ;
}
