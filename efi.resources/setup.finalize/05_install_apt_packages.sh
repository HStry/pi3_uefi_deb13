#!/usr/bin/env sh

apt-get update
apt-get -y upgrade

apt-get install -y \
  bind9-dnsutils \
  bind9-utils \
  binutils \
  ca-certificates \
  curl \
  gpg \
  iputils-arping \
  iputils-ping \
  lvm2 \
  rsync \
  tmux \
  tree \
  unzip \
  vim \
  zip \
  zram-tools

apt-mark -y minimize-manual

zramconf='/etc/default/zramswap'
cp -a "${zramconf}" "${zramconf}.dpkg-dist"
cat << EOF > "${zramconf}"
ALGO=zstd
SIZE=256
PRIORITY=100
EOF
