#!/bin/sh

script_name=$0
script_base=gentoo-chrootiez

die()  { echo "$script_name: ERROR: $@"; exit 1; }
warn() { echo "$script_name: WARN:  $@"; }
info() { echo "$script_name: INFO:  $@"; }

[ $(id -u) = 0 ] || die "Sorry, I need root privileges to 'mount --bind' and 'chroot'"
[ -n "$1" -a -n "$2" ] || die "usage: $0 <chroot-dir> <32 | 64 | as-is> [command to run]"

chroot_name="$1"; shift
chroot_bits="$1"; shift

chroots_base=$(pwd)
chroot_path=$chroots_base/$chroot_name

mkdir -vp "$chroot_path"/bound

cp /etc/resolv.conf  "$chroot_path"/etc/resolv.conf
cp /etc/hosts        "$chroot_path"/etc/hosts
cp /etc/localtime    "$chroot_path"/etc/localtime
cp "$chroots_base"/$script_base/scripts/run_from_chroot "$chroot_path"/run_from_chroot

# unshare whole mount namespace
mount --make-rprivate /

# pass through our current (pseudo)terminal as current console
touch "$chroot_path"/dev/console
mount --bind "$(tty)" "$chroot_path"/dev/console

# pass through other basic /dev/* as-is
for f in full null random tty urandom zero; do
    touch "$chroot_path"/dev/"${f}"
    mount --bind /dev/"${f}" "$chroot_path"/dev/"${f}"
done

for d in "$chroots_base"/$script_base/bound/*
do
    if [ -d "$d" ]; then
        base_d=$(basename "$d")
        dest_d=$chroot_path/bound/$base_d

        mkdir -p "$dest_d"
        mount --bind "$d" "$dest_d"
    fi
done

mkdir -vp "$chroot_path"/dev/pts
mkdir -vp "$chroot_path"/dev/shm

mount -t proc   proc   "$chroot_path"/proc
mount -t sysfs  sysfs  "$chroot_path"/sys

# See linux/Documentation/filesystems/devpts.txt on
# semantics on /dev/pts in each mode.
case "${CHROOTIEZ_DEVPTS}" in
    newinstance)
        mount -t devpts devpts -onewinstance,ptmxmode=0666,mode=620,gid=5 "$chroot_path"/dev/pts
        # don't use the default one
        rm -v "$chroot_path"/dev/ptmx
        ln -fsv pts/ptmx "$chroot_path"/dev/ptmx
        ;;
    host)
        mount --bind /dev/pts "$chroot_path"/dev/pts
        if [ -L "$chroot_path"/dev/ptmx ]; then
            # restore from possible previous newinstance setup
            warn "restoring '$chroot_path/dev/ptmx' to defaults:"
            rm -v "$chroot_path"/dev/ptmx
            mknod -m666 "$chroot_path"/dev/ptmx c 5 2
            ls -l "$chroot_path"/dev/ptmx
        fi
        ;;
    none)
        ;;
    *)
        echo "CHROOTIEZ_DEVPTS has unknown '${CHROOTIEZ_DEVPTS}' value, assuming 'none'"
        ;;
esac
mount -t tmpfs  tmpfs  "$chroot_path"/dev/shm


setarch_wrapper=
case "$chroot_bits" in
    32|64) setarch_wrapper=linux$chroot_bits ;;
esac
info "entering chroot ..."
$setarch_wrapper chroot "$chroot_path" /run_from_chroot "$@"
# for daemons you might like to use:
#>$chroots_base/$chroot_name.log 2>&1
info "... exited from chroot"

for d in /dev/shm /dev/pts /sys /proc
do
    umount $chroot_path"/$d"
done

# TODO: save actually mounted list and iterate thru
#       it in reverse order
for d in "$chroots_base"/$script_base/bound/*
do
    if [ -d "$d" ]; then
        base_d=$(basename "$d")
        dest_d=$chroot_path/bound/$base_d

        umount "$dest_d"
    fi
done
