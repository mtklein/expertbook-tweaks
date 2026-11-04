#!/bin/bash
# Link this repo's files into place. Safe to re-run.
#   ./install.sh           user files (symlinks into ~)
#   ./install.sh --system  also copy system/ into / (root-owned; asks via pkexec)
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

link() {  # link <repo path> <target path>
  local src="$R/$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [[ -L $dst && $(readlink "$dst") == "$src" ]]; then return; fi
  if [[ -e $dst || -L $dst ]]; then
    mv "$dst" "$dst.pre-expertbook-tweaks.$(date +%s)"
    echo "backed up existing $dst"
  fi
  ln -s "$src" "$dst"
  echo "linked $dst"
}

link bin/hdr-brightness                 ~/.local/bin/hdr-brightness
link bin/hdr-monitor-state              ~/.local/bin/hdr-monitor-state
link fingerprint                        ~/.local/share/fp-shim
link hypr/monitors.lua                  ~/.config/hypr/monitors.lua
link hypr/bindings.lua                  ~/.config/hypr/bindings.lua
link omarchy-plugins/mtklein.monitor    ~/.config/omarchy/plugins/mtklein.monitor
link systemd-user/expertbook-mute-leds.service.d ~/.config/systemd/user/expertbook-mute-leds.service.d
link wluma                              ~/.config/wluma

systemctl --user daemon-reload

if [[ ${1:-} == --system ]]; then
  pkexec bash -c '
    set -e
    cd "$1/system"
    find . -type f | while read -r f; do
      install -Dm644 "$f" "/${f#./}" && echo "installed /${f#./}"
    done
    udevadm control --reload
    systemctl daemon-reload
  ' _ "$R"
  echo "restart affected services if needed: sudo systemctl restart ollama"
fi
