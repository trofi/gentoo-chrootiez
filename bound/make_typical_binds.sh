#!/bin/sh

ln -s "$(portageq envvar PORTDIR)" portage
ln -s "$(portageq envvar DISTDIR)" distfiles
