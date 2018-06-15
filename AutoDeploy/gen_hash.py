from IPython.lib import passwd
import os
import sys
path=sys.argv[1]+'/passwd_hash-'+sys.argv[2]+'.txt'
with open(path, 'w') as f:
    f.write(passwd(os.environ['NOTEBOOK_PASSWD']))
