#!/bin/sh

#
# This example script shows how to create a Netmagis database and
# import data.
# This example does not use DNS views, so there is only one view,
# the "default" view.
#
# Use the NMCONF shell variable to specify an alternate configuration
# file.
#

PATH=%BINDIR%:$PATH
export PATH

NMCONF=${NMCONF:-%CONFFILE%}

netmagis-dbcreate -f "$NMCONF" && \
    netmagis-dbimport -f "$NMCONF" -d group group.txt && \
    netmagis-dbimport -f "$NMCONF" -d domain domain.txt && \
    netmagis-dbimport -f "$NMCONF" -d view view.txt && \
    netmagis-dbimport -f "$NMCONF" -d network network.txt && \
    netmagis-dbimport -f "$NMCONF" -d zone default example.com \
			zones/example.com example.com && \
    netmagis-dbimport -f "$NMCONF" -d zone default plant1.example.com \
			zones/plant1.example.com plant1.example.com && \
    netmagis-dbimport -f "$NMCONF" -d zone default subsid.co.zz \
			zones/subsid.co.zz subsid.co.zz && \
    netmagis-dbimport -f "$NMCONF" -d zone default example.org \
			zones/example.org example.org && \
    netmagis-dbimport -f "$NMCONF" -d zone default 16.172.in-addr.arpa \
			zones/16.172.in-addr.arpa 172.16/16 && \
    netmagis-dbimport -f "$NMCONF" -d zone default \
    			4.3.2.1.8.b.d.0.1.0.0.2.ip6.arpa \
			zones/4.3.2.1.8.b.d.0.1.0.0.2.ip6.arpa 2001:db8:1234::/48 && \
    netmagis-dbimport -f "$NMCONF" -d mailrelay default mailrelay.txt && \
    netmagis-dbimport -f "$NMCONF" -d mailrole default mailrole.txt && \
    echo "Succeeded"

exit 0
