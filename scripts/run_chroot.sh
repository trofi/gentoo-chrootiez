#!/bin/sh

script_base=gentoo-chrootiez

[ -f "$script_base"/chrootiez_config ] && . "$script_base"/chrootiez_config

exec unshare $CHROOTIEZ_UNSHARE_EXTRA_OPTS --mount \
     "$script_base"/scripts/run_chroot_unshared.sh "$@"

echo "WARNING: unshare not found, only chroot facility will be used"
exec "$script_base"/scripts/run_chroot_unshared.sh "$@"
