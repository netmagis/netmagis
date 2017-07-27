#!/usr/bin/env python3

#
# Syntax:
#   mkdhcp [-l libdir][-f configfile][-t][-q][-v][-n] [-w] [<view-name>]
#

import sys
import os.path
import argparse

tmpl = {
'subnet': """
# {comment}
subnet {addr} netmask {netmask} {{
    option routers {gw};
    {ranges}
    {hosts}
}} # end {comment}
""",
'range': """
    pool {{
        {failover}
        range {min} {max};
        deny dynamic bootp clients;
        option domain-name "{domain}";
        max-lease-time {max_lease_time};
        default-lease-time {default_lease_time};
        {profile}
    }}
""",
    'host': """
    host {name} {{
        stash-agent-options true;
        hardware ethernet {mac};
        fixed-address {addr};
        option host-name "{name}";
        {profile}
    }}
""",
}

# return list of modified views
def fetch_modified_views (nm, view):
    params = None
    if view is not None:
        params = {'view': view, 'gen': 1}
    else:
        params = {'gen': 1}

    r = nm.api ('get', '/gen/dhcp', params=params)
    j = r.json ()

    views = []
    for vj in j:
        views.append (vj ['name'])

    return views

# generate a DHCP file as a string containing all data
# return (counter, data)
def generate_view (nm, v, failover):
    r = nm.api ('get', '/gen/dhcp/' + v)
    j = r.json ()

    counter = j ['counter']

    default_lease_time = j ['default_lease_time']
    max_lease_time = j ['max_lease_time']
    min_lease_time = j ['min_lease_time']
    dhcpdefdomain = j ['dhcpdefdomain']
    dhcpdefdnslist = j ['dhcpdefdnslist']

    profiles = j ['profiles']
    subnets = j ['subnets']
    ranges = j ['ranges']
    hosts = j ['hosts']

    txt = ''

    #
    # Make some ids directly addressable
    #

    optdns = 'option domain-name-servers {};'.format (dhcpdefdnslist)
    tabprof = {None: optdns}
    for p in profiles:
        proftxt = p ['text']
        if 'domain-name-servers' not in proftxt:
            proftxt += '\n' + optdns
        tabprof [p ['name']] = proftxt

    tabsub = {}
    for s in subnets:
        nw = s ['network']
        tabsub [nw] = {'hosts': [], 'ranges': []}

    for r in ranges:
        nw = r ['network']
        tabsub [nw]['ranges'].append (r)

    for h in hosts:
        nw = h ['network']
        tabsub [nw]['hosts'].append (h)

    #
    # Generate subnets
    #

    for s in subnets:
        nw = s ['network']

        #
        # Gather ranges
        #

        rtxt = ''
        for r in tabsub [nw]['ranges']:
            r ['profile'] = tabprof [r ['profile']]
            r ['failover'] = failover
            r ['dhcpdefdnslist'] = dhcpdefdnslist

            if r ['default_lease_time'] == 0:
                r ['default_lease_time'] = default_lease_time
            if r ['max_lease_time'] == 0:
                r ['max_lease_time'] = max_lease_time

            rtxt += tmpl ['range'].format (**r)

        #
        # Gather hosts
        #

        htxt = ''
        for h in tabsub [nw]['hosts']:
            h ['profile'] = tabprof [h ['profile']]
            htxt += tmpl ['host'].format (**h)

        #
        # Print subnet
        #

        s ['ranges'] = rtxt
        s ['hosts'] = htxt

        txt += tmpl ['subnet'].format (**s)

    return (counter, txt)


def main ():
    parser = argparse.ArgumentParser (description='Netmagis DHCP generation')
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

    lockfile = nm.getconf ('mkdhcp', 'lockfile')
    dhcpfile = nm.getconf ('mkdhcp', 'dhcpfile')
    dhcpfailover = nm.getconf ('mkdhcp', 'dhcpfailover')
    dhcptest = nm.getconf ('mkdhcp', 'dhcptest')
    dhcpcmd = nm.getconf ('mkdhcp', 'dhcpcmd')

    #
    # Prevent multiple runs
    #

    with nmlock (lockfile) as lck:

        if not lck.trylock ():
            if verbose:
                print ('Mkdhcp already running. Abort', file=sys.stderr)
            sys.exit (0)

        #
        # Initialize fq engine
        #

        fq = fileinst ()

        #
        # Fetch modified views (and filter result if view is provided)
        #

        views = fetch_modified_views (nm, view)

        if not views:
            if verbose:
                print ('No generation needed')
            sys.exit (0)

        if len (views) > 1:
            print ('Mkdhcp does not support multiple views', file=sys.stderr)
            sys.exit (1)

        #
        # For each view (warning: generates junk if multiple views)
        #

        reg = []
        v = views [0]

        #
        # Generate file contents
        #

        (counter, txt) = generate_view (nm, v, dhcpfailover)

        reg.append ({'name': v, 'counter': counter})

        #
        # Show diffs
        #

        if verbose:
            utils.diff_file_text (dhcpfile, txt)

        #
        # Output generated data to file
        #

        if not dryrun:
            err = fq.add (dhcpfile, txt)
            if err:
                nm.grmbl (err)


        #
        # Install files and run command
        #

        if not dryrun:
            err = fq.commit ()

            #
            # Test DHCP configuration
            #
            if dhcptest != '':
                (r, msg) = utils.run (dhcptest)
                if r != 0:
                    fq.uncommit ()
                    nm.grmbl ("Command failed: {}\n{}".format (dhcptest, msg))

            #
            # Reload DHCP daemon
            #

            if dhcpcmd != '':
                (r, msg) = utils.run (dhcpcmd)
                if r != 0:
                    fq.uncommit ()
                    nm.grmbl ("Command failed: {}\n{}".format (dhcpcmd, msg))

            #
            # Register generation
            # POST /gen/dhcp with view counters
            #

            r = nm.api ('post', '/gen/dhcp', json=reg, check=False)
            if r.status_code != 200:
                fq.uncommit ()
                msg = 'Cannot register DHCP generation, server returned {}\n{}'
                nm.grmbl (msg.format (r.status_code, r.reason))

        #
        # Allow other mkdhcp to run
        # (not really needed since the process exit will automatically
        # remove the advisory file lock)
        #

        lck.unlock ()

    sys.exit (0)

if __name__ == '__main__':
    main ()
