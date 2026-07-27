#!/usr/bin/env bash
# =============================================================================
# setup.sh — eenmalige opzet van de publieke distributie-repo + bron
# =============================================================================
# Dit maakt een PUBLIEKE GitHub-repo aan die je kant-en-klare IPA's host, zodat
# AltStore/SideStore/LiveContainer je apps automatisch kunnen updaten. Je BRONCODE
# blijft privé; alleen de gecompileerde IPA's + iconen worden bereikbaar via een
# onraadbare (obscure) link.
#
# Vereist: gh (ingelogd via `gh auth login`), jq, git, python3, unzip.
# Draai vanuit deze map:   bash setup.sh
# =============================================================================
set -euo pipefail
cd "$(dirname "$0")"

OWNER=$(jq -r .owner config.json)
DIST=$(jq -r .distRepo config.json)
TOKEN=$(jq -r .pathToken config.json)

echo "==> 1/6 App-iconen kopiëren naar $TOKEN/icons/"
mkdir -p "$TOKEN/icons"
n=$(jq '.apps | length' config.json)
for i in $(seq 0 $((n - 1))); do
  src=$(jq -r ".apps[$i].iconSource" config.json)
  dst="$TOKEN/icons/$(jq -r ".apps[$i].icon" config.json)"
  if [ -f "$src" ]; then cp "$src" "$dst"; echo "   ok  $dst"; else echo "   !! ontbreekt: $src"; fi
done

echo "==> 2/6 Git init + eerste commit"
git init -q 2>/dev/null || true
git branch -M main 2>/dev/null || true
git add -A
git -c user.name=JackvanHecke -c user.email=jackvanhecke1@gmail.com \
  commit -q -m "init: distributie-repo + bron-structuur" || true

echo "==> 3/6 Publieke repo aanmaken + pushen"
if gh repo view "$OWNER/$DIST" >/dev/null 2>&1; then
  echo "   repo bestaat al"
  git remote get-url origin >/dev/null 2>&1 || git remote add origin "https://github.com/$OWNER/$DIST.git"
else
  gh repo create "$OWNER/$DIST" --public \
    --description "IPA-distributie + AltStore/LiveContainer bron (JAVAC apps)" \
    --source=. --remote=origin --push
fi
git push -u origin main

echo "==> 4/6 IPA's verzamelen uit de private repos + bron schrijven"
bash scripts/collect.sh

echo "==> 5/6 Bron committen + pushen"
git add -A
git -c user.name=JackvanHecke -c user.email=jackvanhecke1@gmail.com \
  commit -q -m "chore: eerste bron (collect)" || true
git push

echo
echo "==> 6/6 KLAAR ✅"
echo "Plak deze BRON-URL in AltStore/SideStore/LiveContainer:"
echo
echo "   https://raw.githubusercontent.com/$OWNER/$DIST/main/$TOKEN/apps.json"
echo
echo "Voor AUTOMATISCH updaten (workflow elke 30 min): maak een PAT en zet 'm als"
echo "secret DIST_TOKEN in de repo — zie README.md, sectie 'Automatisch updaten'."
