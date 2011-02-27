#!/bin/sh

#
# This example script shows how to create a Netmagis database and
# import data.
#

netmagis-dbcreate \
    && netmagis-dbimport group		group.txt \
    && netmagis-dbimport domain-perm	grpdom.txt \
    && netmagis-dbimport network 	network.txt \
    && echo "Succeeded"
