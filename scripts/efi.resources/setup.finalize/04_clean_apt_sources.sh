#!/usr/bin/env sh

rm -f /etc/apt/sources.list /etc/apt/sources.list~
apt-get -y clean
apt-get -y distclean
