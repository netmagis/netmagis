#!/usr/bin/env python3

#
# Syntax:
#   dnsmodattr [-l libdir][-c configfile][-t] <fqdn> <view> <key> <val> [<key> val> ...]
#
# Examples:
#   dnsmodattr www.example.com default MAC 00:68:fe....
#   dnsmodattr www.example.com external HINFO "PC/Unix"
#   dnsmodattr www.example.com internal TTL 3600      # 1 hour
#   dnsmodattr www.example.com internal TTL ""        # put back default value
#
# Modifiable attributes (keys):
#   MAC, HINFO, RESPNAME, RESPMAIL, COMMENT, DHCPPROFILE, TTL, SENDSMTP
#

import sys
import os.path
import argparse


argmap = {
    'name':	{'jsonname': 'name',  	'type': 'string'},
    'mac':	{'jsonname': 'mac',	'type': 'string'},
    'hinfo':	{'jsonname': 'idhinfo',	'type': 'hinfo'},
    'dhcpprofile':	{'jsonname': 'iddhcpprof',	'type': 'dhcpprofile'},
    'comment':	{'jsonname': 'comment',	'type': 'string'},
    'respname':	{'jsonname': 'respname','type': 'string'},
    'respmail':	{'jsonname': 'respmail','type': 'string'},
    'ttl':	{'jsonname': 'ttl',	'type': 'int'},
    'sendsmtp':	{'jsonname': 'sendsmtp','type': 'int'},
}

def convert_arg_to_jsonvalue (nm, k, v):
    kj = argmap [k]['jsonname']
    typ = argmap [k]['type']

    if typ == 'string':
        vj = v

    elif typ == 'int':
        try:
            vj = int (v)
        except ValueError:
            nm.grmbl ("Invalid value '{}' for key '{}'".format (v, k))

    elif typ == 'hinfo':
        vj = nm.get_idhinfo (v)
        if vj is None:
            nm.grmbl ("Unknown hinfo '{}'".format (v))

    elif typ == 'dhcpprofile':
        vj = nm.get_iddhcpprofile (v)
        if vj is None:
            nm.grmbl ("Unknown dhcpprofile '{}'".format (v))

    else:
        nm.grmbl ("Internal error: unknown type for key '{}'".format (k))

    return (kj, vj)

def main ():
    parser = argparse.ArgumentParser (description='Netmagis modify host attributes')
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
    parser.add_argument ('keyvals', help='Couples key val', nargs='*',
                            metavar='key val')

    args = parser.parse_args ()

    libdir = os.path.abspath (args.libdir or '%NMLIBDIR%')
    sys.path.append (libdir)
    from pynm.core import netmagis

    nm = netmagis (args.config_file, trace=args.trace)

    fqdn = args.fqdn
    view = args.view
    keyvals = args.keyvals

    # Get all valid keys for further error messages
    a = ', '.join (argmap.keys ())

    l = len (keyvals)
    if l % 2 != 0:
        nm.grmbl ('Each key must have a value')
    if l == 0:
        nm.grmbl ('You must provide at least one key in: {}'.format (a))

    (name, domain, iddom, idview, h) = nm.get_host (fqdn, view)

    # get full host record in order to be modified
    idhost = h ['idhost']
    uri = '/hosts/' + str (idhost)
    r = nm.api ('get', uri)
    fullhost = r.json ()

    # browse through arguments to get couples <key, val>
    # and modify full host record
    i = 0
    while i < l:
        k = keyvals [i]
        v = keyvals [i + 1]

        k = k.lower ()
        if k not in argmap:
            nm.grmbl ("Unknown key '{}'\nShould be one of {}".format (k, a))

        (kj, vj) = convert_arg_to_jsonvalue (nm, k, v)
        fullhost [kj] = vj
        i += 2

    # register modifications
    r = nm.api ('put', uri, json=fullhost)

    sys.exit (0)

if __name__ == '__main__':
    main ()
