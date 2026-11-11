#!/bin/bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
installed=$(pacman -Q sddm | awk '{print $2}')
base=${installed%.1}
work="${SDDM_TREE:-$HOME/sddm/pkg}"
if [[ -d $work/.git ]]; then
  git -C "$work" fetch -q --tags
else
  git clone -q https://gitlab.archlinux.org/archlinux/packaging/packages/sddm.git "$work"
fi
cd "$work"
git checkout -q -f "$base"
git clean -q -fdx -e '*.pkg.tar.zst'
cp "$HERE"/*.patch .
patches=$(cd "$HERE" && ls *.patch | sort)

PATCHES="$patches" python3 - <<'PY'
import os, re
patches = os.environ["PATCHES"].split()
p = open("PKGBUILD").read()
p = re.sub(r"^pkgrel=(\S+)$", lambda m: f"pkgrel={m.group(1)}.1", p, count=1, flags=re.M)
p = re.sub(r"^\s+qt5-(base|declarative|tools)\n", "", p, flags=re.M)
p = re.sub(r"^.*build5.*\\\n.*\n", "", p, flags=re.M)
p = re.sub(r"^.*build5.*\n", "", p, flags=re.M)
p = re.sub(r"^(source=\()", lambda m: m.group(1) + "".join(f"{x}\n        " for x in patches), p, count=1, flags=re.M)
p = re.sub(r"^(sha256sums=\()", lambda m: m.group(1) + "'SKIP'\n            " * len(patches), p, count=1, flags=re.M)
apply = "".join(f'  patch -d $pkgname -Np1 -i "$srcdir/{x}"\n' for x in patches)
p, n = re.subn(r"^(prepare\(\) \{\n(?:.*\n)*?)(\})", lambda m: m.group(1) + apply + m.group(2), p, count=1, flags=re.M)
assert n == 1 and "build5" not in p and "qt5-base" not in p, "PKGBUILD layout changed; update build.sh"
open("PKGBUILD", "w").write(p)
PY

makepkg --cleanbuild --force --noconfirm
ls -1t "$work"/sddm-[0-9]*.pkg.tar.zst | head -1
