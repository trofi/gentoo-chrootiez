#!/bin/sh

script_base=gentoo-chrootiez

exec unshare --mount \
     "$script_base"/scripts/run_chroot_unshared.sh "$@"

echo "WARNING: unshare not found, only chroot facility will be used"
exec "$script_base"/scripts/run_chroot_unshared.sh "$@"
