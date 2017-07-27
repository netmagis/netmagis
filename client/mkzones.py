#!/usr/bin/env python3

#
# Syntax:
#   mkzones [-l libdir][-f configfile][-t][-q][-v][-n] \
#                   [-w <view-name>|<zone-name> ... <zone-name>]
#

import sys
import os.path
import argparse

# return list of modified zone names
def fetch_modified_zones (nm, view, zones):
    params = None
    if view is not None:
        params = {'view': view, 'gen': 1}
    elif not zones:
        params = {'gen': 1}

    if params:
        r = nm.api ('get', '/gen/zones', params=params)
        j = r.json ()

        zones = []
        for zj in j:
            zones.append (zj ['name'])

    return zones

# generate a zone as a string containing all records
# return (counter, records)
def generate_zone_text (nm, z):
    r = nm.api ('get', '/gen/zones/' + z)
    j = r.json ()
    prologue = j ['prologue']
    records = j ['records']
    rrsup = j ['rrsup']
    counter = j ['counter']

    txt = prologue
    txt += '\n'

    #
    # Get individual records
    #

    seen = {}
    for rr in records:
        name = rr ['name']
        if rr ['ttl'] == -1:
            rr ['ttl'] = ''
        t = '{name}\t{ttl}\tIN\t{type}\t{rdata}\n'.format (**rr)
        txt += t

        # rrsup
        if rrsup and rr ['type'] in ['A', 'AAAA'] and name not in seen:
            seen [name] = True          # any value
            txt += rrsup.replace ('%NAME%', name) + '\n'

    return (counter, txt)


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
    from pynm.core import netmagis
    from pynm.fileinst import fileinst
    from pynm.nmlock import nmlock
    from pynm import utils

    nm = netmagis (args.config_file, trace=args.trace)

    verbose = 0
    if args.quiet:
        verbose = -1
    elif args.verbose:
        verbose = 1
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

    lockfile = nm.getconf ('mkzones', 'lockfile')
    zonedir = nm.getconf ('mkzones', 'zonedir')
    zonecmd = nm.getconf ('mkzones', 'zonecmd')

    #
    # Check view name
    #

    if view is not None:
        idview = nm.get_idview (view)
        if idview is None:
            self.grmbl ('View \'{}\' not found'.format (view))

    #
    # Prevent multiple mkzone runs
    #

    with nmlock (lockfile) as lck:

        if not lck.trylock ():
            if verbose >= 0:
                print ('Mkzones already running. Abort', file=sys.stderr)
            sys.exit (0)

        #
        # Initialize fq engine
        #

        fq = fileinst ()

        #
        # Fetch modified zones (and filter result if zones are provided)
        # (if view is provided, or no zone is specified)
        # [if one or more zones are provided on command line, skip this step]
        #

        zones = fetch_modified_zones (nm, view, zones)

        if not zones:
            if verbose >= 0:
                print ('No modified zone')
            sys.exit (0)

        #
        # For each zone
        #

        reg = []
        for z in zones:
            if verbose >= 0:
                print ("Generating zone '{}'".format (z))

            #
            # Generate zone contents
            #

            (counter, txt) = generate_zone_text (nm, z)

            reg.append ({'name': z, 'counter': counter})

            #
            # Show diffs
            #

            fname = os.path.join (zonedir, z)
            utils.diff_file_text (fname, txt, show=(verbose > 0))

            #
            # Output generated zone to file
            #

            if not dryrun:
                err = fq.add (fname, txt)
                if err:
                    nm.grmbl (err)


        #
        # Install files and run command
        #

        if not dryrun:
            err = fq.commit ()

            #
            # Reload DNS daemon
            #

            if zonecmd != '':
                (r, msg) = utils.run (zonecmd)
                if r != 0:
                    fq.uncommit ()
                    nm.grmbl ("Command failed: {}\n{}".format (zonecmd, msg))

            #
            # Register generation
            # POST /zones with zone counters
            #

            r = nm.api ('post', '/gen/zones', json=reg, check=False)
            if r.status_code != 200:
                fq.uncommit ()
                msg = 'Cannot register zone generation, server returned {}\n{}'
                nm.grmbl (msg.format (r.status_code, r.reason))

        #
        # Allow other mkzones to run
        # (not really needed since the process exit will automatically
        # remove the advisory file lock)
        #

        lck.unlock ()

    sys.exit (0)

if __name__ == '__main__':
    main ()
