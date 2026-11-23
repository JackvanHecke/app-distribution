#!/usr/bin/env bash
#
# Bouwt Kaarten & Slokken tot een niet-ondertekende .ipa, zelfde principe als
# de andere apps: LiveContainer/AltStore ondertekent pas op de iPhone.
#
# Gebruik:   bash apps-src/kaarten-en-slokken/build-ipa.sh
# Resultaat: apps-src/kaarten-en-slokken/build/kaarten-en-slokken.ipa
#
set -euo pipefail
cd "$(dirname "$0")"
ROOT="$(pwd)"
BUILD="$ROOT/build"
LOG="$BUILD/xcodebuild.log"
ARCHIVE="$BUILD/KaartenSlokken.xcarchive"
IPA="$BUILD/kaarten-en-slokken.ipa"
mkdir -p "$BUILD"

BUILD_NUMBER="${BUILD_NUMBER:-$(date -u +%y%m%d%H%M)}"
echo "==> Buildnummer: $BUILD_NUMBER"

command -v xcodegen >/dev/null 2>&1 || { echo "!! xcodegen ontbreekt — brew install xcodegen"; exit 1; }
echo "==> Xcode-project genereren uit project.yml"
xcodegen generate --quiet

echo "==> Archiveren (volledige log in $LOG)"
set +e
xcodebuild archive \
  -project "$ROOT/KaartenSlokken.xcodeproj" \
  -scheme KaartenSlokken \
  -configuration Release \
  -archivePath "$ARCHIVE" \
  -destination 'generic/platform=iOS' \
  CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" \
  DEVELOPMENT_TEAM="" PROVISIONING_PROFILE_SPECIFIER="" \
  > "$LOG" 2>&1
STATUS=$?
set -e
if [ $STATUS -ne 0 ]; then
  echo "!! ARCHIVE MISLUKT. De echte foutregels:"
  grep -E "error:" "$LOG" | head -20 || tail -30 "$LOG"
  exit 1
fi

APP_PATH="$(find "$ARCHIVE/Products/Applications" -maxdepth 1 -name "*.app" | head -1)"
[ -n "$APP_PATH" ] || { echo "!! Geen .app gevonden in het archief"; exit 1; }
[ -f "$APP_PATH/web/index.html" ] || { echo "!! web/index.html zit niet in de app"; exit 1; }

rm -rf "$BUILD/Payload" "$IPA"
mkdir -p "$BUILD/Payload"
cp -R "$APP_PATH" "$BUILD/Payload/"
(cd "$BUILD" && zip -qry "$(basename "$IPA")" Payload)
rm -rf "$BUILD/Payload"
echo "==> Klaar: $IPA ($(du -h "$IPA" | cut -f1), build $BUILD_NUMBER)"
