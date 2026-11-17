#!/bin/bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WHOLE_DIRS=(.config/quickshell)

product=$(</sys/class/dmi/id/product_name)
host=
for d in "$R"/hosts/*/; do
  [[ $product == $(<"$d/product") ]] && host=$(basename "$d")
done
[[ -n $host ]] || { echo "no hosts/*/product matches '$product'" >&2; exit 1; }
H=$R/hosts/$host

link() {
  local src="$1/$2" dst="$HOME/$2"
  [[ -L $dst && $(readlink "$dst") == "$src" ]] && return
  mkdir -p "$(dirname "$dst")"
  if [[ -e $dst && ! -L $dst ]]; then
    mv "$dst" "$dst.pre-expertbook-tweaks.$(date +%s)"
    echo "backed up existing $dst"
  fi
  ln -s "$src" "$dst.new-link"
  mv -T "$dst.new-link" "$dst"
  echo "linked $dst"
}

[[ -x $H/setup ]] && "$H/setup" "$R" build
find ~/.local/bin ~/.local/share ~/.config -maxdepth 5 -xtype l -lname "$R/*" -delete
for root in "$R/common/home" "$H/home"; do
  [[ -d $root ]] || continue
  skip=()
  for d in "${WHOLE_DIRS[@]}"; do
    [[ -d $root/$d ]] && link "$root" "$d"
    skip+=(-path "./$d" -prune -o)
  done
  (cd "$root" && find . "${skip[@]}" -type f -print) | while read -r f; do link "$root" "${f#./}"; done
done

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
systemctl --user enable --now hypridle.service shell.service
[[ -x $H/setup ]] && "$H/setup" "$R" enable

if [[ ${1:-} == --system ]]; then
  wallpaper="$R/common/system/usr/local/share/expertbook-tweaks/wallpaper.jpg"
  if [[ ! -f $wallpaper ]]; then
    original=$(mktemp --suffix=.jpg)
    curl -fsSL -o "$original" https://media.512pixels.net/downloads/macos-wallpapers-6k/10-4-6k.jpg &&
      magick "$original" -resize 2880x1800^ -gravity center -extent 2880x1800 -quality 92 "$wallpaper"
    rm -f "$original"
  fi
  pkexec bash -c '
    set -e
    for root in "$1/common/system" "$2/system"; do
      [[ -d $root ]] || continue
      cd "$root"
      find . -type f | while read -r f; do
        install -Dm644 "$f" "/${f#./}" && echo "installed /${f#./}"
      done
    done
    chmod 755 /usr/lib/systemd/system-sleep/unmount-fuse
    pacman -S --needed --noconfirm deepfilternet-ladspa
    systemctl daemon-reload
    systemd-tmpfiles --create /etc/tmpfiles.d/expertbook-tweaks.conf
    udevadm control --reload
    systemd-hwdb update && udevadm trigger -s input
    if [[ -x $2/setup-system ]]; then "$2/setup-system" "$1"; fi
  ' _ "$R" "$H"
fi
