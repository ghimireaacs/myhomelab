#!/usr/bin/env bash
# Render the lab maps: diagrams/*.d2 -> diagrams/<name>.svg (icons bundled into the SVG).
# Icons come from homarr-labs/dashboard-icons and are cached in diagrams/icons/ on first use
# (git-ignored). *.full.d2 are the private maps with everything on them; they and their
# SVGs are git-ignored. Public maps (overview.d2, flow.d2) never name media apps or say
# what they do. D2 v0.7.1 with the ELK layout, in Docker, so nothing is installed on the host.
set -euo pipefail
cd "$(dirname "$0")"
base=https://raw.githubusercontent.com/homarr-labs/dashboard-icons/main
mkdir -p icons
grep -ohE '\$\{d[ip]\}/[a-z0-9.-]+\.(svg|png)' *.d2 | sort -u | while read -r ref; do
  file=${ref#*/}; dir=svg; [[ $file == *.png ]] && dir=png
  [[ -s icons/$file ]] || curl -sfL -o "icons/$file" "$base/$dir/$file" || echo "missing icon: $file" >&2
done
for f in *.d2; do
  name=$(basename "$f" .d2)
  [[ $name == style ]] && continue
  docker run --rm -u "$(id -u):$(id -g)" -e HOME=/tmp -v "$PWD:/work" -w /work \
    terrastruct/d2:v0.7.1 --layout elk --pad 48 "$name.d2" "$name.svg"
done
