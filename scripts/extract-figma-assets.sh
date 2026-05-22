#!/usr/bin/env bash
set -euo pipefail
FILE_KEY="wOK1MMzuJZF3pIOZhGHpY9"
OUT="SushiGarden/Resources/Assets.xcassets"
TOKEN="${FIGMA_TOKEN:-}"
if [ -z "${TOKEN:-}" ]; then echo "Set FIGMA_TOKEN env var"; exit 1; fi
mkdir -p "$OUT"

# 1) Resolve all imageRef fills -> temporary URLs
curl -s -H "X-Figma-Token: $TOKEN" \
  "https://api.figma.com/v1/files/$FILE_KEY/images" > /tmp/figma_images.json
echo "Saved imageRef->url map to /tmp/figma_images.json"

# 2) Helper: download one imageRef into a named imageset
dl_ref () {
  local ref="$1"; local name="$2"
  local url; url=$(python3 -c "import json; d=json.load(open('/tmp/figma_images.json')); print(d.get('meta',{}).get('images',{}).get('$ref',''))")
  [ -z "$url" ] && { echo "missing ref $ref"; return; }
  mkdir -p "$OUT/$name.imageset"
  curl -sL "$url" -o "$OUT/$name.imageset/$name.png"
  cat > "$OUT/$name.imageset/Contents.json" <<JSON
{ "images": [ { "idiom":"universal", "filename":"$name.png", "scale":"1x" } ],
  "info": { "author":"xcode", "version":1 } }
JSON
  echo "Downloaded $name"
}

# Product photo imageRefs from Figma JSON:
dl_ref 9a47d23289a5f8037d0a221a4d5c1705288072b3 product_hikari
dl_ref 63f9d6bca62b86fcfdaaa76cc3413db2afdfed82 product_la
dl_ref 831991b082d35d478e048b042aa1dd799cb0f209 product_idaho
dl_ref 16ec23a7ff3b383d2e3f28aab00baa2f317011d1 product_osaka

# 3) Render banner nodes
render_node () {
  local id="$1"; local name="$2"
  local url; url=$(curl -s -H "X-Figma-Token: $TOKEN" \
    "https://api.figma.com/v1/images/$FILE_KEY?ids=$id&format=png&scale=2" \
    | python3 -c "import json,sys; d=json.load(sys.stdin); imgs=d.get('images',{}); print(list(imgs.values())[0] if imgs else '')")
  [ -z "$url" ] && { echo "missing node $id"; return; }
  mkdir -p "$OUT/$name.imageset"
  curl -sL "$url" -o "$OUT/$name.imageset/$name.png"
  cat > "$OUT/$name.imageset/Contents.json" <<JSON
{ "images": [ { "idiom":"universal", "filename":"$name.png", "scale":"2x" } ],
  "info": { "author":"xcode", "version":1 } }
JSON
  echo "Downloaded $name"
}

render_node 1:1370 banner_promo_1
render_node 1:1369 banner_promo_2

echo "Done. Review $OUT before committing."
