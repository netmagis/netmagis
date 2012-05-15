/*
 */

#include "graph.h"


/******************************************************************************
Output format

    vlan <id> <desc-en-hexa>
    iface <eq> <if> <vlan-id> <ip>
    vrrp <vlan-id> <ip>

Example of output format

    vlan 5 41424344454647
    iface crc-rc1 ge-0/0/0 5 172.16.201.253
    vrrp 5 172.16.201.254

******************************************************************************/


struct vrrpdone
{
    ip_t network ;			/* network address (with prefix) */
    int nref ;				/* number of refs to this network */
    struct vrrpdone *next ;
} ;

struct vrrpdone *vrrplist = NULL ;

void output_vlans (FILE *fp)
{
    vlan_t v ;
    struct vlan *tab ;

    tab = mobj_data (vlanmobj) ;
    for (v = 0 ; v < MAXVLAN ; v++)
    {
	char *p ;

	p = tab [v].name ;
	if (p == NULL)
	    p = "-" ;
	fprintf (fp, "vlan %d %s\n", v, p) ;
    }
}

int is_vrrpdone (ip_t *net)
{
    struct vrrpdone *p ;

    p = vrrplist ;
    while (p != NULL)
    {
	if (ip_match (net, &p->network, 1))
	{
	    p->nref++ ;
	    return 1 ;
	}
	p = p->next ;
    }
    p = malloc (sizeof *p) ;
    if (p == NULL)
	error (1, "Cannot malloc memory for a VRRP address in a network") ;
    p->network = *net ;
    p->nref = 1 ;
    p->next = vrrplist ;
    vrrplist = p ;
    return 0 ;
}

void output_ifaces (FILE *fp)
{
    struct rnet *n ;
    iptext_t addr ;

    for (n = mobj_head (rnetmobj) ; n != NULL ; n = n->next)
    {
	if (n->vrrpaddr.preflen > 0)
	{
	    if (! is_vrrpdone (&n->net->addr))
	    {
		iptext_t vrrpaddr ;

		ip_ntop (&n->vrrpaddr, vrrpaddr, 0) ;
		fprintf (fp, "vrrp %d %s\n", n->l2->u.l2.vlan, vrrpaddr) ;
	    }
	}
	/* iface <eq> <if> <vlan-id> <ip> */
	ip_ntop (&n->l3->u.l3.addr, addr, 0) ;
	fprintf (fp, "iface %s %s %d %s\n",
			n->l1->eq->name,
			n->l1->u.l1.ifname,
			n->l2->u.l2.vlan,
			addr) ;
    }
}

void check_vrrp (void)
{
    struct vrrpdone *p ;

    p = vrrplist ;
    while (p != NULL)
    {
	if (p->nref == 1)
	{
	    iptext_t addr ;

	    ip_ntop (&p->network, addr, 1) ;
	    fprintf (stderr, "Network '%s' is configured for VRRP, but with only one router\n", addr) ;
	}
	p = p->next ;
    }
}

/******************************************************************************
Main function
******************************************************************************/

MOBJ *mobjlist [NB_MOBJ] ;

int main (int argc, char *argv [])
{
    if (argc != 1)
    {
	fprintf (stderr, "Usage : %s\n", argv [0]) ;
	exit (1) ;
    }

    /*
     * Read the graph
     */

    bin_read (stdin, mobjlist) ;

    /*
     * Output vlan list
     */

    output_vlans (stdout) ;

    /*
     * Extract all interfaces which are on an IP network
     */

    output_ifaces (stdout) ;

    /*
     * Check VRRP networks with only one router
     */

    check_vrrp () ;

    exit (0) ;
}
