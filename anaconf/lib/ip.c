/*
 * $Id: ip.c,v 1.2 2007-01-09 10:46:10 pda Exp $
 */

#include "graph.h"

#include <arpa/inet.h>

/******************************************************************************
IP address functions
******************************************************************************/

/*
 * Returns 0 (error) or 1 (ok)
 */

int ip_pton (char *text, ip_t *cidr)
{
    int r ;
    char *p ;
    char addr [IPADDRLEN] ;

    r = 1 ;

    strncpy (addr, text, sizeof addr) ;
    p = strchr (addr, '/') ;
    if (p == NULL)
	cidr->preflen = -1 ;
    else
    {
	*p = '\0' ;
	cidr->preflen = atoi (p + 1) ;
    }

    switch (inet_pton (AF_INET6, addr, &cidr->u.adr6))
    {
	case -1 :			/* system error */
	    r = 0 ;
	    break ;
	case 0 :			/* not parseable with AF_INET6 */
	    switch (inet_pton (AF_INET, addr, &cidr->u.adr4))
	    {
		case -1 :		/* system error */
		    r = 0 ;
		    break ;
		case 0 :		/* not parseable with AF_INET */
		    r = 0 ;
		    break ;
		case 1 :		/* Ok with AF_INET */
		    if (cidr->preflen < 0)
			cidr->preflen = 32 ;
		    else if (cidr->preflen > 32)
			r = 0 ;
		    cidr->family = AF_INET ;
		    break ;
		default :		/* not possible... */
		    r = 0 ;
		    break ;
	    }
	    break ;
	case 1 :			/* Ok with AF_INET6 */
	    if (cidr->preflen < 0)
		cidr->preflen = 128 ;
	    else if (cidr->preflen > 128)
		r = 0 ;
	    cidr->family = AF_INET6 ;
	    break ;
	default :			/* not possible... */
	    r = 0 ;
	    break ;
    }

    if (p != NULL)
	*p = '/' ;		/* leave input string the same as before */

    return r ;
}

int ip_ntop (ip_t *cidr, iptext_t text, int prefix)
{
    const char *p ;
    int l ;
    int size ;

    size = sizeof (iptext_t) ;
    switch (cidr->family)
    {
	case AF_INET :
	    p = inet_ntop (AF_INET, &cidr->u.adr4, text, size) ;
	    break ;
	case AF_INET6 :
	    p = inet_ntop (AF_INET6, &cidr->u.adr6, text, size) ;
	    break ;
	default :
	    p = NULL ;
	    break ;
    }

    l = strlen (text) ;
    if (p != NULL && prefix && l + 4 < size)
	sprintf (text + l, "/%d", cidr->preflen) ;

    return p != NULL ;
}

int ip_equal (ip_t *adr1, ip_t *adr2)
{
    int r ;

    r = 0 ;
    if (adr1->family == adr2->family && adr1->preflen == adr2->preflen)
    {
	switch (adr1->family)
	{
	    case AF_INET :
		r = ! bcmp (&adr1->u.adr4, &adr2->u.adr4, sizeof adr1->u.adr4) ;
		break ;
	    case AF_INET6 :
		r = ! bcmp (&adr1->u.adr6, &adr2->u.adr6, sizeof adr1->u.adr6) ;
		break ;
	}
    }

    return r ;
}


/*
 * Inspired from bitncmp (ISC)
 *
 * Copyright (c) 1996,1999 by Internet Software Consortium.
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND INTERNET SOFTWARE CONSORTIUM DISCLAIMS
 * ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL INTERNET SOFTWARE
 * CONSORTIUM BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL
 * DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR
 * PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS
 * ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS
 * SOFTWARE.
 */

int prefix_match (void *adr, void *cidr, int preflen)
{
    unsigned int lb, rb;
    int x, b;

    b = preflen / 8 ;
    x = memcmp (adr, cidr, b);
    if (x == 0)
    {
	lb = ((unsigned char *) adr) [b] ;
	rb = ((unsigned char *) cidr) [b] ;
	for (b = preflen % 8 ; b > 0 ; b--)
	{
	    if ((lb & 0x80) != (rb & 0x80)) {
		if (lb & 0x80)
		    x = 1 ;
		else x = -1 ;
		break ;
	    }
	    lb <<= 1 ;
	    rb <<= 1 ;
	}
    }
    return x ;
}

/*
 * Match the given address with the network address.
 * Each address has a prefix len inside.
 * The "prefix" parameter tells if the adress prefix length
 * must be tested (1) or ignored (0) for the comparison.
 */

int ip_match (ip_t *adr, ip_t *network, int prefix)
{
    int r ;

    if (adr->family != network->family)
	return 0 ;

    if (prefix && adr->preflen < network->preflen)
	return 0 ;

    switch (network->family)
    {
	case AF_INET :
	    r = prefix_match (&adr->u.adr4, &network->u.adr4, network->preflen) ;
	    break ;
	case AF_INET6 :
	    r = prefix_match (&adr->u.adr6, &network->u.adr6, network->preflen) ;
	    break ;
	default :
	    r = 1 ;
	    break ;
    }

    return r == 0 ;
}

void ip_netof (ip_t *srcadr, ip_t *dstadr)
{
    unsigned char *s, *d ;
    unsigned int o, b, mask ;

    bzero (dstadr, sizeof *dstadr) ;

    dstadr->family = srcadr->family ;
    dstadr->preflen = srcadr->preflen ;

    s = (srcadr->family == AF_INET) ?
			    (unsigned char *) &srcadr->u.adr4 :
			    (unsigned char *) &srcadr->u.adr6 ;
    d = (dstadr->family == AF_INET) ?
			    (unsigned char *) &dstadr->u.adr4 :
			    (unsigned char *) &dstadr->u.adr6 ;

    b = srcadr->preflen ;
    o = 0 ;
    while (b)
    {
	if (b >= 8)
	{
	    mask = 0xff ;
	    b -= 8 ;
	}
	else
	{
	    mask = 0xff << (8 - b) ;
	    b = 0 ;
	}
	d [o] = s [o] & mask ;
	o++ ;
    }
}
