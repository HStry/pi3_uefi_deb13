__ssh_agent_mgr__set_ssh_dir() {
  if [ -n "${SSH_DIR}" ]; then
    if [ -d "${SSH_DIR}" ]; then
      export SSH_DIR
      return 0
    fi
    echo "Provided SSH_DIR value '${SSH_DIR}' is not a directory." >&2
    echo "Determining actual SSH_DIR." >&2
  fi
  for d in "${XDG_CONFIG_HOME:-${HOME}/.config}/ssh" \
           "${HOME}/.ssh"; do
    [ -n "${d}" ] || continue
    [ -d "${d}" ] || continue
    export SSH_DIR="${d}"
    return 0
  done
  echo "Could not determine your SSH directory, will create one." >&2
  if [ -d "${XDG_CONFIG_HOME:-${HOME}/.config}" ]; then
    SSH_DIR="${XDG_CONFIG_HOME:-${HOME}/.config}/ssh"
  else
    SSH_DIR="${HOME}/.ssh"
  fi
  if ! mkdir "${SSH_DIR}"; then
    echo "Could not create directory '${SSH_DIR}'." >&2
    return 1
  fi
  chown $(id -u) "${SSH_DIR}"
  chgrp $(id -g) "${SSH_DIR}"
  chmod 700 "${SSH_DIR}"
  export SSH_DIR
}

__ssh_agent_mgr__set_ssh_agent_file() {
  export SSH_AGENT_FILE="${SSH_DIR}/agent"
  if ! [ -f "${SSH_AGENT_FILE}" ]; then
    touch "${SSH_AGENT_FILE}"
    chown $(id -u) "${SSH_AGENT_FILE}"
    chgrp $(id -g) "${SSH_AGENT_FILE}"
    chmod 600 "${SSH_AGENT_FILE}"
  fi
}

__ssh_agent_mgr__validate_ssh_agent_file() (
  [ $(wc -l "${SSH_AGENT_FILE}" | awk '{print $1}') -ne 2 ] && exit 2
  p="$(grep '^SSH_AGENT_PID' "${SSH_AGENT_FILE}" \
       | sed -e 's/\s*;\s*export\s\+SSH_AGENT_PID;\s*$//' \
             -e 's/^[^=]\+=\s*//')"
  s="$(grep '^SSH_AUTH_SOCK' "${SSH_AGENT_FILE}" \
       | sed -e 's/\s*;\s*export\s\+SSH_AUTH_SOCK;\s*$//' \
             -e 's/^[^=]\+=\s*//')"

  echo "${p}" | grep -q '^[1-9][0-9]*$' || exit 3
  pu="$(ps -q "${p}" -o uid=  | sed -e 's/^\s*//' -e 's/\s*$//')"
  pc="$(ps -q "${p}" -o comm= | sed -e 's/^\s*//' -e 's/\s*$//')"

  [ "${pu}" -eq "$(id -u)" ] || exit 4
  [ "${pc}" = 'ssh-agent' ] || exit 5

  [ -n "${s}" ] || exit 6
  [ -e "${s}" ] || exit 7
  [ -S "${s}" ] || exit 8
)

__ssh_agent_mgr__load_agent() {
  if ! __ssh_agent_mgr__validate_ssh_agent_file; then
    ssh-agent \
    | grep '^SSH_\(AGENT_PID\|AUTH_SOCK\)=' \
    > "${SSH_AGENT_FILE}"
  fi
  . "${SSH_AGENT_FILE}"
}

ssh_agent_mgr() {
  __ssh_agent_mgr__set_ssh_dir || return $?
  __ssh_agent_mgr__set_ssh_agent_file || return $?
  __ssh_agent_mgr__load_agent || return $?
}
