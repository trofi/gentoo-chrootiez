#!/bin/sh

script_base=gentoo-chrootiez

# fault-propagation wise --mount is good-enough
exec unshare --fork --mount --ipc --pid --uts \
     "$script_base"/scripts/run_chroot_unshared.sh "$@"

echo "WARNING: unshare not found, only chroot facility will be used"
exec "$script_base"/scripts/run_chroot_unshared.sh "$@"
