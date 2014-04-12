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
cp /etc/locale.gen   "$chroot_path"/etc/locale.gen
cp "$chroots_base"/$script_base/scripts/run_from_chroot "$chroot_path"/run_from_chroot

# unshare whole mount namespace
mount --make-rprivate /

for d in "$chroots_base"/$script_base/bound/*
do
    if [ -d "$d" ]; then
        base_d=$(basename "$d")
        dest_d=$chroot_path/bound/$base_d

        mkdir -p "$dest_d"
        mount --bind "$d" "$dest_d"
    fi
done

mount -t proc   proc   "$chroot_path"/proc
mount -t sysfs  sysfs  "$chroot_path"/sys
mount -t devpts devpts -onewinstance,ptmxmode=0666,mode=620,gid=5 "$chroot_path"/dev/pts
mount -t tmpfs  tmpfs  "$chroot_path"/dev/shm

setarch_wrapper=
case "$chroot_bits" in
    32|64) setarch_wrapper=linux$chroot_bits ;;
esac
info "entering chroot ..."
$setarch_wrapper /usr/bin/chroot "$chroot_path" /run_from_chroot "$@"
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
