import os
import sys
import subprocess

#
# Show diffs (on stdout) between a file and a text
#

def show_diff_file_text (diffcmd, fname, txt):
    if not os.path.exists (fname):
        fname = '/dev/null'
    diffcmd = (diffcmd % fname) #############################+ ' || exit 0'

    txt = txt.encode ()
    with subprocess.Popen(diffcmd, shell=True, stdin=subprocess.PIPE, close_fds=True) as p:
        p.stdin.write (txt)
