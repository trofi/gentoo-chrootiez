#!/bin/sh

script_base=gentoo-chrootiez
cfg="$script_base"/chrootiez_config

if [ -f "${cfg}" ]; then
    . "${cfg}"
    # used only locally
    #export CHROOTIEZ_UNSHARE_EXTRA_OPTS
    # used in child mount
    export CHROOTIEZ_DEVPTS
else
    echo "HINT from '${0}': you can create '${cfg}'"
    echo '    which recognizes the following variables:'
    echo '    CHROOTIEZ_UNSHARE_EXTRA_OPTS - arguments passed to'
    echo "           'unshare' before 'chroot'; very handy to unshare"
    echo '            everything including network.'
    echo '    CHROOTIEZ_DEVPTS={newinstance|host|none} - mounts new devpts instance'
    echo "            'newinstance' requires kernel support of CONFIG_DEVPTS_MULTIPLE_INSTANCES=y."
    echo '            WARNING: setting this variable without kernel support'
    echo '                     will break ptys on your host system (xterm, screen will stop working).'
    echo "                     To fix the damage run: 'mount -oremount /dev/pts'"
    echo ''
    echo '      Example:'
    echo '        CHROOTIEZ_UNSHARE_EXTRA_OPTS="--ipc --mount --pid --uts --fork --user --map-root-user"'
    echo '        CHROOTIEZ_DEVPTS=newinstance'
fi

exec unshare $CHROOTIEZ_UNSHARE_EXTRA_OPTS --mount \
     "$script_base"/scripts/run_chroot_unshared.sh "$@"

# won't work anyways
unset CHROOTIEZ_DEVPTS
echo "WARNING: unshare not found, only chroot facility will be used"
exec "$script_base"/scripts/run_chroot_unshared.sh "$@"
