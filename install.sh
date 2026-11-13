#!/bin/bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WHOLE_DIRS=(.config/omarchy/themes/tiger .config/quickshell)

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

make -s -C "$R/ctm"

find ~/.local/bin ~/.local/share ~/.config -maxdepth 5 -xtype l -lname "$R/*" -delete
skip=()
for d in "${WHOLE_DIRS[@]}"; do
  link "$d"
  skip+=(-path "./$d" -prune -o)
done
(cd "$R/home" && find . "${skip[@]}" -type f -print) | while read -r f; do link "${f#./}"; done

tiger="$R/home/.config/omarchy/themes/tiger"
if [[ ! -f $tiger/backgrounds/1-tiger.jpg ]]; then
  mkdir -p "$tiger/backgrounds"
  curl -fsSL -o "$tiger/backgrounds/1-tiger.jpg" https://media.512pixels.net/downloads/macos-wallpapers-6k/10-4-6k.jpg ||
    echo "couldn't fetch the Tiger wallpaper; the theme works without it"
fi
if [[ -f $tiger/backgrounds/1-tiger.jpg && ! -f $tiger/preview.png ]] && command -v magick >/dev/null; then
  magick "$tiger/backgrounds/1-tiger.jpg" -resize 2560x1440^ -gravity center -extent 2560x1440 "$tiger/preview.png"
fi

systemctl --user daemon-reload
systemctl --user enable --now ambient-display.service hypridle.service shell.service sdw-clash-recover.service tv-mode.service

if [[ ${1:-} == --system ]]; then
  login_background="$R/system/usr/share/sddm/themes/tiger/background.jpg"
  if [[ ! -f $login_background && -f $tiger/backgrounds/1-tiger.jpg ]]; then
    magick "$tiger/backgrounds/1-tiger.jpg" -resize 2880x1800^ -gravity center -extent 2880x1800 -quality 92 "$login_background"
  fi
  pkexec bash -c '
    set -e
    cd "$1/system"
    find . -type f | while read -r f; do
      install -Dm644 "$f" "/${f#./}" && echo "installed /${f#./}"
    done
    chmod 755 /usr/lib/systemd/system-sleep/unmount-fuse
    systemctl daemon-reload
    systemd-tmpfiles --create /etc/tmpfiles.d/expertbook-tweaks.conf
    sed -i "/^IgnorePkg/d" /etc/pacman.conf
    if [[ $(grep "^\[" /etc/pacman.conf | tail -1) != "[omarchy]" ]] && grep -q "^\[omarchy\]$" /etc/pacman.conf; then
      server=$(sed -n "/^\[omarchy\]$/,/^\[/{/^Server/p}" /etc/pacman.conf)
      sed -i "/^\[omarchy\]$/,/^\[/{/^\[omarchy\]$/d;/^Server/d}" /etc/pacman.conf
      printf "\n[omarchy]\n%s\n" "$server" >>/etc/pacman.conf
    fi
    for f in sudo polkit-1; do
      sed -i "s|pam_exec.so quiet /usr/bin/omarchy-hw-laptop-closed|pam_exec.so quiet /bin/sh /usr/local/share/expertbook-tweaks/lid-closed|" /etc/pam.d/$f
    done
    udevadm control --reload
    systemd-hwdb update && udevadm trigger -s input
    systemctl enable rapl-sync.service
    systemctl restart rapl-sync.service
  ' _ "$R"
fi
