#!/usr/bin/env python3

#
# Mail route generation for sendmail (or other MTAs)
#
# Syntax:
#   mkmroute [-l libdir][-f configfile][-t][-q][-v][-n] [-w] [<view-name>]
#

import sys
import os.path
import argparse

# return list of views if no view is provided
def fetch_views (nm):
    r = nm.api ('get', '/gen/mroute')
    j = r.json ()

    views = []
    for vj in j:
        views.append (vj ['name'])

    return views

# generate a mroute file as a string containing all data
def generate_mroute (nm, v, prologue, fmt):
    r = nm.api ('get', '/gen/mroute/' + v)
    j = r.json ()

    #
    # Get prologue
    #

    with open (prologue, 'r') as f:
        txt = f.read ()

    txt += '\n'

    for mr in j:
        txt += fmt.format (**mr) + '\n'

    return txt


def main ():
    parser = argparse.ArgumentParser (description='Netmagis mail route generation')
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
    parser.add_argument ('-w', '--obsolete-option', action='store_true',
                help='Option kept for compatibility purpose')
    parser.add_argument ('view', nargs='?',
                help='Limit generation to this view')

    args = parser.parse_args ()

    libdir = os.path.abspath (args.libdir or '%NMLIBDIR%')
    sys.path.append (libdir)
    from pynm.core import netmagis
    from pynm.fileinst import fileinst
    from pynm.nmlock import nmlock
    from pynm import utils

    nm = netmagis (args.config_file, trace=args.trace)

    if args.obsolete_option:
        print ('WARNING: option -w is deprecated', file=sys.stderr)

    verbose = 0
    if args.quiet:
        verbose = -1
    elif args.verbose:
        verbose = 1
    dryrun = args.dry_run
    view = args.view

    #
    # Check view name
    #

    if view is not None:
        idview = nm.get_idview (view)
        if idview is None:
            self.grmbl ('View \'{}\' not found'.format (view))

    #
    # Get parameters from local configuration file (~/.config/netmagisrc)
    #

    lockfile = nm.getconf ('mkmroute', 'lockfile')
    mroutefile = nm.getconf ('mkmroute', 'mroutefile')
    mrouteprologue = nm.getconf ('mkmroute', 'mrouteprologue')
    mroutefmt = nm.getconf ('mkmroute', 'mroutefmt')
    mroutecmd = nm.getconf ('mkmroute', 'mroutecmd')

    #
    # Prevent multiple runs
    #

    with nmlock (lockfile) as lck:

        if not lck.trylock ():
            if verbose >= 0:
                print ('Mkmroute already running. Abort', file=sys.stderr)
            sys.exit (0)

        #
        # Initialize fq engine
        #

        fq = fileinst ()

        #
        # Fetch view
        #

        if view is None:
            views = fetch_views (nm)
            if len (views) > 1:
                print ('Mkmroute does not support multiple views', file=sys.stderr)
                sys.exit (1)
            view = views [0]

        #
        # Generate file contents
        #

        txt = generate_mroute (nm, view, mrouteprologue, mroutefmt)

        #
        # Show diffs if needed (if verbose)
        #

        diff = utils.diff_file_text (mroutefile, txt, show=(verbose > 0))

        #
        # If no modification, stop
        #

        #
        # Output generated data to file
        #

        if verbose >= 0 and not dryrun:
            if diff:
                print ('Mail routes are modified')
            else:
                print ('Mail routes are not modified')

        if diff and not dryrun:
            err = fq.add (mroutefile, txt)
            if err:
                nm.grmbl (err)

            #
            # Install files and run command
            #

            err = fq.commit ()

            #
            # Signal the MTA daemon
            #

            if mroutecmd != '':
                (r, msg) = utils.run (mroutecmd)
                if r != 0:
                    fq.uncommit ()
                    nm.grmbl ("Command failed: {}\n{}".format (mroutecmd, msg))

        #
        # Allow other mkmroute to run
        # (not really needed since the process exit will automatically
        # remove the advisory file lock)
        #

        lck.unlock ()

    sys.exit (0)

if __name__ == '__main__':
    main ()
