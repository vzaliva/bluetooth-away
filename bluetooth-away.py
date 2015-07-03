#!/usr/bin/env python

import sys
import os
import shutil
from optparse import OptionParser
import subprocess
import time
import json
import time,datetime
import string
import getopt
import logging

CFG_FILE="bluetooth-away.cfg"
LOG_FILE="bluetooth-away.log"

class State:
    OK = 1
    ERR = 2

def usage():
    print """
%s [-f <cfg file>] [-c] [-d]

-c -- log to console instead of log file
-d -- debug
-f <cfg file> -- config file name. Default is '%s'
"""  % (sys.argv[0], CFG_FILE)

def read_config(cfg_fname):
    log.info("Reading config file %s" % cfg_fname)
    f=open(cfg_fname,"r")
    try:
        return json.load(f)
    finally:
        f.close()

def main():
    global log
    global debug_mode

    try:
        opts, args = getopt.getopt(sys.argv[1:], 'dcf:', [])
    except getopt.GetoptError:
        usage()
        sys.exit(2)

    console = False
    debug_mode = False
    cfg_fname = CFG_FILE

    for o, a in opts:
        if o in ['-d']:
            debug_mode = True
        elif o in ['-c']:
            console = True
        elif o in ['-f']:
            cfg_fname = a
        else:
            usage()
            sys.exit(1)

    log_format = '%(asctime)s %(process)d %(filename)s:%(lineno)d %(levelname)s %(message)s'
    if debug_mode:
        log_level=logging.DEBUG
    else:
        log_level=logging.INFO
    if console:
        logging.basicConfig(level=log_level, format=log_format)
    else:
        logging.basicConfig(level=log_level, format=log_format,
                            filename=LOG_FILE, filemode='a')
    log = logging.getLogger('default')

    try:
        cfg = read_config(cfg_fname)
    except Exception, ex:
        log.error("Error reading config file %s" % ex)
        sys.exit(1)

    device = cfg["Device"]
    check_interval = int(cfg["Interval"])
    check_attempts = int(cfg["Attempts"])
    log.info("Monitoring %s every %d seconds" % (device, check_interval))

    # We assume that device is initially unrecheable
    mode = State.ERR

    while True:
        tries = 0
        while tries < check_attempts:
            # for debugging on Mac simulate Linux ping via file check
            #process = subprocess.Popen(['cat', "fake"], shell=False, stdout=subprocess.PIPE)
            process = subprocess.Popen(['sudo', '/usr/bin/l2ping', device, '-t', '1', '-c', '1'], shell=False, stdout=subprocess.PIPE)
            process.wait()
            if process.returncode == 0:
                log.debug("ping OK")
                break
            log.debug("ping response code: %d" % (process.returncode))
            time.sleep(1)
            tries = tries + 1

        if process.returncode == 0:
            if mode == State.OK:
                cmd = cfg["Triggers"].get("available",None)
            else:
                cmd = cfg["Triggers"].get("found",None)
            mode = State.OK
        else:
            if mode == State.OK:
                cmd = cfg["Triggers"].get("lost",None)
            else:
                cmd = cfg["Triggers"].get("not_available",None)
            mode = State.ERR

        if cmd:
            log.debug("executing %s",cmd)
            subprocess.call(cmd, shell=True)

        time.sleep(check_interval)

if __name__ == "__main__":
    main()
