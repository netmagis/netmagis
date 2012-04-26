#
# Example virtual equipment : sw1
#
# This file is an example of a virtual equipment modelling a simple
# switch with a single VLAN.
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
#   2012/04/26 : pda      : bring in sync with default database example
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

eq sw1 type cisco model WS-C2950 snmp public location - manual 1

###############################################################################
# Nodes provided by this equipment
###############################################################################

#
# Bridging instance: there is one bridging instance for each broadcast
# domain on this equipment. In this simple example, we have only one
# broadcast domain.
#
# Bridge node characteristics:
# - node name (must be unique in the whole network graph, thus we
#	prepend the equipment name)
# - type : bridge
# - eq : equipment name this node belongs to
#

node sw1:bridge type bridge eq sw1

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

node sw1:g0  type L1 eq sw1 name Gi0/0  link X encap ether stat - desc -
node sw1:g1  type L1 eq sw1 name Gi0/1  link X encap ether stat - desc -
node sw1:g23 type L1 eq sw1 name Gi0/23 link L101 encap trunk stat Msw1 desc 75706c696e6b20706f7274

#
# Vlan interfaces: each physical interface (L1) must be connected to
# some Vlan (L2) interfaces.
# - L1 with "encap ether" must be connected to exactly one L2 interface
# - L1 with "encap trunk" may be connected to more than one L2 interface
# Each L2 interface should be connected to a bridge node.
#
# Vlan interface characteristics
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

node sw1:v0  type L2 eq sw1 vlan 0   stat - desc - ifname - native 1
node sw1:v1  type L2 eq sw1 vlan 0   stat - desc - ifname - native 1
node sw1:v23 type L2 eq sw1 vlan 123 stat - desc - ifname - native 0

###############################################################################
# Connexions between nodes on this equipment
###############################################################################

# Connexions between L1 and L2 nodes
link sw1:g0 sw1:v0
link sw1:g1 sw1:v1
link sw1:g23 sw1:v23

# Connexions between L2 nodes and bridge
link sw1:bridge sw1:v0
link sw1:bridge sw1:v1
link sw1:bridge sw1:v23
