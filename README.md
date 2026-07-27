# app-distribution — publieke sideload-bron voor de JAVAC-apps

Deze **publieke** repo host de kant-en-klare **IPA's** + een **bron-JSON** (`apps.json`)
zodat **AltStore / SideStore / LiveContainer** je apps kunnen installeren én **automatisch
updaten**. Je **broncode blijft privé** — alleen de gecompileerde IPA's en app-iconen zijn
bereikbaar, via een onraadbare (obscure) map (`2e4312f7cb9b/`).

> ⚠️ Wat hier staat is publiek downloadbaar voor wie de link kent. De link is bewust
> moeilijk te raden, maar het is géén echte toegangscontrole.

---

## Zo werkt het

```
private app-repos            deze publieke repo               jouw iPhone
(Snusscounter, agora, …)  →  IPA's als release-assets     →   AltStore/SideStore/
push naar main = build       + apps.json (de "bron")           LiveContainer
                             ↑ collect.sh / workflow           (auto-update)
```

- `config.json` — welke apps in de bron zitten (repo, bundle-ID, naam, icon).
- `scripts/collect.sh` — haalt de nieuwste IPA uit elke private repo, upload 'm hier en
  schrijft `2e4312f7cb9b/apps.json`.
- `.github/workflows/collect.yml` — draait `collect.sh` automatisch (elk half uur, gratis
  want publieke repo draait op ubuntu).
- `setup.sh` — eenmalige opzet.

---

## Eenmalige opzet

```bash
cd app-distribution
bash setup.sh
```

Aan het eind print 't script je **bron-URL**. Die ziet er zo uit:

```
https://raw.githubusercontent.com/JackvanHecke/app-distribution/main/2e4312f7cb9b/apps.json
```

---

## De bron toevoegen op je iPhone

**LiveContainer**: open LiveContainer → tab *Repositories/Sources* → **+** → plak de bron-URL.
Installeer apps eronder; ze draaien als "gast" (omzeilt de 3-app-limiet).

**AltStore / SideStore**: tab *Browse* → *Sources* → **+** → plak de bron-URL → apps
verschijnen met een **Update**-knop zodra er een nieuwere build is.

---

## Automatisch updaten (aanrader)

De workflow ververst de bron elk half uur, maar heeft leesrechten op je **private** repos
nodig. Daarvoor maak je één keer een token:

1. GitHub → **Settings → Developer settings → Personal access tokens → Fine-grained tokens**.
2. Geef 'm toegang tot de repos: Snusscounter, agora, lumina, vigor, dispatch **en**
   app-distribution. Permissions: **Contents: Read** (voor de app-repos) en
   **Contents: Read and write** (voor app-distribution).
3. Kopieer het token.
4. In **deze** repo: **Settings → Secrets and variables → Actions → New repository secret**
   → naam **`DIST_TOKEN`** → plak het token.

Daarna: **Actions** → *Update source (collect IPAs)* → **Run workflow** (of wacht op de
half-uurlijkse run). Voortaan: push naar `main` van een app → nieuwe IPA → binnen 30 min
staat de update in de bron → je iPhone ziet 'm.

---

## Handmatig verversen (zonder token)

```bash
cd app-distribution
bash scripts/collect.sh
git add -A && git commit -m "update source" && git push
```

---

## Belangrijk om te weten

- **LiveContainer** omzeilt de 3-app-limiet en de 7-daagse reinstall per app — je onderhoudt
  alleen LiveContainer zelf (via SideStore vernieuwt dat automatisch over wifi).
- Niet elke native feature werkt perfect in LiveContainer (push-notificaties, widgets).
  Uitproberen; **dispatch** is de meest waarschijnlijke uitzondering.
- De iconen zijn gekopieerd uit de app-assets; veranderen ze, draai dan `setup.sh` opnieuw.
