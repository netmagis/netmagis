/*
 * $Id: dumpgraph.c,v 1.1.1.1 2007-01-05 15:12:00 pda Exp $
 */

#include "graph.h"

MOBJ *mobjlist [NB_MOBJ] ;

int main (int argc, char *argv [])
{
    bin_read (stdin, mobjlist) ;
    text_write (stdout) ;
    exit (0) ;
}
