import os
import sys

class fileinst:
    def __init__ (self):
        self._state = 'init'        # values in ['init', 'nonempty', 'commit']
        self._fileq = []

    def add (self, name, content):
        err = None
        if self._state in ['init', 'nonempty']:
            try:
                nf = name + '.new'
                if os.path.exists (nf):
                    os.remove (nf)
                with open (nf, 'w') as fd:
                    fd.write (content)

                self._fileq.append (name)
                self._state = 'nonempty'
            except Exception as m:
                err = str (m)
        else:
            err = 'cannot add file: state != init and state != nonempty'

        return err

    def _file_rename (self, old, new, force=False):
        err = None
        if force:
            if os.path.exists (new):
                try:
                    os.remove (new)
                except:
                    pass
        if os.path.exists (old):
            try:
                os.rename (old, new)
            except Exception as m:
                err = 'Cannot move ' + old + ' to ' + new + '\n' + str (m)
        return err

    def commit (self):
        err = None
        if self._state not in ['init', 'nonempty']:
            err = 'Cannot commit files: state != init and state != nonempty'
        else:
            state = 0
            for i, f in enumerate (self._fileq):
                nf = f + '.new'
                of = f + '.old'

                # step 1: create an empty file is f does not exist
                state = 0
                if not os.path.exists (f):
                    try:
                        with open (f, 'w'):
                            pass
                    except Exception as m:
                        err = 'Cannot create ' + f
                        err += '\n' + str (m)
                        break

                # step 2: make a backup of original file if it exists
                state = 1
                err = self._file_rename (f, of, force=True)
                if err is not None:
                    break

                # step 3: install new file
                state = 2
                err = self._file_rename (nf, f, force=False)
                if err is not None:
                    break

            # check if loop succeeded
            if err is None:
                self._state = 'commit'
            else:
                # reset files in state before the failed commit attempt
                # (we stopped at file number i inclusive)
                uerr = []
                for j, f in enumerate (self._fileq):
                    if j < i:
                        s = 3           # all operations ok for file j
                    elif j == i:
                        s = state       # operations ok for file i until state
                    else:
                        break

                    nf = f + '.new'
                    of = f + '.old'

                    e = None
                    if s <= 1:
                        break
                    elif s == 2:
                        e = self._file_rename (of, f, force=True)
                    elif s == 3:
                        e = self._file_rename (f, nf, force=True)
                        if e is None:
                            e = self._file_rename (of, f, force=True)
                    else:
                        e = 'Internal error: invalid state ' + str (s)
                        e += ' for file ' + f

                    if e is not None:
                        uerr.append (e)

                # End of loop. Leave an appropriate message:
                err += '\n'
                if len (uerr):
                    err += 'Errors occurred while uncommitting changes:\n'
                    err += '\n'.join (uerr)
                else:
                    err += 'Files restored in their original state'

                self._state = 'error'

        return err

    def uncommit (self):
        err = None
        if self._state != 'commit':
            err = 'Cannot uncommit files: state != commit'
        else:
            uerr = []
            for f in self._fileq:
                nf = f + '.new'
                of = f + '.old'

                e = self._file_rename (f, nf, force=True)
                if e is None:
                    e = self._file_rename (of, f, force=True)

                if e is not None:
                    uerr.append (e)

            if len (uerr):
                err = '\n'.join (uerr)
                self._state = 'error'
            else:
                self._state = 'nonempty'

        return err

    def abort (self):
        err = None
        if self._state not in ['init', 'nonempty'] :
            err = 'Cannot abort: state != init and state != nonempty'
        else:
            uerr = []
            for f in self._fileq:
                nf = f + '.new'
                try:
                    os.remove (nf)
                except Exception as m:
                    e = 'Cannot remove ' + nf + '\n' + str (m)
                    uerr.append (e)

            if len (uerr):
                err = '\n'.join (uerr)
                self._state = 'error'
            else:
                self._fileq = []
                self._state = 'init'

        return err
