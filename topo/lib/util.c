/*
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

/******************************************************************************
Append to a string :
Append string "a" to string "old", free "old" and return a new pointer
******************************************************************************/
char *append(char *old, char *a)
{
    size_t oldsize = 0, asize = 0, newlen =0;
    char *new;

    if(old != NULL)
    {
	oldsize = strlen(old) ;
    }
    if(a != NULL)
    {
	asize = strlen(a) ;
    }

    /* provide space for final '\0' */
    newlen = oldsize + asize + sizeof(char);
    new = malloc(newlen);

    bzero(new, newlen);
    memcpy(new, old, oldsize);
    memcpy(new + oldsize, a, asize + sizeof(char));

    free(old);

    return new;
}

