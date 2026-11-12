#!/bin/bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
version=$(pacman -Q voxtype-bin | awk '{print $2}')
version=${version%-*}
work="${VOXTYPE_TREE:-$HOME/voxtype}"
if [[ -d $work/.git ]]; then
  git -C "$work" fetch -q --depth 1 origin tag "v$version"
else
  git clone -q --depth 1 --branch "v$version" https://github.com/peteonrails/voxtype.git "$work"
fi
cd "$work"
git checkout -q -f "v$version"
for patch in "$HERE"/*.patch; do
  git apply "$patch"
done
RUSTFLAGS="-C target-cpu=native" cargo build --release --bin voxtype
install -Dm755 target/release/voxtype "$HOME/.local/bin/voxtype-patched"
systemctl --user daemon-reload
systemctl --user restart voxtype.service
"$HOME/.local/bin/voxtype-patched" --version
