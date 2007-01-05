/*
 * $Id: util.c,v 1.1.1.1 2007-01-05 15:12:00 pda Exp $
 */

#include "graph.h"

#include <stdarg.h>

/******************************************************************************
Utility functions
******************************************************************************/

int errorstate = 0 ;
int lineno = -1 ;

void error (int syserr, char *msg)
{
    if (syserr)
	perror (msg) ;
    else
    {
	fprintf (stderr, "%s\n", msg) ;
    }
    exit (1) ;
}

void inconsistency (char *fmt, ...)
{
    va_list ap ;

    va_start (ap, fmt) ;

    fprintf (stderr, "Inconsistency: ") ;
    if (lineno > 0)
	fprintf (stderr, "(line %d) ", lineno) ;
    vfprintf (stderr, fmt, ap) ;
    fprintf (stderr, "\n") ;

    va_end (ap) ;
    errorstate = 1 ;
}
