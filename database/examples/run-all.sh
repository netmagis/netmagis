#!/bin/sh

#
# This example script shows how to create a Netmagis database and
# import data.
#
# Note: this example shows how to use views.
# If you don't want views:
#	- update the view.txt file to use the "default" view
#	- substitute view "internal" by "default" everywhere in this file
#	- don't load the example.com zone twice
#

PATH=%SBINDIR%:$PATH
export PATH

netmagis-dbcreate && \
    netmagis-dbimport -v group group.txt && \
    netmagis-dbimport -v domain domain.txt && \
    netmagis-dbimport -v view view.txt && \
    netmagis-dbimport -v network network.txt && \
    netmagis-dbimport -v zone internal example.com \
			zones/example.com example.com \
			/dev/null pda && \
    netmagis-dbimport -v zone internal plant1.example.com \
			zones/plant1.example.com plant1.example.com \
			/dev/null pda && \
    netmagis-dbimport -v zone internal subsid.co.zz \
			zones/subsid.co.zz subsid.co.zz \
			/dev/null pda && \
    netmagis-dbimport -v zone internal example.org \
			zones/example.org example.org \
			/dev/null pda && \
    netmagis-dbimport -v zone internal 16.172.in-addr.arpa \
			zones/16.172.in-addr.arpa 172.16/16 \
			/dev/null pda && \
    netmagis-dbimport -v zone internal 4.3.2.1.8.b.d.0.1.0.0.2.ip6.arpa \
			zones/4.3.2.1.8.b.d.0.1.0.0.2.ip6.arpa 2001:db8:1234::/48 \
			/dev/null pda && \
    netmagis-dbimport -v zone external example.com-external-view \
			zones/example.com example.com \
			/dev/null pda && \
    netmagis-dbimport -v mailrelay external mailrelay.txt && \
    netmagis-dbimport -v mailrole external mailrole.txt pda && \
    echo "Succeeded"

exit 0
