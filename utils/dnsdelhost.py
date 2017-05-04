#!/usr/bin/env python3

#
# Syntax:
#   dnsdelhost [-l libdir][-c configfile] <fqdn> <viewname>
#

import sys
import os.path
import argparse

def main ():
    parser = argparse.ArgumentParser (description='Netmagis delete host')
    parser.add_argument ('-c', '--config-file', action='store',
                help='Config file location (default=~/.config/netmagisrc)')
    parser.add_argument ('-l', '--libdir', action='store',
                help='Library directory (default=%NMLIBDIR%)')
    parser.add_argument ('fqdn', help='Host FQDN')
    parser.add_argument ('view', help='View name')

    args = parser.parse_args ()

    libdir = os.path.abspath (args.libdir or '%NMLIBDIR%')
    sys.path.append (libdir)
    from pynm.core import netmagis

    nm = netmagis (args.config_file)

    fqdn = args.fqdn
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
        # Host does not exist. Look for an alias.
        #

        query = {'name': name, 'domain': domain, 'view': view}
        r = nm.api ('get', '/aliases', params=query)
        nm.test_answer (r)

        j = r.json ()
        nr = len (j)
        if nr == 1:
            idalias = j [0]['idalias']
            uri = '/aliases/' + str (idalias)
            r = nm.api ('delete', uri)
            nm.test_answer (r)

        else:
            msg = "Host '{}' does not exist in view {}"
            nm.grmbl (msg.format (fqdn, view))

    elif nr == 1:
        #
        # Host exists
        #

        idhost = j [0]['idhost']
        uri = '/hosts/' + str (idhost)
        r = nm.api ('delete', uri)
        nm.test_answer (r)

    else:
        # this case should never happen
        msg = "Server error: host '{}' exists more than once in view {}"
        nm.grmbl (msg.format (fqdn, view))

if __name__ == '__main__':
    main ()
