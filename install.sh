#!/bin/bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WHOLE_DIRS=(.config/quickshell)

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
make -s -C "$R/geforcenow-hdr"
if [[ ! -e $R/geforcenow-hdr/sdl/lib/libSDL2-2.0.so.0 ]] && flatpak info com.nvidia.geforcenow &>/dev/null; then
  flatpak install --user --noninteractive -y flathub org.freedesktop.Sdk//24.08
  "$R/geforcenow-hdr/build-sdl" >/dev/null
fi

find ~/.local/bin ~/.local/share ~/.config -maxdepth 5 -xtype l -lname "$R/*" -delete
skip=()
for d in "${WHOLE_DIRS[@]}"; do
  link "$d"
  skip+=(-path "./$d" -prune -o)
done
(cd "$R/home" && find . "${skip[@]}" -type f -print) | while read -r f; do link "${f#./}"; done

if [[ ! -x ~/piper/venv/bin/piper ]]; then
  python3 -m venv ~/piper/venv
  ~/piper/venv/bin/pip install --quiet piper-tts
fi
for f in en_GB-semaine-medium.onnx en_GB-semaine-medium.onnx.json; do
  [[ -s ~/piper/voices/$f ]] ||
    curl -fsSL --create-dirs -o ~/piper/voices/"$f" "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_GB/semaine/medium/$f"
done
"$R/tools/claude-settings"

systemctl --user daemon-reload
systemctl --user enable --now ambient-display.service hypridle.service shell.service sdw-clash-recover.service tv-mode.service fn-keys.service

if [[ ${1:-} == --system ]]; then
  wallpaper="$R/system/usr/local/share/expertbook-tweaks/wallpaper.jpg"
  if [[ ! -f $wallpaper ]]; then
    original=$(mktemp --suffix=.jpg)
    curl -fsSL -o "$original" https://media.512pixels.net/downloads/macos-wallpapers-6k/10-4-6k.jpg &&
      magick "$original" -resize 2880x1800^ -gravity center -extent 2880x1800 -quality 92 "$wallpaper"
    rm -f "$original"
  fi
  pkexec bash -c '
    set -e
    cd "$1/system"
    find . -type f | while read -r f; do
      install -Dm644 "$f" "/${f#./}" && echo "installed /${f#./}"
    done
    chmod 755 /usr/lib/systemd/system-sleep/unmount-fuse /usr/lib/systemd/system-sleep/firmware-state
    msgfmt -o /usr/share/locale/en/LC_MESSAGES/fprintd.mo "$1/fingerprint-prompts.po"
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
    systemctl enable rapl-sync.service lightbar-off.service fn-keys-on.service psr-after-desktop.service
    systemctl restart rapl-sync.service
  ' _ "$R"
fi
