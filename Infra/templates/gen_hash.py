#!/usr/bin/env python

# generate_pw_hash uses iPython and urandom to first generate a random Password
# and run SHA1 hashing algorithm on it. It uses the template file to
# append the generated SHA1 to jupyter_config.py. This will enable user
# to directly login with the password and not have to manage password on his own.

from IPython.lib import passwd
import os
import sys
path=sys.argv[1]+'/passwd_hash'+'.txt'
print(os.environ)
print("STUFF: ", path)
with open(path, 'w') as f:
    f.write(passwd(os.environ['NOTEBOOK_PASSWD']))
