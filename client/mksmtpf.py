#!/usr/bin/env python3

#
# SMTP filter generation for packet filters
#
# Syntax:
#   mksmtp [-l libdir][-f configfile][-t][-q][-v][-n] [-w] [<view-name>]
#

import sys
import os.path
import argparse

# return list of views if no view is provided
def fetch_views (nm):
    r = nm.api ('get', '/gen/smtpf')
    j = r.json ()

    views = []
    for vj in j:
        views.append (vj ['name'])

    return views

# generate a smtpf file as a string containing all data
def generate_smtpf (nm, v, prologue, fmt):
    r = nm.api ('get', '/gen/smtpf/' + v)
    j = r.json ()

    #
    # Get prologue
    #

    with open (prologue, 'r') as f:
        txt = f.read ()

    txt += '\n'

    for a in j:
        txt += fmt.format (**a) + '\n'

    return txt


def main ():
    parser = argparse.ArgumentParser (description='Netmagis SMTP filter generation')
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

    quiet = args.quiet
    verbose = args.verbose
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

    lockfile = nm.getconf ('mksmtpf', 'lockfile')
    pffile = nm.getconf ('mksmtpf', 'pffile')
    pffmt = nm.getconf ('mksmtpf', 'pffmt')
    pfprologue = nm.getconf ('mksmtpf', 'pfprologue')
    pftest = nm.getconf ('mksmtpf', 'pftest')
    pfcmd = nm.getconf ('mksmtpf', 'pfcmd')

    #
    # Prevent multiple runs
    #

    with nmlock (lockfile) as lck:

        if not lck.trylock ():
            if verbose:
                print ('Mksmtpf already running. Abort', file=sys.stderr)
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
                print ('Mksmtpf does not support multiple views', file=sys.stderr)
                sys.exit (1)
            view = views [0]

        #
        # Generate file contents
        #

        txt = generate_smtpf (nm, view, pfprologue, pffmt)

        #
        # Show diffs if needed (if verbose)
        #

        diff = utils.diff_file_text (pffile, txt, show=verbose)

        #
        # Output generated data to file
        #

        if verbose and not dryrun:
            if diff:
                print ('SMTP filters are modified')
            else:
                print ('SMTP filters are not modified')

        if diff and not dryrun:
            err = fq.add (pffile, txt)
            if err:
                nm.grmbl (err)

            #
            # Install files and run command
            #

            err = fq.commit ()

            #
            # Test file
            #

            if pftest != '':
                (r, msg) = utils.run (pftest)
                if r != 0:
                    fq.uncommit ()
                    nm.grmbl ("Command failed: {}\n{}".format (pftest, msg))


            #
            # Notify changes
            #

            if pfcmd != '':
                (r, msg) = utils.run (pfcmd)
                if r != 0:
                    fq.uncommit ()
                    nm.grmbl ("Command failed: {}\n{}".format (pfcmd, msg))

        #
        # Allow other mksmtpf to run
        # (not really needed since the process exit will automatically
        # remove the advisory file lock)
        #

        lck.unlock ()

    sys.exit (0)

if __name__ == '__main__':
    main ()
