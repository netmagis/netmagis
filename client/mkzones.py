#!/usr/bin/env python3

#
# Syntax:
#   mkzones [-l libdir][-f configfile][-t][-q][-v][-n] \
#                   [-w <view-name>|<zone-name> ... <zone-name>]
#

import sys
import os.path
import argparse

def main ():
    parser = argparse.ArgumentParser (description='Netmagis zone generation')
    parser.add_argument ('-f', '--config-file', action='store',
                help='Config file location (default=~/.config/netmagisrc)')
    parser.add_argument ('-t', '--trace', action='store_true',
                help='Trace requests to Netmagis server')
    # warning: do not execute this script with "--help" while %...% are
    # not subtitued
    parser.add_argument ('-l', '--libdir', action='store',
                help='Library directory (default=%NMLIBDIR%)')

    parser.add_argument ('-q', '--quiet', action='store_true',
                help='Keep silent on normal operation')
    parser.add_argument ('-v', '--verbose', action='store_true',
                help='Verbose (show diffs)')
    parser.add_argument ('-n', '--dry-run', action='store_true',
                help='Don\'t perform file installation')
    parser.add_argument ('-w', '--view', action='store',
                help='Limit generation to modified zones for this view')
    parser.add_argument ('zone', help='Zone name', nargs='*')

    args = parser.parse_args ()

    libdir = os.path.abspath (args.libdir or '%NMLIBDIR%')
    sys.path.append (libdir)
    from pynm.core import netmagis, fileinst

    nm = netmagis (args.config_file, trace=args.trace)

    quiet = args.quiet
    verbose = args.verbose
    dryrun = args.dry_run
    view = args.view
    zones = args.zone

    #
    # Check mutually exclusive options: -w view vs zone ... zone
    #

    if view is not None and zones:
        nm.grmbl ('View name and zones are mutually exclusive')

    #
    # Get parameters from local configuration file (~/.config/netmagisrc)
    #

    diff = nm.getconf ('mkclient', 'diff')
    zonedir = nm.getconf ('mkclient', 'zonedir')
    zonecmd = nm.getconf ('mkclient', 'zonecmd')

    #
    # Check view name
    #

    if view is not None:
        idview = nm.get_idview (view)
        if idview is None:
            self.grmbl ('View \'{}\' not found'.format (view))

    # initialize fq engine
    # fetch modified zones (and filter result if zones are provided)
    # for each zone
    #   gen zone
    #   fq->add zone
    # done
    # fq->commit
    # reload DNS daemon
    # if error: PROBLEM!



    sys.exit (0)
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
