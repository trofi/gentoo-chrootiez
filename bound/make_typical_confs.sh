#!/bin/sh

makeopts=auto

for a; do
    case "$a" in
        --makeopts=*)
            makeopts=${a#--makeopts=}
            ;;
        *)
            die "unknown option: $a"
            ;;
    esac
done

if [ "${makeopts}" = auto ]; then
    makeopts=$(expr `nproc` + 1)
fi

cat >conf/make.conf.local <<EOF
MAKEOPTS=-j${makeopts}
FEATURES="\${FEATURES} test"
EOF
