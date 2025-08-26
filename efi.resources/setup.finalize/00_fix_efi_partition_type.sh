#!/usr/bin/env sh

ROOT_DEV="${ROOT_DEV:-/dev/mmcblk0}"

if [ -z "${ROOT_DEV}" ]; then
  echo "Something went wrong. Variable ROOT_DEV should not be able to be empty." >&2
  exit 1
elif ! [ -e "${ROOT_DEV}" ]; then
  echo "ROOT_DEV '${ROOT_DEV}' appears not to exist." >&2
  exit 1
elif ! [ -b "${ROOT_DEV}" ]; then
  echo "ROOT_DEV '${ROOT_DEV}' is not a block device." >&2
  exit 1
fi

for c in 't' '1' '0e' 'w'; do
  echo "${c}"
  sleep 0.2
done | fdisk "${ROOT_DEV}"
