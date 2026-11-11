#!/bin/bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
installed=$(pacman -Q hyprland | awk '{print $2}')
base=${installed%.1}                       # 0.56.2-4.1 -> 0.56.2-4
# The packaging checkout (and, after a build, the unpacked source in
# src/hyprland-source) lives in ~/hyprland so it's easy to browse.
work="${HYPRLAND_TREE:-$HOME/hyprland}"
if [[ -d $work/.git ]]; then
  git -C "$work" fetch -q --tags
else
  git clone -q https://gitlab.archlinux.org/archlinux/packaging/packages/hyprland.git "$work"
fi
cd "$work"
git checkout -q -f "$base"          # discards last build's PKGBUILD edits
git clean -q -fdx -e '*.pkg.tar.zst' # old patches, src/, pkg/; keep built packages
cp "$HERE"/*.patch .
patches=$(cd "$HERE" && ls *.patch | sort)

PATCHES="$patches" python3 - <<'PY'
import os, re
patches = os.environ["PATCHES"].split()
p = open("PKGBUILD").read()
p = re.sub(r"^pkgrel=(\S+)$", lambda m: f"pkgrel={m.group(1)}.1", p, count=1, flags=re.M)
p = re.sub(r"^(source=\()", lambda m: m.group(1) + "".join(f"{x}\n        " for x in patches), p, count=1, flags=re.M)
p = re.sub(r"^(sha256sums=\()", lambda m: m.group(1) + "'SKIP'\n            " * len(patches), p, count=1, flags=re.M)
apply = "".join(f'\tpatch -Np1 -i "$srcdir/{x}"\n' for x in patches)
p = p.replace('\tcd "$_archive"\n\tsed -i -e \'/^release:/',
              '\tcd "$_archive"\n' + apply + '\tsed -i -e \'/^release:/', 1)
assert "patch -Np1" in p, "prepare() layout changed; update build.sh"
open("PKGBUILD", "w").write(p)
PY

makepkg --cleanbuild --force --noconfirm   # --force: rebuild when only the patches changed
ls -1t "$work"/hyprland-[0-9]*.pkg.tar.zst | head -1
