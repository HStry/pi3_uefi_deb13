#!/usr/bin/env sh

ls_stanza="\
\\1export LS_OPTIONS='--almost-all --classify --group-directories-first --color=auto'\\n\
\\1export LL_OPTIONS=\"\${LS_OPTIONS}\"' --human --format=long'\\n\
\\1alias ls='ls \${LS_OPTIONS}'\\n\
\\1alias ll='ls \${LL_OPTIONS}'"

sed -i \
  -e '/^HIST\(FILE\)\?SIZE=/ s/\s*$/0/' \
  -e '/^HISTFILESIZE=/ s/$/\nHISTTIMEFORMAT='"'"'[%Y-%m-%d %H:%M:%S] '"'"'/' \
  -e 's/^\(\s*#\s*\)\?\(force_color_prompt=\)/\2/' \
  -e '/^if \[ "$color_prompt" = yes ]; then/ s/^/[ $(id -u) -gt 0 ] \&\& color_username='"'"'01;32'"'"' || color_username='"'"'01;31'"'"'\n/' \
  -e '/^\s*PS1=/ s/01;32/'"'"'"${color_username}"'"'"'/' \
  -e '/^unset color_prompt/ s/\s*$/ color_username/' \
  -e '/^\s*alias ls=/ s/^\(\s*\).*$/'"${ls_stanza}"'/' \
  -e 's/^\(\s*#\s*\)\?\(export GCC_COLORS=\)/\2/' \
  /etc/skel/.bashrc

for f in "/root/.bashrc" "/home/"*"/.bashrc; do
  [ -n "${f}" ] || continue
  [ -f "${f}" ] || continue
  cat /etc/skel/.bashrc > "${f}"
done
