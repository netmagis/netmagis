/*
 * $Id: graph.h,v 1.1.1.1 2007-01-05 15:12:00 pda Exp $
 */

/*
 * Graph.h
 *
 * Definitions used to represent a graph of a network
 *
 * History
 *   2004/06/22 : pda/jean : design
 *   2006/05/26 : pda/jean : collect points
 */

/******************************************************************************
Include files for items specific to this file
******************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/*
 * For IP address manipulation functions
 */

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>

/******************************************************************************
Global definitions used everywhere
******************************************************************************/

/*
 * Facility
 */

#define	NTAB(t)		(sizeof (t) / sizeof (t [0]))

/*
 * Link name (used in interface description) to identify links to outside
 * of our network.
 */
#define	EXTLINK	"X"

/*
 * Maximum line length (including "network" lines)
 */

#define	MAXLINE	100000

/*
 * Maximum number of Vlans
 */

#define	MAXVLAN	4096

/******************************************************************************
Dynamic memory object
******************************************************************************/

enum mobj_mode
{
    MOBJ_CONST,			/* cannot increase size after init */
    MOBJ_MALLOC,		/* already allocated areas cannot change */
    MOBJ_REALLOC,		/* already allocated areas may change address */
} ;


struct mobj
{
    enum mobj_mode mode ;
    int maxidx ;		/* used only for MOBJ_CONST or MOBJ_REALLOC */
    int curidx ;
    int objsiz ;
    void *head ;		/* head of a list */
    void *data ;		/* used only for MOBJ_CONST or MOBJ_REALLOC */
} ;
typedef struct mobj MOBJ ;

MOBJ *mobj_init (int objsiz, enum mobj_mode mode) ;
void mobj_close (MOBJ *d) ;
void mobj_free (MOBJ *d, void *data) ;
void *mobj_alloc (MOBJ *d, int nelem) ;
void *mobj_data (MOBJ *d) ;
void *mobj_head (MOBJ *d) ;
void mobj_sethead (MOBJ *d, void *head) ;
void mobj_empty (MOBJ *d) ;
int mobj_size (MOBJ *d) ;
int mobj_count (MOBJ *d) ;
int mobj_read (FILE *fp, MOBJ *d, int nelem) ;
int mobj_write (FILE *fp, MOBJ *d) ;


/*
 * Global dynamic objects (saved in compiled files)
 */

#define	HASHMOBJIDX	0
#define	SYMMOBJIDX	1
#define	STRMOBJIDX	2
#define	NODEMOBJIDX	3
#define	LINKMOBJIDX	4
#define	LLISTMOBJIDX	5
#define	EQMOBJIDX	6
#define	VDESCMOBJIDX	7
#define	NETMOBJIDX	8
#define	ROUTEMOBJIDX	9
#define	NB_MOBJ		(ROUTEMOBJIDX+1)

#define	hashmobj	(mobjlist [HASHMOBJIDX])
#define	symmobj		(mobjlist [SYMMOBJIDX])
#define	strmobj		(mobjlist [STRMOBJIDX])
#define	nodemobj	(mobjlist [NODEMOBJIDX])
#define	linkmobj	(mobjlist [LINKMOBJIDX])
#define	llistmobj	(mobjlist [LLISTMOBJIDX])
#define	eqmobj		(mobjlist [EQMOBJIDX])
#define	vdescmobj	(mobjlist [VDESCMOBJIDX])
#define	netmobj		(mobjlist [NETMOBJIDX])
#define	routemobj	(mobjlist [ROUTEMOBJIDX])

extern MOBJ *mobjlist [] ;

char **vlandesc ;			/* array of vlan descriptions */

void duplicate_graph (MOBJ *new [], MOBJ *old []) ;

/******************************************************************************
Vlan type
******************************************************************************/

typedef int vlan_t ;			/* vlan id */

struct vlanlist
{
    vlan_t min, max ;			/* vlan range */
    struct vlanlist *next ;		/* next in list */
} ;

#define	NBYTESVLAN	(MAXVLAN/8)

typedef unsigned char vlanset_t [NBYTESVLAN] ;
#define vlan_zero(tab)		do { int i ; for (i=0;i<NBYTESVLAN;i++) \
					tab[i]=0 ; } while (0)
#define	vlan_isset(tab,n)	(tab [n/8] & (1 << (n%8)))
#define	vlan_set(tab,n)		(tab [n/8] |= (1 << (n%8)))
#define	vlan_clear(tab,n)	(tab [n/8] &= ~(1 << (n%8)))
#define	vlan_nextset(tab,n)	do { for (;n<MAXVLAN;n++) \
					if (vlan_set(tab,n)) break ; } while (0)

void traversed_vlans (vlanset_t vs) ;
void print_vlanlist (FILE *fp, vlanset_t vs) ;

/******************************************************************************
Miscellaneous functions
******************************************************************************/

extern int errorstate ;
extern int lineno ;

void error (int syserr, char *msg) ;
void inconsistency (char *fmt, ...) ;
void *my_malloc (size_t s) ;


/******************************************************************************
Symbol table functions
******************************************************************************/

struct symtab
{
    char *name ;		/* name (in strmobj) */
    struct node *node ;		/* node with this name (in nodemobj) */
    struct link *link ;		/* physical link between eq (in linkmobj) */
    struct symtab *next ;	/* next symtab (in symmobj) */
} ;

void symtab_init (void) ;
struct symtab *symtab_lookup (char *name) ;
struct symtab *symtab_get (char *name) ;

#define symtab_to_name(s)	((s)->name)
#define symtab_to_node(s)	((s)->node)
#define symtab_to_link(s)	((s)->link)


/******************************************************************************
IP address datatypes and functions
******************************************************************************/

struct cidr46
{
    int family ;			/* AF_INET or AF_INET6 */
    union
    {
	struct in_addr adr4 ;
	struct in6_addr adr6 ;
    } u ;
    int preflen ;
} ;

typedef struct cidr46 ip_t ;

#define	IPADDRLEN  sizeof("xxxx:xxxx:xxxx:xxxx:xxxx:xxxx:255.255.255.255/128")
typedef char iptext_t [IPADDRLEN+1] ;

int ip_pton (char *text, ip_t *cidr) ;
int ip_ntop (ip_t *cidr, iptext_t text, int prefix) ;
int ip_match (ip_t *adr, ip_t *network, int prefix) ;
void ip_netof (ip_t *srcadr, ip_t *dstadr) ;

/******************************************************************************
Node name management
******************************************************************************/

char *new_nodename (char *eqname) ;

/******************************************************************************
Node management
******************************************************************************/

/*
 * Warning : if a modification of these structures occur, don't
 * forget to modify the following source files
 *	absrel.c
 *	relabs.c
 *	dupgraph.c
 *	textread.c
 *	textwrite.c
 */

enum nodetype
{
    NT_L1,
    NT_L2,
    NT_L3,
    NT_BRIDGE,
    NT_ROUTER,
    NT_BRPAT,
    NT_L2PAT,
} ;

enum L1type
{
    L1T_TRUNK,
    L1T_ETHER,
} ;

struct L1
{
    char *ifname ;			/* physical interface name */
    char *link ;			/* physical link name */
    char *stat ;			/* collect point */
    enum L1type l1type ;
} ;

struct L2
{
    vlan_t vlan ;
    char *stat ;			/* collect point */
} ;

struct L3
{
    ip_t addr ;				/* IP (v4 or v6) address with mask */
} ;

#ifdef NOTNEEDED
struct bridge
{
    /* nothing */
} ;
#endif

struct router
{
    char *name ;			/* routing instance name */
} ;

struct L2pat
{
    struct vlanlist *allowed ;
} ;

struct node
{
    char *name ;			/* name of node */
    char *eq ;				/* name of equipement */
    enum nodetype nodetype ;
    union
    {
	struct L1 l1 ;
	struct L2 l2 ;
	struct L3 l3 ;
	/* nothing for bridge */
	struct router router ;
	struct L2pat l2pat ;
	/* nothing for brpat */
    } u ;
    struct linklist *linklist ;

    /* For graph traversal */
    vlanset_t vlanset ;			/* vlans transported on this node */
    int mark ;				/* used by various places. See below */

    struct node *next ;			/* next entry in node list */
} ;


#define	MK_L2TRANSPORT		0x1	/* used by transport_vlan_on_L2 */
#define	MK_LAST			MK_L2TRANSPORT

struct node *create_node (char *name, char *eq, enum nodetype nodetype) ;

/******************************************************************************
Link management
******************************************************************************/

struct link
{
    char *name ;			/* link name if physical link */
    struct node *node [2] ;		/* interconnected nodes */
} ;

/*
 * List of links, generaly used to keep all links connected to a node,
 * but used also to keep all physical links seen in the input file.
 */

struct linklist
{
    struct link *link ;
    struct linklist *next ;
} ;

struct link *create_link (char *name, char *n1, char *n2) ;

#define	getlinkpeer(l,n) (((l)->node[0]==(n)) ? (l)->node[1] : (l)->node[0])

struct node *get_neighbour (struct node *n, enum nodetype type) ;
void check_links (void) ;

/******************************************************************************
Propagation of vlans in the graph
******************************************************************************/

void transport_vlan_on_L2 (struct node *n, vlan_t v) ;

/******************************************************************************
Equipement list
******************************************************************************/

struct eq
{
    char *name ;
    char *type ;
    char *model ;
    char *snmp ;

    int mark ;				/* used by drawl2 */

    struct eq *next ;
} ;

struct eq *search_eq (char *name) ;

/******************************************************************************
Network list
******************************************************************************/

struct route
{
    ip_t net ;
    ip_t gw ;
    struct route *next ;
} ;

struct network
{
    ip_t addr ;				/* IP (v4 or v6) address with mask */
    struct node *router ;
    struct node *l3 ;
    struct node *l2 ;
    struct node *l1 ;
    ip_t vrrpaddr ;
    int vrrpprio ;
    struct route *routelist ;
    struct network *next ;
} ;

/******************************************************************************
Graph-file binary format
******************************************************************************/

struct mobjhdr
{
    int objsiz ;
    int objcnt ;
    int listhead ;
} ;

struct graphhdr
{
    unsigned int magic ;
    unsigned int version ;
    unsigned int nbmobj ;
    struct mobjhdr mobjhdr [NB_MOBJ] ;
} ;

#define	MAGIC		0x67726571	/* greq (graph of equipements) */
#define	VERSION1	1
#define	VERSION2	2

void abs_to_rel (MOBJ *graph []) ;
void rel_to_abs (MOBJ *graph []) ;

/******************************************************************************
Input-output functions
******************************************************************************/

void text_read (FILE *fpin) ;
void text_write (FILE *fpin) ;

void bin_read (FILE *fpin, MOBJ *graph []) ;
void bin_write (FILE *fpout, MOBJ *graph []) ;
