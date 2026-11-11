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
link bin/ambient-display                ~/.local/bin/ambient-display
link bin/white-point                    ~/.local/bin/white-point
make -s -C "$R/ctm"                     # the helper that holds the white point (needs gcc, wayland, hyprland-protocols)
link ctm/white-point-ctm                ~/.local/bin/white-point-ctm
link bin/brightness-wake-floor          ~/.local/bin/brightness-wake-floor
link bin/sdw-clash-recover              ~/.local/bin/sdw-clash-recover
link bin/workspace-layout-toggle        ~/.local/bin/workspace-layout-toggle
link bin/brightness-why                 ~/.local/bin/brightness-why
link bin/tv-mode                        ~/.local/bin/tv-mode
link bin/game                           ~/.local/bin/game
link bin/bar-item                       ~/.local/bin/bar-item
link mangohud/MangoHud.conf             ~/.config/MangoHud/MangoHud.conf
link fingerprint                        ~/.local/share/fp-shim
# monitors.lua stays a real file: Omarchy rewrites its scale lines with sed -i,
# which would replace a symlink. It just loads hypr/hdr.lua from here.
loader='dofile(os.getenv("HOME") .. "/expertbook-tweaks/hypr/hdr.lua")(omarchy_monitor_scale)'
if ! grep -qF "$loader" ~/.config/hypr/monitors.lua; then
  printf '\n-- Internal OLED: HDR, brightness keys/slider support.\n%s\n' "$loader" >> ~/.config/hypr/monitors.lua
  echo "added hdr.lua loader to ~/.config/hypr/monitors.lua"
fi
loader='dofile(os.getenv("HOME") .. "/expertbook-tweaks/hypr/tv-mode.lua")'
if ! grep -qF "$loader" ~/.config/hypr/monitors.lua; then
  printf '\n-- TV mode (bin/tv-mode): the TV'"'"'s monitor rule while one is connected.\n%s\n' "$loader" >> ~/.config/hypr/monitors.lua
  echo "added tv-mode.lua loader to ~/.config/hypr/monitors.lua"
fi
link hypr/bindings.lua                  ~/.config/hypr/bindings.lua
link hypr/looknfeel.lua                 ~/.config/hypr/looknfeel.lua
link hypr/input.lua                     ~/.config/hypr/input.lua
link omarchy-plugins/mtklein.monitor    ~/.config/omarchy/plugins/mtklein.monitor
link omarchy-plugins/mtklein.workspaces ~/.config/omarchy/plugins/mtklein.workspaces
link omarchy-plugins/mtklein.active-window ~/.config/omarchy/plugins/mtklein.active-window
link omarchy-plugins/mtklein.clock      ~/.config/omarchy/plugins/mtklein.clock
link omarchy-plugins/mtklein.tray       ~/.config/omarchy/plugins/mtklein.tray
link omarchy-plugins/mtklein.power      ~/.config/omarchy/plugins/mtklein.power
link omarchy-plugins/mtklein.network    ~/.config/omarchy/plugins/mtklein.network
link omarchy-plugins/mtklein.bluetooth  ~/.config/omarchy/plugins/mtklein.bluetooth
link omarchy-plugins/mtklein.weather    ~/.config/omarchy/plugins/mtklein.weather
link omarchy-plugins/mtklein.audio      ~/.config/omarchy/plugins/mtklein.audio
link omarchy-plugins/mtklein.dropbox    ~/.config/omarchy/plugins/mtklein.dropbox
link omarchy-plugins/mtklein.tailscale  ~/.config/omarchy/plugins/mtklein.tailscale
link omarchy-plugins/mtklein.agents     ~/.config/omarchy/plugins/mtklein.agents
link omarchy-plugins/mtklein.osd        ~/.config/omarchy/plugins/mtklein.osd
link omarchy-themes/tiger               ~/.config/omarchy/themes/tiger
# Tiger's wallpaper is Apple's artwork, so it isn't in the repo: fetch it (and
# the theme picker's preview) the first time.
tiger=$R/omarchy-themes/tiger
if [[ ! -f $tiger/backgrounds/1-tiger.jpg ]]; then
  mkdir -p "$tiger/backgrounds"
  curl -fsSL -o "$tiger/backgrounds/1-tiger.jpg" https://media.512pixels.net/downloads/macos-wallpapers-6k/10-4-6k.jpg &&
    echo "fetched the Tiger wallpaper" || echo "couldn't fetch the Tiger wallpaper; the theme works without it"
fi
if [[ -f $tiger/backgrounds/1-tiger.jpg && ! -f $tiger/preview.png ]] && command -v magick >/dev/null; then
  magick "$tiger/backgrounds/1-tiger.jpg" -resize 2560x1440^ -gravity center -extent 2560x1440 "$tiger/preview.png"
fi
link omarchy/omarchy-menu.jsonc         ~/.config/omarchy/extensions/omarchy-menu.jsonc
link fontconfig/60-grayscale-antialias.conf ~/.config/fontconfig/conf.d/60-grayscale-antialias.conf
link fontconfig/61-tiger-sans.conf   ~/.config/fontconfig/conf.d/61-tiger-sans.conf
link systemd-user/ambient-display.service ~/.config/systemd/user/ambient-display.service
link hypr/hypridle.conf                 ~/.config/hypr/hypridle.conf
link systemd-user/sdw-clash-recover.service ~/.config/systemd/user/sdw-clash-recover.service
link systemd-user/tv-mode.service       ~/.config/systemd/user/tv-mode.service

# Replaced by ambient-display (2026-11-06).
for old in hdr-auto-brightness ambient-white; do
  if [[ -L ~/.config/systemd/user/$old.service ]]; then
    systemctl --user stop $old.service || true
    rm -f ~/.config/systemd/user/$old.service ~/.config/systemd/user/*.wants/$old.service ~/.local/bin/$old
    echo "removed $old"
  fi
done
systemctl --user daemon-reload
systemctl --user enable --now ambient-display.service
systemctl --user enable --now hypridle.service   # pacman: hypridle
systemctl --user enable --now sdw-clash-recover.service
systemctl --user enable --now tv-mode.service

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
  echo "restart affected services if needed: sudo systemctl restart ollama"
fi
