#!/usr/bin/env bash
# Regenerates App/Assets.xcassets/AppIcon.appiconset from scripts/make-icon.swift.
set -euo pipefail
cd "$(dirname "$0")/.."

set_dir=App/Assets.xcassets/AppIcon.appiconset
mkdir -p "$set_dir"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
master="$tmp/icon-1024.png"
swift scripts/make-icon.swift "$master"

images=""
for pt in 16 32 128 256 512; do
  for scale in 1 2; do
    px=$((pt * scale))
    suffix=""
    if [ "$scale" = 2 ]; then suffix="@2x"; fi
    name="icon_${pt}x${pt}${suffix}.png"
    sips -z "$px" "$px" "$master" --out "$set_dir/$name" >/dev/null
    images+="    { \"idiom\" : \"mac\", \"scale\" : \"${scale}x\", \"size\" : \"${pt}x${pt}\", \"filename\" : \"$name\" },"$'\n'
  done
done

images="${images%,$'\n'}"

cat > "$set_dir/Contents.json" <<JSON
{
  "images" : [
$images
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
JSON

cat > App/Assets.xcassets/Contents.json <<'JSON'
{
  "info" : { "author" : "xcode", "version" : 1 }
}
JSON
echo "Wrote $set_dir"
