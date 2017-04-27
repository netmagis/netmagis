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

    @staticmethod
    def grmbl (msg):
        print (msg, file=sys.stderr)
        sys.exit (1)

    @staticmethod
    def test_answer (req):
        if req.status_code != 200:
            grmbl ('Server error {} ({})'.format (req.status_code, req.reason))
