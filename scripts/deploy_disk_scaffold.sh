#!/usr/bin/env sh

_self="$(realpath -s "$0" 2>/dev/null || realpath "$0")" # F* busybox.
_path="$(dirname "${_self}")"
_file="$(basename "${_self}")"
_name="${_file%.*}"

default_parts() (
  echo 'EFI,  255M,  e, /boot/efi, vfat'
  echo 'boot, 768M, 8a, /boot,     ext4'
  echo 'lvm,      , 8e, ,          '
)

default_lv_parts() (
  echo 'root,        12G, /,              ext4'
  echo 'home,         2G, /home,          ext4'
  echo 'var,          4G, /var,           ext4'
  echo 'varlog,       3G, /var/log,       ext4'
  echo 'varlogaudit,  2G, /var/log/audit, ext4'
  echo 'vartmp,       1G, /var/tmp,       ext4'
  echo 'tmp,          1G, /tmp,           ext4'
)

parts() (
  if [ -n "${parts}" ]; then
    echo "${parts}" | sed -e 's/;/\n/g'
  else
    default_parts
  fi
)

lv_parts() (
  if [ -n "${lv_parts}" ]; then
    echo "${lv_parts}" | sed -e 's/;/\n/g'
  else
    default_lv_parts
  fi
)

firmware() (
  if [ -n "${firmware}" ]; then
    [ -f "${firmware}" ] && echo "${firmware}" && exit 0
    echo "Provided firmware '${firmware}' could not be found." >&2
    exit 1
  fi
  for f in "${_path}/firmware/RPi3_UEFI_Firmware"*".zip" \
           "${_path}/RPi3_UEFI_Firmware"*".zip"; do
    [ -f "${f}" ] && echo "${f}"
  done \
  | sort -rV \
  | while IFS= read fw; do
      echo "${fw}"
      exit 0
    done
  
  echo "Could not locate a firmware file." >&2
  exit 1
)

vg_name() (
  [ -n "${vg_name}"] && echo "${vg_name}" && exit 0
  dt="$(date -uIs)"
  d0="$(date -d "${dt}" +%Y)-01-01T00:00:00Z"
  s="$(( ($(date -d "${dt}" +%s) - $(date -d "${d0}" +%s)) / 2 ))"
  printf 'sys%02d%06x' "$(date -d "${dt}" +%y)" "${s}"
)



help=0
force=0
devices=
parts=
vg_name=
lv_parts=
firmware=

parse_args=1
active_arg=

for arg in "$@"; do
  [ ${parse_args} -gt 0 ] && [ "${arg}" = '--' ] && parse_args=0 && continue
  [ ${parse_args} -le 0 ] && [ "${arg}" = '++' ] && parse_args=1 && continue
  [ ${parse_args} -gt 0 ] && [ "${arg#--}" != "${arg}" ] && \
  case "$(echo "${arg#--}" | sed -e 's/-/_/g')" in
    'help')      help=1;;
    'force')     force=1;;
    'device')    active_arg='device';;
    'partition') active_arg='partition';;
    'vg_name')   active_arg='vg_name';;
    'lv_part')   active_arg='lv_part';;
    'firmware')  active_arg='firmware';;
    *) echo "Unrecognized argument '${arg}'." >&2;
       exit 1;;
  esac && continue
  [ ${parse_args} -gt 0 ] && [ "${arg#-}" != "${arg}" ] && \
  for a in $(echo "${arg#-}" | sed -e 's/\(.\)/\1\n/g'); do
    case "${a}" in
      'h'|'?') help=1;;
      'F')     force=1;;
      'd')     active_arg='device';;
      'p')     active_arg='partition';;
      'g')     active_arg='vg_name';;
      'v')     active_arg='lv_part';;
      'f')     active_arg='firmware';;
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
    *) echo -n "Coding error, unhandled argument '${active_arg}'." >&2;
       echo    " This should not occur." >&2;
       exit 1;;
  esac && continue
  echo "Orphaned argument '${arg}' encountered." >&2
  exit 1;;
done

[ $# -eq 0 ] || [ ${help} -gt 0 ] && cat << EOF >&2
USAGE:
  ${_file} [OPTIONS] DEVICE [DEVICE...]

OPTIONS:
  -h, --help                   Show this help text.
  -F, --force                  Do not ask for confirmation. Don't use this.
  -d, --device     BLOCKDEV  * Block device to prep for installation.
  -p, --partition  PARTSPEC    Partition specification. See below.
  -v, --vg-name    VG_NAME     Name for the generated lvm volume group.
  -p, --lv-part    LV_SPEC     LV partition specification. See below.
  -f, --firmware   FILE      * RPi Firmware (https://github.com/pftf/RPi3).

  Asterisks indicate required variables.

PARTSPEC:
  'name,size,type,mountpoint,fstype'
  If provided, only these partitions will be created. Tread carefully.
  By default, it will create:
$(default_parts | while IFS= read line; do echo "    ${line}"; done)
  
LV_SPEC:
  'lv_name,lv_size,mountpoint,fstype'
  If provided, only those partitions will be created, so this might break your
  setup if, e.g. you forget to add a root partition.
  By default, it will create:
$(default_lv_parts | while IFS= read line; do echo "    ${line}"; done)
EOF

