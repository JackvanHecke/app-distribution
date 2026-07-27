#!/usr/bin/env bash
# =============================================================================
# collect.sh — bouwt de AltStore/LiveContainer-bron (apps.json)
# =============================================================================
# Voor elke app in config.json:
#   1. pak de NIEUWSTE release-IPA uit de (private) app-repo
#   2. upload die naar de 'latest'-release van deze PUBLIEKE distributie-repo
#      (vaste bestandsnaam <repo>.ipa -> stabiele, bereikbare download-URL)
#   3. lees versie uit de IPA (Info.plist)
#   4. schrijf een bron-JSON die AltStore/SideStore/LiveContainer kunnen lezen
#
# Auth: gebruikt de GitHub CLI. Lokaal via 'gh auth', in CI via GH_TOKEN (PAT).
# =============================================================================
set -euo pipefail
cd "$(dirname "$0")/.."

CFG=config.json
OWNER=$(jq -r .owner "$CFG")
DIST=$(jq -r .distRepo "$CFG")
TOKEN=$(jq -r .pathToken "$CFG")
REL=latest
ASSET_BASE="https://github.com/$OWNER/$DIST/releases/download/$REL"
ICON_BASE="https://raw.githubusercontent.com/$OWNER/$DIST/main/$TOKEN/icons"
OUT="$TOKEN/apps.json"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# Zorg dat de 'latest'-release bestaat om IPA's aan te hangen.
gh release view "$REL" -R "$OWNER/$DIST" >/dev/null 2>&1 \
  || gh release create "$REL" -R "$OWNER/$DIST" -t "Latest IPAs" -n "Automatisch bijgewerkt door collect.sh"

entries="[]"
n=$(jq '.apps | length' "$CFG")
for i in $(seq 0 $((n - 1))); do
  repo=$(jq -r ".apps[$i].repo" "$CFG")
  name=$(jq -r ".apps[$i].name" "$CFG")
  bid=$(jq -r ".apps[$i].bundleIdentifier" "$CFG")
  dev=$(jq -r ".apps[$i].developerName" "$CFG")
  icon=$(jq -r ".apps[$i].icon" "$CFG")

  tag=$(gh release list -R "$OWNER/$repo" -L 1 --json tagName -q '.[0].tagName' 2>/dev/null || echo "")
  if [ -z "$tag" ]; then echo "!! $repo: geen release — overslaan"; continue; fi
  ipaname=$(gh release view "$tag" -R "$OWNER/$repo" --json assets \
            -q '.assets[] | select(.name | endswith(".ipa")).name' | head -1)
  if [ -z "$ipaname" ]; then echo "!! $repo: geen .ipa in $tag — overslaan"; continue; fi

  echo "==> $name  ($tag / $ipaname)"
  gh release download "$tag" -R "$OWNER/$repo" -p "$ipaname" -D "$WORK" --clobber
  ipa="$WORK/$ipaname"

  # Versie uit Info.plist (python3/plistlib werkt op macOS én Linux).
  unzip -o -q "$ipa" -d "$WORK/x_$repo"
  plist=$(ls "$WORK/x_$repo"/Payload/*.app/Info.plist | head -1)
  ver=$(python3 - "$plist" <<'PY'
import plistlib, sys
d = plistlib.load(open(sys.argv[1], "rb"))
print(f"{d.get('CFBundleShortVersionString','1.0.0')}.{d.get('CFBundleVersion','1')}")
PY
)
  size=$(stat -f%z "$ipa" 2>/dev/null || stat -c%s "$ipa")

  # Upload naar dist 'latest' met stabiele naam <repo>.ipa. In een eigen submap,
  # anders botst bv. agora.ipa met Agora.ipa op een hoofdletter-ongevoelig
  # bestandssysteem (macOS) en weigert cp.
  outname="${repo}.ipa"
  updir="$WORK/up_$repo"
  mkdir -p "$updir"
  cp "$ipa" "$updir/$outname"
  gh release upload "$REL" -R "$OWNER/$DIST" "$updir/$outname" --clobber

  entry=$(jq -n \
    --arg name "$name" --arg bid "$bid" --arg dev "$dev" --arg ver "$ver" \
    --arg date "$(date +%F)" --arg url "$ASSET_BASE/$outname" \
    --arg icon "$ICON_BASE/$icon" --argjson size "$size" \
    '{name:$name, bundleIdentifier:$bid, developerName:$dev, version:$ver,
      versionDate:$date, downloadURL:$url, iconURL:$icon, size:$size,
      localizedDescription:("Sideload-build van " + $name)}')
  entries=$(jq --argjson e "$entry" '. + [$e]' <<<"$entries")
done

srcname=$(jq -r .source.name "$CFG")
srcid=$(jq -r .source.identifier "$CFG")
sub=$(jq -r .source.subtitle "$CFG")
mkdir -p "$(dirname "$OUT")"
jq -n --arg n "$srcname" --arg id "$srcid" --arg s "$sub" --argjson apps "$entries" \
  '{name:$n, identifier:$id, subtitle:$s, apps:$apps}' > "$OUT"

echo "----------------------------------------------------------------------"
echo "Bron geschreven: $OUT  ($(jq '.apps|length' "$OUT") apps)"
