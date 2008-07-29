/*
 * $Id: relabs.c,v 1.7 2008-07-29 12:54:03 pda Exp $
 */

#include "graph.h"

#define	CONVABS(idx,base)	(((int)(idx))==-1 ? NULL : ((int)(idx))+(base))
#define	RELTOABS(ptr,base)	((ptr)= CONVABS ((ptr), (base)))
#define	PROLOGABS(m,d,base)	\
	do { \
	    m = mobj_count (d) ; \
	    mobj_sethead ((d), CONVABS (mobj_head (d), (base))) ; \
	} while (0)


void rel_to_abs (MOBJ *graph [])
{
    int i, max ;

    struct symtab **hashtab 	= mobj_data (graph [HASHMOBJIDX]) ;
    struct symtab *symtab	= mobj_data (graph [SYMMOBJIDX]) ;
    char *strtab		= mobj_data (graph [STRMOBJIDX]) ;
    struct node *nodetab	= mobj_data (graph [NODEMOBJIDX]) ;
    struct link *linktab	= mobj_data (graph [LINKMOBJIDX]) ;
    struct linklist *llisttab	= mobj_data (graph [LLISTMOBJIDX]) ;
    struct eq *eqtab		= mobj_data (graph [EQMOBJIDX]) ;
    struct vlan *vlantab	= mobj_data (graph [VLANMOBJIDX]) ;
    struct network *nettab	= mobj_data (graph [NETMOBJIDX]) ;
    struct netlist *nlisttab	= mobj_data (graph [NLISTMOBJIDX]) ;
    struct lvlan *lvlantab	= mobj_data (graph [LVLANMOBJIDX]) ;
    struct rnet *rnettab	= mobj_data (graph [RNETMOBJIDX]) ;
    struct route *routetab	= mobj_data (graph [ROUTEMOBJIDX]) ;
    struct ssid *ssidtab	= mobj_data (graph [SSIDMOBJIDX]) ;
    struct ssidprobe *ssidprobetab = mobj_data (graph [SSIDPROBEMOBJIDX]) ;

    PROLOGABS (max, graph [HASHMOBJIDX], hashtab) ;
    for (i = 0 ; i < max ; i++)
    {
	RELTOABS (hashtab [i], symtab) ;
    }

    PROLOGABS (max, graph [SYMMOBJIDX], symtab) ;
    for (i = 0 ; i < max ; i++)
    {
	RELTOABS (symtab [i].name, strtab) ;
	RELTOABS (symtab [i].node, nodetab) ;
	RELTOABS (symtab [i].link, linktab) ;
	RELTOABS (symtab [i].next, symtab) ;
    }

    PROLOGABS (max, graph [STRMOBJIDX], strtab) ;
    /* nothing for strmobj */

    PROLOGABS (max, graph [SSIDMOBJIDX], ssidtab) ;
    for (i = 0 ; i < max ; i++)
    {
	RELTOABS (ssidtab [i].name, strtab) ;
	RELTOABS (ssidtab [i].next, ssidtab) ;
    }

    PROLOGABS (max, graph [EQMOBJIDX], eqtab) ;
    for (i = 0 ; i < max ; i++)
    {
	RELTOABS (eqtab [i].name, strtab) ;
	RELTOABS (eqtab [i].type, strtab) ;
	RELTOABS (eqtab [i].model, strtab) ;
	RELTOABS (eqtab [i].snmp, strtab) ;
	RELTOABS (eqtab [i].location, strtab) ;
	RELTOABS (eqtab [i].next, eqtab) ;
    }

    PROLOGABS (max, graph [NODEMOBJIDX], nodetab) ;
    for (i = 0 ; i < max ; i++)
    {
	RELTOABS (nodetab [i].name, strtab) ;
	RELTOABS (nodetab [i].eq, eqtab) ;
	RELTOABS (nodetab [i].next, nodetab) ;
	RELTOABS (nodetab [i].linklist, llisttab) ;

	switch (nodetab [i].nodetype)
	{
	    case NT_L1 :
		RELTOABS (nodetab [i].u.l1.ifname, strtab) ;
		RELTOABS (nodetab [i].u.l1.ifdesc, strtab) ;
		RELTOABS (nodetab [i].u.l1.link, strtab) ;
		RELTOABS (nodetab [i].u.l1.stat, strtab) ;
		RELTOABS (nodetab [i].u.l1.radio.ssid, ssidtab) ;
		break ;
	    case NT_L2 :
		RELTOABS (nodetab [i].u.l2.stat, strtab) ;
		break ;
	    case NT_ROUTER :
		RELTOABS (nodetab [i].u.router.name, strtab) ;
		break ;
	    default :
		break ;
	}
    }

    PROLOGABS (max, graph [LINKMOBJIDX], linktab) ;
    for (i = 0 ; i < max ; i++)
    {
	RELTOABS (linktab [i].name, strtab) ;
	RELTOABS (linktab [i].node [0], nodetab) ;
	RELTOABS (linktab [i].node [1], nodetab) ;
    }

    PROLOGABS (max, graph [LLISTMOBJIDX], llisttab) ;
    for (i = 0 ; i < max ; i++)
    {
	RELTOABS (llisttab [i].link, linktab) ;
	RELTOABS (llisttab [i].next, llisttab) ;
    }

    PROLOGABS (max, graph [NETMOBJIDX], nettab) ;
    for (i = 0 ; i < max ; i++)
    {
	RELTOABS (nettab [i].next, nettab) ;
    }

    PROLOGABS (max, graph [NLISTMOBJIDX], nlisttab) ;
    for (i = 0 ; i < max ; i++)
    {
	RELTOABS (nlisttab [i].net, nettab) ;
	RELTOABS (nlisttab [i].next, nlisttab) ;
    }

    PROLOGABS (max, graph [LVLANMOBJIDX], lvlantab) ;
    for (i = 0 ; i < max ; i++)
    {
	RELTOABS (lvlantab [i].eq, eqtab) ;
	RELTOABS (lvlantab [i].name, strtab) ;
	RELTOABS (lvlantab [i].next, lvlantab) ;
    }

    PROLOGABS (max, graph [VLANMOBJIDX], vlantab) ;
    for (i = 0 ; i < max ; i++)
    {
	RELTOABS (vlantab [i].name, strtab) ;
	RELTOABS (vlantab [i].netlist, nlisttab) ;
	RELTOABS (vlantab [i].lvlan, lvlantab) ;
    }

    PROLOGABS (max, graph [RNETMOBJIDX], rnettab) ;
    for (i = 0 ; i < max ; i++)
    {
	RELTOABS (rnettab [i].net, nettab) ;
	RELTOABS (rnettab [i].router, nodetab) ;
	RELTOABS (rnettab [i].l3, nodetab) ;
	RELTOABS (rnettab [i].l2, nodetab) ;
	RELTOABS (rnettab [i].l1, nodetab) ;
	RELTOABS (rnettab [i].routelist, routetab) ;
	RELTOABS (rnettab [i].next, rnettab) ;
    }

    PROLOGABS (max, graph [ROUTEMOBJIDX], routetab) ;
    for (i = 0 ; i < max ; i++)
    {
	RELTOABS (routetab [i].next, routetab) ;
    }

    PROLOGABS (max, graph [SSIDPROBEMOBJIDX], ssidprobetab) ;
    for (i = 0 ; i < max ; i++)
    {
	RELTOABS (ssidprobetab [i].name, strtab) ;
	RELTOABS (ssidprobetab [i].eq, eqtab) ;
	RELTOABS (ssidprobetab [i].l1, nodetab) ;
	RELTOABS (ssidprobetab [i].ssid, ssidtab) ;
	RELTOABS (ssidprobetab [i].next, ssidprobetab) ;
    }
}
