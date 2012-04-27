#!/bin/sh

#
# This example script shows how to create a Netmagis database and
# import data.
#

PATH=%SBINDIR%:$PATH
export PATH

#
# You can use PGUSER and PGPASSWORD environment variables to provide 
# netmagis-dbcreate with identity of a priviledged PostgreSQL user 
# (in order to create the database), or you can use -u/-w switches.
#

netmagis-dbcreate && \
    netmagis-dbimport -v group group.txt && \
    netmagis-dbimport -v domain domain.txt && \
    netmagis-dbimport -v network network.txt && \
    netmagis-dbimport -v zone mycompany.com \
			zones/mycompany.com mycompany.com \
			/dev/null pda && \
    netmagis-dbimport -v zone plant1.mycompany.com \
			zones/plant1.mycompany.com plant1.mycompany.com \
			/dev/null pda && \
    netmagis-dbimport -v zone subsid.co.zz \
			zones/subsid.co.zz subsid.co.zz \
			/dev/null pda && \
    netmagis-dbimport -v zone myevent.org \
			zones/myevent.org myevent.org \
			/dev/null pda && \
    netmagis-dbimport -v zone 16.172.in-addr.arpa \
			zones/16.172.in-addr.arpa 172.16/16 \
			/dev/null pda && \
    netmagis-dbimport -v zone 4.3.2.1.6.6.0.1.0.0.2.ip6.arpa \
			zones/4.3.2.1.6.6.0.1.0.0.2.ip6.arpa 2001:660:1234::/48 \
			/dev/null pda && \
    netmagis-dbimport -v mailrelay mailrelay.txt && \
    netmagis-dbimport -v mailrole mailrole.txt pda && \
    echo "Succeeded"

exit 0
