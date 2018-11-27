#!/bin/sh

# Scan sysfs for nodes and trigger module loading and other coldplug
# business... (scanning for 'modalias' is not enough as it may
# miss some necessary actions on nodes which don't use modules).
#
# This script is run early (S15loadmods) to cold-plug drivers in
# the root filesystem and later (from S42nfsmount), after mounting NFS shares
# in case a directory with modules is mounted.

find /sys -name uevent -exec sh -c 'echo -n add > {}' \;
