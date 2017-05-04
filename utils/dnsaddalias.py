#!/usr/bin/env python3

#
# Syntax:
#   dnsaddalias [-l libdir][-c configfile] <fqdn-alias> <fqdn-host> <viewname>
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
    parser.add_argument ('alias', help='Host FQDN')
    parser.add_argument ('host', help='Alias FQDN')
    parser.add_argument ('view', help='View name')

    args = parser.parse_args ()

    libdir = os.path.abspath (args.libdir or '%NMLIBDIR%')
    sys.path.append (libdir)
    from pynm.core import netmagis

    nm = netmagis (args.config_file)

    fqdnh = args.host
    fqdna = args.alias
    view = args.view

    # view is the same for host and alias
    (nameh, domainh, iddomh, idviewh) = nm.split_fqdn (fqdnh, view)
    (namea, domaina, iddoma, idviewa) = nm.split_fqdn (fqdna, view)

    #
    # Test if alias already exists
    #

    query = {'name': namea, 'domain': domaina, 'view': view}
    r = nm.api ('get', '/aliases', params=query)
    nm.test_answer (r)

    j = r.json ()
    nr = len (j)
    if nr == 0:
        #
        # Alias does not exist: fetch the host id
        #

        query = {'name': nameh, 'domain':domainh, 'view':view}
        rh = nm.api ('get', '/hosts', params=query)
        nm.test_answer (rh)

        jh = rh.json ()
        nrh = len (jh)
        if nrh == 0:
            # Host does not exist
            nm.grmbl ('Host {} does not exist in view {}'.format (fqdnh, view))

        elif nrh > 1:
            # this case should never happen
            msg = "Server error: host '{}' found more than once in view {}"
            nm.grmbl (msg.format (fqdn, view))

        else:
            pass

        #
        # Found host id. Use a POST request to create the alias
        #

        idhost = jh [0]['idhost']
        data = {
                    'name': namea,
                    'iddom': iddoma,
                    'idview': idviewa,
                    'idhost': idhost,
                    'ttl': -1,
                }
        r = nm.api ('post', '/aliases', json=data)
        nm.test_answer (r)

    elif nr == 1:
        #
        # Alias already exists
        #
        nm.grmbl ("Alias '{}' already exists".format (fqdna, view))

    else:
        # this case should never happen
        msg = "Server error: host '{}' exists more than once in view {}"
        nm.grmbl (msg.format (fqdn, view))

if __name__ == '__main__':
    main ()
