#!/usr/bin/env python3

#
# Syntax:
#   dnsaddhost <fqdn> <ip> <viewname>
#
# This scripts uses a configuration file for authentication purpose
#   ~/.config/netmagisrc
#       [general]
#           url = https://app.example.com/netmagis
#           key = a-secret-key-delivered-by-netmagis
#

import argparse
import configparser
import os
import sys
import re

import requests

class netmagis:
    def __init__ (self):
        self._url = None
        self._key = None
        self._domains = None
        self._views = None

    @staticmethod
    def default_conf_filename ():
        return os.path.expanduser ('~') + '/.config/netmagisrc'

    def read_conf (self, filename):
        self._url = None
        self._key = None

        config = configparser.ConfigParser ()
        if not config.read (filename):
            raise RuntimeError ('Cannot read ' + filename)

        try:
            self._url = config ['general']['url']
            self._key = config ['general']['key']
        except KeyError as m:
            raise RuntimeError ('File {}: {} not found'.format (filename, str (m)))

        return

    def api (self, verb, url, params=None, json=None):
        url = self._url + url
        cookies = {'session': self._key}
        r = requests.request (verb, url, cookies=cookies, params=params, json=json)
        # XXX : check if not authenticated or other non-api errors
        # (server not found, ...)
        return r

    def _read_domains (self):
        res = self.api ('get', '/domains')
        return res.json ()

    def get_iddom (self, name):
        if self._domains is None:
            self._domains = self._read_domains ()
        iddom = None
        for j in self._domains:
            if j ['name'] == name:
                iddom = j ['iddom']
                break
        return iddom

    def _read_views (self):
        res = self.api ('get', '/views')
        return res.json ()

    def get_idview (self, name):
        if self._views is None:
            self._views = self._read_views ()
        idview = None
        for j in self._views:
            if j ['name'] == name:
                idview = j ['idview']
                break
        return idview

    def split_fqdn (self, fqdn):
        m = re.match (r'^([^.]+)\.(.+)', fqdn)
        if m is None:
            return (None, None, None)
        (local, domain) = m.groups ()
        iddom = self.get_iddom (domain)
        return (local, domain, iddom)


def grmbl (msg):
    print (msg, file=sys.stderr)
    sys.exit (1)

def test_answer (req):
    if req.status_code != 200:
        grmbl ('Server error {} ({})'.format (req.status_code, req.reason))

def main ():
    parser = argparse.ArgumentParser (description='Netmagis add host')
    parser.add_argument ('-c', '--config-file', action='store',
                help='Config file location (default=~/.config/netmagisrc)')
    parser.add_argument ('fqdn', help='Host FQDN')
    parser.add_argument ('ip', help='IP (v4 or v6) address to add')
    parser.add_argument ('view', help='View name')

    args = parser.parse_args ()
    if args.config_file is None:
        configfile = netmagis.default_conf_filename ()

    fqdn = args.fqdn
    ip = args.ip
    view = args.view

    nm = netmagis ()
    try:
        nm.read_conf (configfile)
    except RuntimeError as m:
        grmbl (m)

    (name, domain, iddom) = nm.split_fqdn (fqdn)
    if name is None:
        grmbl ('Invalid FQDN {}'.format (fqdn))
    if iddom is None:
        grmbl ('Unknown domain {}'.format (domain))

    idview = nm.get_idview (view)
    if not idview:
        grmbl ('Unknown view {}'.format (view))

    #
    # Test if host already exists
    #

    query = {'name': name, 'domain': domain, 'view': view}
    r = nm.api ('get', '/hosts', params=query)
    test_answer (r)

    j = r.json ()
    nr = len (j)
    if nr == 0:
        #
        # Host does not exist: use a POST request to create the jost
        #

        # TODO : find a way to get a default HINFO value (API change requested)
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
        r = nm.api ('post', '/hosts', json=data)
        test_answer (r)

    elif nr == 1:
        #
        # Host already exists: get full data with an additional GET
        # request for this idhost, and use a PUT request to add the
        # new IP address
        #

        idhost = j [0]['idhost']
        uri = '/hosts/' + str (idhost)
        r = nm.api ('get', uri)
        test_answer (r)

        data = r.json ()
        data ['addr'].append (ip)
        r = nm.api ('put', uri, json=data)
        test_answer (r)

    else:
        # this case should never happen
        msg = "Server error: host '{}.{}' exists more than once in view {}"
        grmbl (msg.format (name, domain, view))

if __name__ == '__main__':
    main ()
