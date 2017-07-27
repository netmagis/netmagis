#!/usr/bin/env python3

#
# Syntax:
#   dnsdelhost [-l libdir][-f configfile][-d] <fqdn> <viewname>
#

import sys
import os.path
import argparse

def doit (nm, fqdn, view):
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
            nm.api ('delete', uri)
    else:
        #
        # Host exists
        #

        idhost = h ['idhost']
        uri = '/hosts/' + str (idhost)
        nm.api ('delete', uri)


def main ():
    parser = argparse.ArgumentParser (description='Netmagis delete host')
    parser.add_argument ('-f', '--config-file', action='store',
                help='Config file location (default=~/.config/netmagisrc)')
    parser.add_argument ('-d', '--debug', action='store_true',
                help='Debug/trace requests')
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
    from pynm.decorator import catchdecorator

    nm = netmagis (args.config_file, trace=args.debug)

    fqdn = args.fqdn
    view = args.view

    fdoit = catchdecorator (args.debug) (doit)
    fdoit (nm, fqdn, view)
    sys.exit (0)


if __name__ == '__main__':
    main ()
