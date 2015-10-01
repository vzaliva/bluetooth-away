bluetooth-away
===========

The motivation for this project was to hack a simple script which will
keep Nest termostat from switching to 'away' mode while user is
present. To detect user presence we have chosen to check his phone
proximuty using his phone bluetooth connection.

We run it on RasbperryPI with bluetooth dongle, but it could be used
on any Linux machine,

Config
------

Realistic config to keep Nest from going into AWAY mode:

    {
    "Device": "20:6E:9C:95:2B:E7",
    "Interval" : 600,
    "Attempts" : 1,
    "Triggers": {
         "found": "nest.py --user user@example.com --password 'secret123' away here",
         "available": "nest.py --user user@example.com --password 'secret123' away here"
    }
    }

See `config.cfg` for more configration options.

Running
-------

    ./bluetooth-away.py [-f <cfg file>] [-c] [-d]
    
    -c -- log to console instead of log file
    -d -- debug
    -f <cfg file> -- config file name. Default is 'bluetooth-away.cfg'

Implementation Notes
-------------------

Two implementations are provided. The original one was in Python, but
latter it was rewritten as an excercise in OCaml. They are
functionally equivalent, and support same command line optons and
config file format.

To compile OCaml version you need to install additional packages using
followin command

    opam install omake getopt yojson bolt

Credits
------

  * Original Script: https://github.com/jotson/bluetooth-lock
  * PyNest (patched to support 'away' command): https://github.com/RandyLevensalor/pynest
  * Author: Vadim Zaliva <lord@crocodile.org>

