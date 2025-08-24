#!/usr/bin/env sh

_self="$(realpath -s $0)"
_path="$(dirname "${_self}")"
_file="$(basename "${_self}")"
_name="${_file%.*}"

_deploy_files() (
  source="${1}"; shift
  target="${1}"; shift
  mode="${1}"; shift
  user="${1:-$(id -u)}"; shift
  group="${1:-$(id -g)}"; shift

  [ -n "${source}" ] || exit 0
  [ -d "${source}" ] || exit 0
  [ -n "${target}" ] || exit 0
  [ -d "${target}" ] || exit 0

  source="$(realpath "${source}")"
  target="$(realpath "${target}")"

  for f in "${source}/"*; do
    [ -n "${f}" ] || continue  # skip empty values
    [ -f "${f}" ] || continue  # skip non-files
    [ -s "${f}" ] || continue  # skip empty files
    fn="$(basename "${f}")"
    echo "${target}/${fn}" >&2
    cp "${f}" "${target}"
    chown "${user}" "${target}/${fn}"
    chgrp "${group}" "${target}/${fn}"
    chmod "${mode}" "${target}/${fn}"
  done
)

_deploy_files "${_path}/apt.keyrings"  "/etc/apt/keyrings"       644 root root
_deploy_files "${_path}/apt.sources"   "/etc/apt/sources.list.d" 644 root root
_deploy_files "${_path}/usr.local.bin" "/usr/local/bin"          755 root root
_deploy_files "${_path}/usr.local.lib" "/usr/local/lib"          655 root root
_deploy_files "${_path}/etc.profile.d" "/etc/profile.d"          655 root root
