#!/usr/bin/env python3

#
# Syntax:
#   dnswriteprol [-l libdir][-c configfile][-t] <zonename> [<viewname>] <file>
#

import sys
import os.path
import argparse

def main ():
    parser = argparse.ArgumentParser (description='Netmagis write zone prologue')
    parser.add_argument ('-c', '--config-file', action='store',
                help='Config file location (default=~/.config/netmagisrc)')
    parser.add_argument ('-t', '--trace', action='store_true',
                help='Trace requests to Netmagis server')
    # warning: do not execute this script with "--help" while %...% are
    # not subtitued
    parser.add_argument ('-l', '--libdir', action='store',
                help='Library directory (default=%NMLIBDIR%)')
    parser.add_argument ('zone', help='zone name')
    parser.add_argument ('view', help='View name', nargs='?', default=None)
    parser.add_argument ('file', type=open, help='file name')

    args = parser.parse_args ()

    libdir = os.path.abspath (args.libdir or '%NMLIBDIR%')
    sys.path.append (libdir)
    from pynm.core import netmagis

    nm = netmagis (args.config_file, trace=args.trace)

    zone = args.zone
    view = args.view
    fd = args.file

    (table, j) = nm.get_zone (zone, view)

    newprol = fd.read ()
    fd.close ()
    j ['prologue'] = newprol

    uri = '/admin/dns.' + table + '/' + str (j ['idzone'])
    r = nm.api ('put', uri, json=j)

if __name__ == '__main__':
    main ()
