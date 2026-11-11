#!/bin/bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WHOLE_DIRS=(.config/omarchy/themes/tiger)

link() {
  local src="$R/home/$1" dst="$HOME/$1"
  [[ -L $dst && $(readlink "$dst") == "$src" ]] && return
  mkdir -p "$(dirname "$dst")"
  if [[ -e $dst && ! -L $dst ]]; then
    mv "$dst" "$dst.pre-expertbook-tweaks.$(date +%s)"
    echo "backed up existing $dst"
  fi
  ln -sfn "$src" "$dst"
  echo "linked $dst"
}

load_from_monitors_lua() {
  local line="dofile(os.getenv(\"HOME\") .. \"/.config/hypr/$1\")${2:-}"
  grep -qF "$line" ~/.config/hypr/monitors.lua || printf '\n%s\n' "$line" >>~/.config/hypr/monitors.lua
}

make -s -C "$R/ctm"

find ~/.local/bin ~/.local/share ~/.config -maxdepth 5 -xtype l -lname "$R/*" -delete
skip=()
for d in "${WHOLE_DIRS[@]}"; do
  link "$d"
  skip+=(-path "./$d" -prune -o)
done
(cd "$R/home" && find . "${skip[@]}" -type f -print) | while read -r f; do link "${f#./}"; done

load_from_monitors_lua hdr.lua "(omarchy_monitor_scale)"
load_from_monitors_lua tv-mode.lua

tiger="$R/home/.config/omarchy/themes/tiger"
if [[ ! -f $tiger/backgrounds/1-tiger.jpg ]]; then
  mkdir -p "$tiger/backgrounds"
  curl -fsSL -o "$tiger/backgrounds/1-tiger.jpg" https://media.512pixels.net/downloads/macos-wallpapers-6k/10-4-6k.jpg ||
    echo "couldn't fetch the Tiger wallpaper; the theme works without it"
fi
if [[ -f $tiger/backgrounds/1-tiger.jpg && ! -f $tiger/preview.png ]] && command -v magick >/dev/null; then
  magick "$tiger/backgrounds/1-tiger.jpg" -resize 2560x1440^ -gravity center -extent 2560x1440 "$tiger/preview.png"
fi

"$R/plugins/sync" apply

systemctl --user daemon-reload
systemctl --user enable --now ambient-display.service hypridle.service sdw-clash-recover.service tv-mode.service

if [[ ${1:-} == --system ]]; then
  pkexec bash -c '
    set -e
    cd "$1/system"
    find . -type f | while read -r f; do
      install -Dm644 "$f" "/${f#./}" && echo "installed /${f#./}"
    done
    systemctl daemon-reload
    systemd-hwdb update && udevadm trigger -s input
    systemctl enable rapl-sync.service
    systemctl restart rapl-sync.service
  ' _ "$R"
fi
