# Kaarten & Slokken

Uitleg-app voor kaart-drankspellen: Presidenten, Boerenbridge, Pesten, Kingsen, Paardenrace, Bussen, Hoger Lager en Dealertje. Het aantal spelers en de zwaarte (Rustig, Normaal, Stevig) passen de regels, het aantal kaartspellen en de slokken aan.

- `web/index.html`: de hele app in één bestand. Opent ook in een browser.
- `App/`: SwiftUI-schil die `web/index.html` offline in een WKWebView toont, plus het icoon.
- `project.yml`: XcodeGen-project (bundle-ID `com.javac.kaartenslokken`).
- `build-ipa.sh`: bouwt een niet-ondertekende IPA.

Deze app heeft geen eigen repo. De workflow `.github/workflows/build-kaarten-en-slokken.yml` bouwt hem op een macOS-runner van GitHub bij elke push naar `main` die deze map raakt, zet `kaarten-en-slokken.ipa` op de `latest`-release en werkt `apps.json` bij. De bundle-ID staat in `localBundleIdentifiers` in `config.json`, zodat `collect.sh` het item laat staan.
