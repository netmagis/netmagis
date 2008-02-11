/*
 * $Id: base.c,v 1.3 2008-02-11 14:50:53 pda Exp $
 *
 * Copyright (c) 1998-1999
 *	Pierre David
 *
 * History
 *   1998/06/06 : design
 *   1999/07/26 : active characters
 *   1999/08/30 : keep position in the buffer and simplification of insert
 *   1999/09/07 : debug
 *   1999/09/08 : keep old positions until reset
 *
 */

#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <sys/times.h>

#include <tcl.h>

typedef unsigned char unschar ;

/* maximum length of a macro name */
#define	MAX_MACRO	100
/* prefix to be added in front of macro names */
#define	PREFIX_MACRO	"htg_"

#define	OPENINGBRACE	'{'
#define	CLOSINGBRACE	'}'

#define	NTAB(t)	(sizeof t / sizeof (t[0]))

/*
 * Global variables
 */

struct position
{
    char *filename ;
    unschar *buffer ;
    unschar *curptr ;
    int lineno ;
    struct position *next ;
} ;

struct
{
    /*
     * Position management
     */

    struct position *pos ;

    /*
     * In order to keep malloced strings
     */

    struct position *oldpos ;

    /*
     * Active characters
     * Each character points to a TCL script which is evaluated each
     * time the characters occurs in the text.
     */

    char *actchar [256] ;
} htgctxt ;

/******************************************************************************
Command "htg reset"
******************************************************************************/

void free_position_list (struct position *head)
{
    if (head != NULL)
    {
	struct position *tmp ;

	tmp = head->next ;
	free (head->filename) ;
	free (head->buffer) ;
	free (head) ;
	head = tmp ;
    }
}

void reset_ctxt (int all)
{
    int i ;

    /*
     * Free all position buffer
     */

    free_position_list (htgctxt.pos) ;
    htgctxt.pos = NULL ;

    free_position_list (htgctxt.oldpos) ;
    htgctxt.oldpos = NULL ;

    if (all)
    {
	for (i = 0 ; i < 255 ; i++)
	{
	    if (htgctxt.actchar [i] != NULL)
		free (htgctxt.actchar [i]) ;
	    htgctxt.actchar [i] = NULL ;
	}
    }
}

int HTG_Reset (Tcl_Interp *interp, int argc, char *argv [])
{
    int all ;

    if (argc == 1)
    {
	all = 0 ;
    }
    else if (argc == 2 && strcmp (argv [1], "all") == 0)
    {
	all = 1 ;
    }
    else
    {
	interp->result = "wrong # args: should be htg reset ?all?" ;
	return TCL_ERROR ;
    }

    reset_ctxt (all) ;
    return TCL_OK ;
}

/******************************************************************************
Command "htg insert"
******************************************************************************/

char *malloc_string (char *string)
{
    int len ;
    char *p ;

    len = strlen (string) ;
    p = malloc (len + 1) ;
    if (p != NULL)
	strcpy (p, string) ;
    return p ;
}

int HTG_Insert (Tcl_Interp *interp, int argc, char *argv [])
{
    char *arg_string, *arg_filename, *arg_lineno ;
    int lineno ;
    struct position *pos ;

    if (argc != 4)
    {
	interp->result = "wrong # args: should be htg insert string filename lineno" ;
	return TCL_ERROR ;
    }

    arg_string   = argv [1] ;
    arg_filename = argv [2] ;
    arg_lineno   = argv [3] ;

    if (Tcl_GetInt (interp, arg_lineno, &lineno) != TCL_OK)
	return TCL_ERROR ;

    /*
     * Prepare a new position element
     */

    pos = (struct position *) malloc (sizeof *pos) ;
    if (pos == NULL)
    {
	interp->result = "cannot allocate new position element" ;
	return TCL_ERROR ;
    }

    pos->filename = malloc_string (arg_filename) ;
    if (pos->filename == NULL)
    {
	free (pos) ;
	interp->result = "cannot allocate new file name" ;
	return TCL_ERROR ;
    }

    pos->buffer = (unschar *) malloc_string (arg_string) ;
    if (pos->buffer == NULL)
    {
	free (pos) ;
	free (pos->filename) ;
	interp->result = "cannot allocate new string" ;
	return TCL_ERROR ;
    }
    pos->curptr = pos->buffer ;

    pos->lineno = lineno ;

    /*
     * Insert this element in position stack
     */

    pos->next = htgctxt.pos ;
    htgctxt.pos = pos ;

    /*
     * That's all, folks !
     */

    interp->result = "" ;
    return TCL_OK ;
}


/******************************************************************************
Command "htg getnext"
******************************************************************************/

int error (Tcl_Interp *interp, char *msg, char *filename, int lineno)
{
    char tmp [1000], *p ;

    p = tmp ;
    if (strcmp (interp->result, "") != 0)
	*p++ = '\n' ;
    sprintf (p, "%s(%d): %s", filename, lineno, msg) ;
    Tcl_AppendResult (interp, tmp, NULL) ;
    return TCL_ERROR ;
}

void remove_position (void)
{
    struct position *tmp ;

    tmp = htgctxt.pos ;
    htgctxt.pos = tmp->next ;

    tmp->next = htgctxt.oldpos ;
    htgctxt.oldpos = tmp ;
}

unschar current_char (void)
{
    unschar c ;

    if (htgctxt.pos == NULL)
    {
	c = '\0' ;
    }
    else if (*htgctxt.pos->curptr == '\0')
    {
	remove_position () ;
	c = current_char () ;
    }
    else
    {
	c = *htgctxt.pos->curptr ;
    }
    return c ;
}

void advance_char (void)
{
    if (htgctxt.pos != NULL)
    {
	if (*htgctxt.pos->curptr == '\0')
	{
	    remove_position () ;
	    advance_char () ;
	}
	else
	{
	    if (*htgctxt.pos->curptr == '\n')
		htgctxt.pos->lineno++ ;
	    htgctxt.pos->curptr++ ;
	}
    }
}

void macro_name (char *name, int maxlen)
{
    unschar c ;
    int len ;

    len = 0 ;
    while ((c = current_char ()) != '\0' && isalnum (c))
    {
	if (len < maxlen)
	    name [len++] = c ;
	advance_char () ;
    }
    name [len] = '\0' ;
}

void skip_rest_of_line (void)
{
    unschar c ;

    while ((c = current_char ()) != '\0' && c != '\n')
	advance_char () ;
}

void skip_space (void)
{
    unschar c ;

    while ((c = current_char ()) != '\0' && isspace (c))
	advance_char () ;

    if (c == '\\' && *(htgctxt.pos->curptr + 1) == '*')
    {
	skip_rest_of_line () ;
	skip_space () ;
    }
}

int normal_char (Tcl_Interp *interp, unschar c)
{
    interp->result [0] = c ;
    interp->result [1] = '\0' ;
    advance_char () ;

    return TCL_OK ;
}

int engine (Tcl_Interp *interp)
{
    int rcode ;
    int cc ;

    char *orgfile ;
    int orglineno ;

    orgfile = htgctxt.pos->filename ;
    orglineno = htgctxt.pos->lineno ;

    cc = current_char () ;

    if (cc == '\0')
    {
	interp->result = "" ;
	rcode = TCL_OK ;
    }
    else if (cc == '\\')
    {
	advance_char () ;

	orgfile = htgctxt.pos->filename ;
	orglineno = htgctxt.pos->lineno ;

	cc = current_char () ;
	if (isalpha (cc))
	{
	    char macro [MAX_MACRO + sizeof PREFIX_MACRO], *pmacro ;
	    Tcl_CmdInfo info ;

	    strcpy (macro, PREFIX_MACRO) ;
	    pmacro = macro + sizeof PREFIX_MACRO - 1 ;
	    macro_name (pmacro, MAX_MACRO) ;
	    if (Tcl_GetCommandInfo (interp, macro, &info))
	    {
		rcode = Tcl_Eval (interp, macro) ;
		if (rcode != TCL_OK)
		{
		    char tmp [100 + MAX_MACRO] ;

		    sprintf (tmp, "Error in '\\%s' analysis", pmacro) ;
		    (void) error (interp, tmp, orgfile, orglineno) ;
		}
	    }
	    else
	    {
		char tmp [100 + MAX_MACRO] ;

		sprintf (tmp, "Unknown directive '\\%s'", pmacro) ;
		rcode = error (interp, tmp, orgfile, orglineno) ;
	    }
	}
	else if (cc == '*')
	{
	    skip_rest_of_line () ;
	    rcode = engine (interp) ;
	}
	else 
	    rcode = normal_char (interp, cc) ;
    }
    else if (cc == OPENINGBRACE)
    {
	Tcl_DString resultat ; 

	Tcl_DStringInit (&resultat) ;
	advance_char () ;
	rcode = TCL_OK ;

	while (rcode == TCL_OK &&
		(cc = current_char ()) != '\0' && cc != CLOSINGBRACE)
	{
	    rcode = engine (interp) ;
	    if (rcode == TCL_ERROR)
		Tcl_DStringFree (&resultat) ;
	    else Tcl_DStringAppend (&resultat, interp->result, -1) ;
	}
	if (rcode == TCL_OK)
	{
	    cc = current_char () ;
	    if (cc == '\0')
	    {
		Tcl_DStringFree (&resultat) ;
		Tcl_ResetResult (interp) ;
		rcode = error (interp, "Missing closing curly brace",
			 orgfile, orglineno) ;
	    }
	    else
	    {
		advance_char () ;
		Tcl_DStringResult (interp, &resultat) ;
		rcode = TCL_OK ;		/* not useful here */
	    }
	}
    }
    else if (cc == CLOSINGBRACE)
    {
	rcode = error (interp, "Unexpected closing curly brace",
		 orgfile, orglineno) ;
    }
    else if (htgctxt.actchar [cc] != NULL)
    {
	advance_char () ;
	rcode = Tcl_Eval (interp, htgctxt.actchar [cc]) ;
	if (rcode != TCL_OK)
	{
	    char tmp [100 + MAX_MACRO] ;

	    sprintf (tmp, "Error in analysis of char '%c'", cc) ;
	    (void) error (interp, tmp, orgfile, orglineno) ;
	}
    }
    else
	rcode = normal_char (interp, cc) ;

    return rcode ;
}

int HTG_Getnext (Tcl_Interp *interp, int argc, char *argv [])
{
    int r ;

    if (argc != 1)
    {
	interp->result = "wrong # args: should be htg getnext" ;
	return TCL_ERROR ;
    }

    Tcl_ResetResult (interp) ;

    skip_space () ;
    r = engine (interp) ;
    return r ;
}

/******************************************************************************
Command "htg position"
******************************************************************************/

int HTG_Position (Tcl_Interp *interp, int argc, char *argv [])
{
    if (argc != 1)
    {
	interp->result = "wrong # args: should be htg position" ;
	return TCL_ERROR ;
    }

    Tcl_ResetResult (interp) ;

    /*
     * In order for positions to be precise, we must skip spaces
     * If we don't skip spaces, we get position of last analysed
     * string (which may be at the end of an included file for
     * example).
     */

    skip_space () ;

    if (htgctxt.pos != NULL)
    {
	char tmp [100] ;

	Tcl_AppendElement (interp, htgctxt.pos->filename) ;
	sprintf (tmp, "%d", htgctxt.pos->lineno) ;
	Tcl_AppendElement (interp, tmp) ;
    }

    return TCL_OK ;
}

/******************************************************************************
Command "htg getdate"
******************************************************************************/

int HTG_Getdate (Tcl_Interp *interp, int argc, char *argv [])
{
    FILE *fp ;
    struct stat stbuf ;
    char filedate [100] ;

    if (argc != 2)
    {
	interp->result = "wrong # args: should be htg getdate channelId" ;
	return TCL_ERROR ;
    }

    if (Tcl_GetOpenFile (interp, argv [1], 0, 0, (ClientData *) &fp) != TCL_OK)
	return TCL_ERROR ;

    if (fstat (fileno (fp), &stbuf) == -1)
    {
	interp->result = "cannot stat file" ;
	return TCL_ERROR ;
    }

    sprintf (filedate, "%ld", (unsigned long int) stbuf.st_mtime) ;
    Tcl_SetResult (interp, filedate, TCL_VOLATILE) ;

    return TCL_OK ;
}

/******************************************************************************
Command "htg defchar"
******************************************************************************/

int HTG_Defchar (Tcl_Interp *interp, int argc, char *argv [])
{
    int c ;

    if (argc != 3)
    {
	interp->result = "wrong # args: should be htg defchar char cmd" ;
	return TCL_ERROR ;
    }

    if (strlen (argv [1]) != 1)
    {
	interp->result = "must give a char" ;
	return TCL_ERROR ;
    }

    c = (unschar) (*argv [1]) ;

    if (htgctxt.actchar [c] != NULL)
	free (htgctxt.actchar [c]) ;

    htgctxt.actchar [c] = malloc (strlen (argv [2] + 1)) ;
    if (htgctxt.actchar [c] == NULL)
    {
	interp->result = "not enough memory" ;
	return TCL_ERROR ;
    }
    strcpy (htgctxt.actchar [c], argv [2]) ;

    Tcl_SetResult (interp, argv [1], TCL_VOLATILE) ;

    return TCL_OK ;
}

/******************************************************************************
Driver procedure
******************************************************************************/

int HTG_Cmd (ClientData clientdata, Tcl_Interp *interp,
						int argc, char *argv [])
{
    static struct
    {
	char *command ;
	int (*procedure) (Tcl_Interp *, int, char * []) ;
    } optable [] =
    {
	{ "reset",    HTG_Reset   , },
	{ "insert",   HTG_Insert  , },
	{ "position", HTG_Position, },
	{ "getnext",  HTG_Getnext , },
	{ "getdate",  HTG_Getdate , },
	{ "defchar",  HTG_Defchar , },
    } ;
    int i, r ;

    for (i = 0 ; i < NTAB (optable) ; i++)
    {
	if (strcmp (argv [1], optable [i].command) == 0)
	{
	    r = (*optable [i].procedure) (interp, argc - 1, argv + 1) ;
	    break ;
	}
    }

    if (i >= NTAB (optable))			/* not found */
    {
	char tmp [200] ;

	sprintf (tmp, "bad option \"%s\": should be ", argv [1]) ;
	for (i = 0 ; i < NTAB (optable) ; i++)
	{
	    if (i != 0)
		strcat (tmp, ", ") ;
	    strcat (tmp, optable [i].command) ;
	}
	Tcl_SetResult (interp, tmp, TCL_VOLATILE) ;
	r = TCL_ERROR ;
    }

    return r ;
}


/******************************************************************************
Initialization procedure
******************************************************************************/

int HTG_Init (Tcl_Interp *interp)
{
    Tcl_CreateCommand (interp, "htg",
		(Tcl_CmdProc *) HTG_Cmd,
		(ClientData) NULL,
		(Tcl_CmdDeleteProc *) NULL) ;

    return TCL_OK ;
}
