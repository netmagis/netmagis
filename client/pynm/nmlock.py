#!/usr/bin/env python3

# Python >= 3.3

import os
import fcntl

class nmlock:
    def __init__ (self, fname, writepid=True):
        self._fd = os.open (fname, os.O_WRONLY | os.O_CREAT, mode=0o644)
        self._writepid = writepid

    def __del__ (self):
        os.close (self._fd)

    def __enter__ (self):
        return self

    def __exit__ (self, exc_type, exc_value, traceback):
        pass

    def _writemypid (self):
        if self._writepid:
            os.ftruncate (self._fd, 0)
            os.write (self._fd, str (os.getpid ()).encode ())
        return

    def lock (self):
        r = fcntl.lockf (self._fd, fcntl.LOCK_EX)
        self._writemypid ()

    def unlock (self):
        r = fcntl.lockf (self._fd, fcntl.LOCK_UN)
        os.ftruncate (self._fd, 0)

    def trylock (self):
        r = True
        try:
            fcntl.lockf (self._fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
            self._writemypid ()
        except BlockingIOError:
            r = False
        return r
