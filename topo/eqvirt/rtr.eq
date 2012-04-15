#
# Example virtual equipment : rtr
#
# This file is an example of a virtual equipment modelling a router
#
# Note: informations marked as "(*)" are encoded in hex, with the
# empty string represented as "-".
# To encode a string, use tclsh:
#	% binary scan "Hello, world" H* var
#	1
#	% puts $var
#	48656c6c6f2c20776f726c64
# To decode an encoded string, use tclsh with:
#	% binary format H* 48656c6c6f2c20776f726c64
#	Hello, world
# 
# History:
#   2012/04/13 : pda      : provide this example
#

###############################################################################
# Equipment definition
###############################################################################

#
# Equipment characteristics:
# - name: name of your equipment (don't use a FQDN)
# - type and model: you can use any string you want. They are
#	used in equipment display, and are searched as type/model
#	when a network graph is displayed (see the WWW menu
#	admin->modify equipment types)
# - snmp: read community name (no space/tab inside), used by
#	the metro module
# - location(*): used only in equipment display at this time. Use "-"
#	to indicate no location.
# - manual: 1 (this is manually configured equipment, don't try
#	to change VLAN on ports)
# 

eq rtr type juniper model M20 snmp public location - manual 1

###############################################################################
# Nodes provided by this equipment
###############################################################################

#
# Routing instances: you can have multiple routing instances if you
# have virtual routers. Note that IPv4 and IPv6 are distinct routing
# instances: a dual stack router will have at least 2 routing instances.
# Default instances should be named "_v4" (for IPv4) and "_v6" (for IPv6).
#

node rtr:r4 type router eq rtr instance _v4
node rtr:r6 type router eq rtr instance _v6

#
# Physical interfaces: describe all used interfaces (you do not need
# to describe unused interfaces)
#
# Physical interface characteristics
# - node name (must be unique in the whole network graph, thus we
#	prepend the equipment name)
# - type: L1
# - eq: equipment name this node belongs to
# - name: interface name
# - link: link name (used to identify remote equipment) or X for terminal port
# - encap: ether (native Ethernet) or trunk (IEEE 802.1Q encapsulation)
# - stat: metrology sensor name, or "-" for no sensor
# - desc(*): interface description (used in equipment display)
#

node rtr:g0 type L1 eq rtr name ge-0/0/0 link X    encap ether stat - desc -
node rtr:g1 type L1 eq rtr name ge-0/0/1 link L101 encap trunk stat - desc -
node rtr:g2 type L1 eq rtr name ge-0/0/2 link L102 encap trunk stat Mrtr desc -

#
# Vlan interfaces: each physical interface (L1) must be connected to
# some Vlan (L2) interfaces.
# - L1 with "encap ether" must be connected to exactly one L2 interface
# - L1 with "encap trunk" may be connected to more than one L2 interface
# Each L2 interface should be connected to a bridge node.
#
# Vlan interface characteristics:
# - node name (must be unique in the whole network graph, thus we
#	prepend the equipment name)
# - type: L1
# - eq: equipment name this node belongs to
# - stat: metrology sensor name, or "-" for no sensor
# - desc(*): interface description (used in equipment display)
# - ifname: interface name 
# - native: 1 (native vlan) or 0 (encapsulated vlan). In an ideal world,
#	there would be no utility for this parameter, as L1 encapsulation
#	mode tells if vlans are encapsulated or not. However, IP telephony
#	often needs dual mode (e.g. ether Vlan for data and trunk Vlan
#	for voice).
#

node rtr:v0     type L2 eq rtr vlan 0   stat - desc - ifname - native 1
node rtr:v1-123 type L2 eq rtr vlan 123 stat - desc - ifname - native 0
node rtr:v2-456 type L2 eq rtr vlan 456 stat - desc - ifname - native 0
node rtr:v2-789 type L2 eq rtr vlan 456 stat - desc - ifname - native 0

#
# IP(v4 and v6) interfaces
#
# IP interface characteristics:
# - node name (must be unique in the whole network graph, thus we
#	prepend the equipment name)
# - type: L1
# - eq: equipment name this node belongs to
# - addr: IPv4 ou IPv6 address with prefix length
#

node rtr:intercov4 type L3 eq rtr addr 192.168.1.1/30
node rtr:intercov6 type L3 eq rtr addr 2001:660:0123:4000::1/64

node rtr:i123v4    type L3 eq rtr addr 172.16.1.254/24
node rtr:i123v6    type L3 eq rtr addr 2001:660:0123:4001::1/64

node rtr:i456v4    type L3 eq rtr addr 172.16.11.254/24
node rtr:i456v6    type L3 eq rtr addr 2001:660:0123:4011::1/64

node rtr:i789v4    type L3 eq rtr addr 172.16.12.254/24
# no IPv6 is routed through this vlan
# node rtr:i789v6    type L3 eq rtr addr 2001:660:0123:4012::1/64


###############################################################################
# Connexions between nodes on this equipment
###############################################################################

# Connexions between L1 and L2 nodes
link rtr:g0 rtr:v0
link rtr:g1 rtr:v1-123
link rtr:g2 rtr:v2-456
link rtr:g2 rtr:v2-789

# Connexions between L2 and L3 nodes
link rtr:v0 rtr:intercov4
link rtr:v0 rtr:intercov6
link rtr:v1-123 rtr:i123v4
link rtr:v1-123 rtr:i123v6
link rtr:v2-456 rtr:i456v4
link rtr:v2-456 rtr:i456v6
link rtr:v2-789 rtr:i789v4

# Connexions between L3 nodes and routing instances

link rtr:r4 rtr:intercov4
link rtr:r4 rtr:i123v4
link rtr:r4 rtr:i456v4
link rtr:r4 rtr:i789v4

link rtr:r6 rtr:intercov6
link rtr:r6 rtr:i123v6
link rtr:r6 rtr:i456v6
