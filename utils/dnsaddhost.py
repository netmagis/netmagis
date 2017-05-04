#!/usr/bin/env python3

#
# Syntax:
#   dnsaddhost [-l libdir][-c configfile] <fqdn> <ip> <viewname>
#
# This scripts uses a configuration file for authentication purpose
#   ~/.config/netmagisrc
#       [general]
#           url = https://app.example.com/netmagis
#           key = a-secret-key-delivered-by-netmagis
#

import sys
import os.path
import argparse

def main ():
    parser = argparse.ArgumentParser (description='Netmagis add host')
    parser.add_argument ('-c', '--config-file', action='store',
                help='Config file location (default=~/.config/netmagisrc)')
    parser.add_argument ('-l', '--libdir', action='store',
                help='Library directory (default=%NMLIBDIR%)')
    parser.add_argument ('fqdn', help='Host FQDN')
    parser.add_argument ('ip', help='IP (v4 or v6) address to add')
    parser.add_argument ('view', help='View name')

    args = parser.parse_args ()

    libdir = os.path.abspath (args.libdir or '%NMLIBDIR%')
    sys.path.append (libdir)
    from pynm.core import netmagis

    nm = netmagis (args.config_file)

    fqdn = args.fqdn
    ip = args.ip
    view = args.view

    (name, domain, iddom, idview) = nm.split_fqdn (fqdn, view)

    #
    # Test if host already exists
    #

    query = {'name': name, 'domain': domain, 'view': view}
    r = nm.api ('get', '/hosts', params=query)
    nm.test_answer (r)

    j = r.json ()
    nr = len (j)
    if nr == 0:
        #
        # Host does not exist: use a POST request to create the host
        #

        # TODO : find a way to get a default HINFO value (API change requested)
        idhinfo = 0

        data = {
                    'name': name,
                    'iddom': iddom,
                    'idview': idview,
                    'mac': "",
                    'idhinfo': idhinfo,
                    'comment': "",
                    'respname': "",
                    'respmail': "",
                    'iddhcpprof': -1,
                    'ttl': -1,
                    'addr': [ip],
                }
        r = nm.api ('post', '/hosts', json=data)
        nm.test_answer (r)

    elif nr == 1:
        #
        # Host already exists: get full data with an additional GET
        # request for this idhost, and use a PUT request to add the
        # new IP address
        #

        idhost = j [0]['idhost']
        uri = '/hosts/' + str (idhost)
        r = nm.api ('get', uri)
        nm.test_answer (r)

        data = r.json ()
        data ['addr'].append (ip)
        r = nm.api ('put', uri, json=data)
        nm.test_answer (r)

    else:
        # this case should never happen
        msg = "Server error: host '{}' exists more than once in view {}"
        nm.grmbl (msg.format (fqdn, view))

if __name__ == '__main__':
    main ()
