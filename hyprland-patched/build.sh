#!/bin/bash
# Rebuild the installed Hyprland version from Arch's PKGBUILD with
# the patches here (applied in name order): 01 makes the SDR reference luminance advertised
# to colour-managed clients (Chromium, Electron) follow the monitor's
# sdr_max_luminance instead of a hard-coded 203 nits; 02 notifies those clients when
# sdr_max_luminance changes at runtime, so they follow brightness changes live.
# Upstream: https://github.com/hyprwm/Hyprland/discussions/14999 (francomeisterm),
# tracked in https://github.com/hyprwm/Hyprland/issues/16329.
#
#   ./build.sh            build, then install with: sudo pacman -U <printed package>
#
# The package is versioned <pkgver>-<pkgrel>.1, so any official update replaces
# it; re-run this after updates until upstream fixes #16329.
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

makepkg --cleanbuild --noconfirm
ls -1t "$work"/hyprland-[0-9]*.pkg.tar.zst | head -1
