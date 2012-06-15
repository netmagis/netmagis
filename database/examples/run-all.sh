#!/bin/sh

#
# This example script shows how to create a Netmagis database and
# import data.
#

PATH=%SBINDIR%:$PATH
export PATH

netmagis-dbcreate && \
    netmagis-dbimport -v group group.txt && \
    netmagis-dbimport -v domain domain.txt && \
    netmagis-dbimport -v network network.txt && \
    netmagis-dbimport -v zone example.com \
			zones/example.com example.com \
			/dev/null pda && \
    netmagis-dbimport -v zone plant1.example.com \
			zones/plant1.example.com plant1.example.com \
			/dev/null pda && \
    netmagis-dbimport -v zone subsid.co.zz \
			zones/subsid.co.zz subsid.co.zz \
			/dev/null pda && \
    netmagis-dbimport -v zone example.org \
			zones/example.org example.org \
			/dev/null pda && \
    netmagis-dbimport -v zone 16.172.in-addr.arpa \
			zones/16.172.in-addr.arpa 172.16/16 \
			/dev/null pda && \
    netmagis-dbimport -v zone 4.3.2.1.8.b.d.0.1.0.0.2.ip6.arpa \
			zones/4.3.2.1.8.b.d.0.1.0.0.2.ip6.arpa 2001:db8:1234::/48 \
			/dev/null pda && \
    netmagis-dbimport -v mailrelay mailrelay.txt && \
    netmagis-dbimport -v mailrole mailrole.txt pda && \
    echo "Succeeded"

exit 0
