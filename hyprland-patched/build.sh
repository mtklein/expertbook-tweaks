#!/bin/bash
# Rebuild the installed Hyprland version from Arch's PKGBUILD with
# the patches here (applied in name order): 01 makes the SDR reference luminance advertised
# to colour-managed clients (Chromium, Electron) follow the monitor's
# sdr_max_luminance instead of a hard-coded 203 nits; 02 notifies those clients when
# sdr_max_luminance changes at runtime, so they follow brightness changes live.
# 03 applies sdrbrightness to colour-managed surfaces too (not just SDR ones), so
# 0% brightness (sdrbrightness ~0, hypr/hdr.lua) blacks out Chromium and HDR video as well.
# 04 sends those notifications to subsurfaces too (they get no wl_surface.enter, so the
# feedback's one-output check never passed): Chromium's omnibox dropdown is one.
# 05 renders the hardware cursor in the output's encoding (it was rendered for the linear
# work buffer, so in HDR it was far too bright) and redraws it when brightness changes;
# with it the software-cursor override in hypr/hdr.lua isn't needed.
# 06 applies the white point (hyprsunset's matrix) in linear light when the output is PQ.
# KMS applies it to the encoded signal, which for PQ tints white far more than shadows,
# more the brighter the screen, and made "5100 K" really ~3300 K.
# 07 keeps surfaces that aren't on screen yet up to date too (single monitor), and rechecks
# one when it becomes a subsurface: Chromium's omnibox dropdown opened one brightness behind.
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

makepkg --cleanbuild --force --noconfirm   # --force: rebuild when only the patches changed
ls -1t "$work"/hyprland-[0-9]*.pkg.tar.zst | head -1
