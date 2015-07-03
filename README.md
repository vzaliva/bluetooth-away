bluetooth-away
===========

The motivation for this project was to hack a simple script which will
keep Nest termostat from switching to 'away' mode while user is
present. To detect user presence we have chosen to check his phone
proximuty using his phone bluetooth connection.

We run it on RasbperryPI with bluetooth dongle, but it could be used
on any Linux machine,

See `config.cfg` for configuration.

Vadim Zaliva <lord@crocodile.org>

Credits:
--------

  * Original Script: https://github.com/jotson/bluetooth-lock
  * PyNest (patched to support 'away' command): https://github.com/RandyLevensalor/pynest

