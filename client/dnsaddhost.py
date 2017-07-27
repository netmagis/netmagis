#!/usr/bin/env python3

#
# Syntax:
#   dnsaddhost [-l libdir][-f configfile][-d] <fqdn> <ip> <viewname>
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


def doit (nm, fqdn, ip, view):
    (name, domain, iddom, idview, h) = nm.get_host (fqdn, view, must_exist=False)

    #
    # Test if host already exists
    #

    if h is None:
        #
        # Host does not exist: use a POST request to create the host
        #

        # TODO : find a way to get a default HINFO value (API change requested)
        print ('WARNING: GET DEFAULT HINFO', file=sys.stderr)
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
        nm.api ('post', '/hosts', json=data)

    else:
        #
        # Host already exists: get full data with an additional GET
        # request for this idhost, and use a PUT request to add the
        # new IP address
        #

        idhost = h ['idhost']
        uri = '/hosts/' + str (idhost)
        nm.api ('get', uri)

        data = r.json ()
        data ['addr'].append (ip)
        nm.api ('put', uri, json=data)


def main ():
    parser = argparse.ArgumentParser (description='Netmagis add host')
    parser.add_argument ('-f', '--config-file', action='store',
                help='Config file location (default=~/.config/netmagisrc)')
    parser.add_argument ('-d', '--debug', action='store_true',
                help='Debug/trace requests')
    # warning: do not execute this script with "--help" while %...% are
    # not subtitued
    parser.add_argument ('-l', '--libdir', action='store',
                help='Library directory (default=%NMLIBDIR%)')
    parser.add_argument ('fqdn', help='Host FQDN')
    parser.add_argument ('ip', help='IP (v4 or v6) address to add')
    parser.add_argument ('view', help='View name')

    args = parser.parse_args ()

    libdir = os.path.abspath (args.libdir or '%NMLIBDIR%')
    sys.path.append (libdir)
    from pynm.core import netmagis
    from pynm.decorator import catchdecorator

    nm = netmagis (args.config_file, trace=args.debug)

    fqdn = args.fqdn
    ip = args.ip
    view = args.view

    fdoit = catchdecorator (args.debug) (doit)
    fdoit (nm, fqdn, ip, view)
    sys.exit (0)


if __name__ == '__main__':
    main ()
