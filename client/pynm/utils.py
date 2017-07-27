import sys
import os
import difflib
import subprocess

# return verbose level as -1 (quiet), 0 (normal) or 1 (verbose)
def verbosity (quiet, verbose):
    v = 0
    if quiet:
        v = -1
    elif verbose:
        v = 1
    return v

#
# Show diffs (on stdout) between a file and a text
# Returns True if they differ
#

def diff_file_text (fname, txt, show=True):
    #
    # Read existing file as a list of strings
    #

    if os.path.exists (fname):
        with open (fname, 'r') as f:
            old = f.readlines ()
    else:
        old = []

    #
    # Convert new text into a list of strings (terminated by \n)
    #

    new = txt.splitlines (keepends=True)

    #
    # Diff contents
    #

    d = difflib.unified_diff (old, new, fromfile=fname, n=0)
    ld = list (d)
    if show:
        sys.stdout.writelines (ld)

    return bool (ld)


#
# Run a command and returns (exit code, stderr-if-exitcode-not-null)
#

def run (cmd):
    r = 0
    stderr = None
    try:
        l = ['sh', '-c', cmd]
        subprocess.check_output (l, stderr=subprocess.STDOUT)
    except subprocess.CalledProcessError as err:
        r = err.returncode
        stderr = err.output
        try:
            # stderr is a binary string: decode it in order to
            # have a beautiful error message
            stderr = stderr.decode ()
        except:
            pass
    return (r, stderr)
