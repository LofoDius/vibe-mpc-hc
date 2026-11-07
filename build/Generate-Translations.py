"""Generate language resources using the original Python 2 translation tools."""
import glob
import os
import sys

resources = os.path.abspath(os.path.join(os.path.dirname(__file__),
                                       '../src/mpc-hc/mpcresources'))
os.chdir(resources)
sys.path.insert(0, resources)

from UpdateRC import UpdateRC

for config in sorted(glob.glob('cfg/mpc-hc.*.cfg')):
    name = os.path.splitext(os.path.basename(config))[0]
    print('Generating ' + name)
    UpdateRC(name, False)
