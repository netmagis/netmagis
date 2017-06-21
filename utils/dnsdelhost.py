#!/usr/bin/env python3

#
# Syntax:
#   dnsdelhost [-l libdir][-c configfile][-t] <fqdn> <viewname>
#

import sys
import os.path
import argparse

def main ():
    parser = argparse.ArgumentParser (description='Netmagis delete host')
    parser.add_argument ('-c', '--config-file', action='store',
                help='Config file location (default=~/.config/netmagisrc)')
    parser.add_argument ('-t', '--trace', action='store_true',
                help='Trace requests to Netmagis server')
    # warning: do not execute this script with "--help" while %...% are
    # not subtitued
    parser.add_argument ('-l', '--libdir', action='store',
                help='Library directory (default=%NMLIBDIR%)')
    parser.add_argument ('fqdn', help='Host FQDN')
    parser.add_argument ('view', help='View name')

    args = parser.parse_args ()

    libdir = os.path.abspath (args.libdir or '%NMLIBDIR%')
    sys.path.append (libdir)
    from pynm.core import netmagis

    nm = netmagis (args.config_file, trace=args.trace)

    fqdn = args.fqdn
    view = args.view

    (name, domain, iddom, idview, h) = nm.get_host (fqdn, view, must_exist=False)

    if h is None:
        #
        # Host does not exist. Look for an alias.
        #

        (_, _, _, _, a) = nm.get_alias (fqdn, view, must_exist=False)

        if a is None:
            msg = "No host or alias '{}' in view {}"
            nm.grmbl (msg.format (fqdn, view))

        else:
            idalias = a ['idalias']
            uri = '/aliases/' + str (idalias)
            r = nm.api ('delete', uri)

    else:
        #
        # Host exists
        #

        idhost = h ['idhost']
        uri = '/hosts/' + str (idhost)
        r = nm.api ('delete', uri)

if __name__ == '__main__':
    main ()
