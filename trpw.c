/*
 * $Id: trpw.c,v 1.2 2007-02-27 13:04:48 pda Exp $
 *
 * trpw.c
 *
 * A partir d'un mot de passe en clair, calcule le mot de passe crypte
 * a mettre dans /etc/passwd.
 *
 * Syntaxe de la commande :
 *	trpw <mot de passe en clair>
 *	Renvoie sur la sortie standard le mot de passe crypte a mettre
 *	directement dans /etc/passwd.
 *
 * Syntaxe de la fonction C "trpw" :
 *	char *trpw (char *mot_de_passe_en_clair)
 * 	Renvoie le mot de passe crypte a mettre directement
 *	dans /etc/passwd.
 *
 * Historique :
 * - 91/10/22 : pda@masi.ibp.fr
 *	codage a partir de passwd de BSD4.3 Tahoe
 */

#include <stdio.h>

#ifdef	BSD
#   define	rand	random
#   define	srand	srandom
#endif

/*
 * main
 */

main (argc, argv)
int argc ;
char *argv [] ;
{
    extern char *trpw () ;

    if (argc != 2)
    {
	fprintf (stderr, "usage: %s mot-de-passe\n", argv [0]) ;
	exit (1) ;
    }

    puts (trpw (argv [1])) ;

    exit (0) ;
}

/*
 * trpw
 */

char *trpw (clair)
char *clair ;
{
    char sel [2] ;
    char *crypt () ;

    /*
     * Initialise le generateur de nombres aleatoires de telle facon
     * que le mot de passe crypte depende de l'heure.
     */

    srand ((unsigned int) time ((long *) 0)) ;

    /*
     * Le "sel" de l'algorithme de cryptage doit etre une sequence
     * de deux caracteres imprimables (et non ':' pour des raisons
     * evidentes...).
     */

    while ((sel [0] = rand () % 93 + 33) == ':')
	;
    while ((sel [1] = rand () % 93 + 33) == ':')
	;

    /*
     * Le mot de passe peut maintenant etre crypte avec le sel.
     * En final, on a :
     * - deux caracteres pour le sel (en clair)
     * - onze caracteres pour le mot de passe proprement dit
     */

    return crypt (clair, sel) ;
}
