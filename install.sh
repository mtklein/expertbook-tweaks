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
link bin/hdr-auto-brightness            ~/.local/bin/hdr-auto-brightness
link bin/nightlight-sun                 ~/.local/bin/nightlight-sun
link fingerprint                        ~/.local/share/fp-shim
# monitors.lua stays a real file: Omarchy rewrites its scale lines with sed -i,
# which would replace a symlink. It just loads hypr/hdr.lua from here.
loader='dofile(os.getenv("HOME") .. "/expertbook-tweaks/hypr/hdr.lua")(omarchy_monitor_scale)'
if ! grep -qF "$loader" ~/.config/hypr/monitors.lua; then
  printf '\n-- Internal OLED: HDR, brightness keys/slider support, border dimming.\n%s\n' "$loader" >> ~/.config/hypr/monitors.lua
  echo "added hdr.lua loader to ~/.config/hypr/monitors.lua"
fi
link hypr/bindings.lua                  ~/.config/hypr/bindings.lua
link hypr/input.lua                     ~/.config/hypr/input.lua
link omarchy-plugins/mtklein.monitor    ~/.config/omarchy/plugins/mtklein.monitor
link wluma                              ~/.config/wluma
link systemd-user/hdr-auto-brightness.service ~/.config/systemd/user/hdr-auto-brightness.service
link hypr/hypridle.conf                 ~/.config/hypr/hypridle.conf
link systemd-user/nightlight-sun.service ~/.config/systemd/user/nightlight-sun.service
link systemd-user/nightlight-sun.timer   ~/.config/systemd/user/nightlight-sun.timer

systemctl --user daemon-reload
systemctl --user enable --now hdr-auto-brightness.service
systemctl --user enable --now hypridle.service   # pacman: hypridle
systemctl --user enable --now nightlight-sun.timer

if [[ ${1:-} == --system ]]; then
  pkexec bash -c '
    set -e
    cd "$1/system"
    find . -type f | while read -r f; do
      install -Dm644 "$f" "/${f#./}" && echo "installed /${f#./}"
    done
    systemctl daemon-reload
    systemctl enable rapl-sync.service
    systemctl restart rapl-sync.service
  ' _ "$R"
  echo "restart affected services if needed: sudo systemctl restart ollama"
fi
