#!/bin/sh

#
# This example script shows how to create a Netmagis database and
# import data.
#

netmagis-dbcreate \
    && netmagis-dbimport -v group		group.txt \
    && netmagis-dbimport -v domain		domain.txt \
    && netmagis-dbimport -v network 	network.txt \
    && netmagis-dbimport -v zone univ-machin.fr \
			zones/univ-machin.fr univ-machin.fr \
			/dev/null pda \
    && netmagis-dbimport -v zone labo2.univ-machin.fr \
			zones/labo2.univ-machin.fr labo2.univ-machin.fr \
			/dev/null pda \
    && netmagis-dbimport -v zone esiatf.fr \
			zones/esiatf.fr esiatf.fr \
			/dev/null pda \
    && netmagis-dbimport -v zone bidon.org \
			zones/bidon.org bidon.org \
			/dev/null pda \
    && netmagis-dbimport -v zone 16.172.in-addr.arpa \
			zones/16.172.in-addr.arpa 172.16/16 \
			/dev/null pda \
    && netmagis-dbimport -v zone 4.3.2.1.0.6.6.0.1.0.0.2.ip6.arpa \
			zones/4.3.2.1.0.6.6.0.1.0.0.2.ip6.arpa 2001:660:1234::/48 \
			/dev/null pda \
    && echo "Succeeded"

exit 0
