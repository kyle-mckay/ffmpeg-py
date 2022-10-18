import subprocess
import command, os
#ffprobe "/home/kyle/Downloads/A Couple of Cuckoos/Season 1/A.Couple.of.Cuckoos.S01E16.I.want.to.talk.about.now.HDTV-1080p.mkv" -v quiet -show_entries format=bit_rate -of default=noprint_wrappers=1:nokey=1)
path = "/home/kyle/Downloads/A Couple of Cuckoos/Season 1/A.Couple.of.Cuckoos.S01E16.I.want.to.talk.about.now.HDTV-1080p.mkv"
probes = "-v quiet -show_entries format=bit_rate -of default=noprint_wrappers=1:nokey=1"
os.system(f'ffprobe "{path}" {probes}')

import os, sys, subprocess, shlex, re
from subprocess import call
def probe_file(filename):
    cmnd = ['ffprobe', '-v', 'quiet', '-show_entries', 'format=bit_rate', '-of', 'default=noprint_wrappers=1:nokey=1', filename]
    p = subprocess.Popen(cmnd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    print (filename)
    out, err =  p.communicate()
    print("==========output==========")
    print (out)
    if err:
        print ("========= error ========")
        print (err)

probe_file(path)