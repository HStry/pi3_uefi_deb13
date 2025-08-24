#!/usr/bin/env sh

_self="$(realpath -s "$0" 2>/dev/null || realpath "$0")" # F* busybox.
_path="$(dirname "${_self}")"
_file="$(basename "${_self}")"
_name="${_file%.*}"

lv_parts_default="$(cat << EOF
    'root,        12G, /,              ext4'
    'home,         2G, /home,          ext4'
    'var,          4G, /var,           ext4'
    'varlog,       3G, /var/log,       ext4'
    'varlogaudit,  2G, /var/log/audit, ext4'
    'vartmp,       1G, /var/tmp,       ext4'
    'tmp,          1G, /tmp,           ext4'
EOF
)"

help=0
force=0
devices=
firmware=
vg_name=
lv_parts=

parse_args=1
active_arg=

for arg in "$@"; do
  [ ${parse_args} -gt 0 ] && [ "${arg}" = '--' ] && parse_args=0 && continue
  [ ${parse_args} -le 0 ] && [ "${arg}" = '++' ] && parse_args=1 && continue
  [ ${parse_args} -gt 0 ] && [ "${arg#--}" != "${arg}" ] && \
  case "$(echo "${arg#--}" | sed -e 's/-/_/g')" in
    'help')     help=1;;
    'force')    force=1;;
    'firmware') active_arg='firmware';;
    'vg_name')  active_arg='vg_name';;
    'lv_part')  active_arg='lv_part';;
    'device')   active_arg='device';;
    *) echo "Unrecognized argument '${arg}'." >&2;
       exit 1;;
  esac && continue
  [ ${parse_args} -gt 0 ] && [ "${arg#-}" != "${arg}" ] && \
  for a in $(echo "${arg#-}" | sed -e 's/\(.\)/\1\n/g'); do
    case "${a}" in
      'h'|'?') help=1;;
      'F')     force=1;;
      'f')     active_arg='firmware';;
      'v')     active_arg='vg_name';;
      'p')     active_arg='lv_part';;
      'd')     active_arg='device';;
      *) echo "Unrecognized argument '-${a}'." >&2;
         exit 1;;
    esac
  done && continue
  [ -n "${active_arg}" ] && \
  case "${active_arg}" in
    'firmware') firmware="${arg}";;
    'vg_name')  vg_name="${arg}";;
    'lv_part')  lv_parts="${lv_parts}${arg};";;
    'device')   devices="${devices}${arg},";;
    *) echo "Coding error, unhandled argument '${active_arg}'. This should not occur." >&2;
       exit 1;;
  esac && continue
  echo "Orphaned argument '${arg}' encountered." >&2
  exit 1;;
done

[ $# -eq 0 ] || [ ${help} -gt 0 ] && cat << EOF >&2
USAGE:
  ${_file} [OPTIONS] DEVICE [DEVICE...]

OPTIONS:
  -h, --help                Show this help text.
  -F, --force               Do not ask for confirmation. Don't use this.
  -f, --firmware FILE       RPi Firmware (https://github.com/pftf/RPi3).
  -v, --vg-name  VG_NAME    Name for the generated lvm volume group.
  -p, --lv-part  LV_SPEC    LV partition specification. See below.
  -d, --device   BLOCKDEV   Block device to prep for installation.

LV_SPEC:
  'lv_name,lv_size,mountpoint,fstype'
  If provided, only those partitions will be created, so this might break your setup if, e.g. you forget to add a root partition.
  By default, it will create: ${lv_parts_default}
EOF

