#!/bin/sh

cat >conf/make.conf.local <<EOF
MAKEOPTS=-j$(expr `nproc` + 1)
FEATURES="\${FEATURES} test"
EOF
