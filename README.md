# Browser Generals — Zero Hour Tribute

A complete, single-file real-time strategy game — a fan-made browser tribute to
*Command & Conquer: Generals — Zero Hour*. The entire game (engine, rendering,
AI, audio, and art) lives in one self-contained HTML file with **zero
dependencies**. Double-click it, or play the hosted build.

### ▶ Play it live: https://browser-generals.web.app

## Features

- **3 factions** — USA (air superiority, snipers, Tomahawks), China (hordes,
  Overlords, napalm), and GLA (swarms, suicide units, SCUDs, no power needed).
- **31 unit types** (~10 per faction) plus faction-specific base defenses.
- Harvester economy, base building with tech prerequisites, power management,
  A\* pathfinding, fog of war, a weapon-vs-armor damage model, homing rockets
  and splash artillery.
- A skirmish **AI opponent** (random opposing faction) with Easy / Normal / Hard
  difficulty, escalating attack waves, and base defense behavior.
- Drag-select, attack-move, control groups, minimap, and synthesized SFX.

## Controls

| Input | Action |
|-------|--------|
| Left-click / drag | Select units (Shift adds) |
| Right-click | Move / attack / harvest / set rally |
| `A` then click | Attack-move |
| `S` | Stop |
| `Ctrl`+`1`–`9` | Assign control group |
| `1`–`9` | Select group (tap twice = jump camera) |
| Arrow keys / screen edges / minimap | Scroll camera |
| `P` / `M` / `Esc` / `H` | Pause / Mute / Cancel / Help |

**Win:** destroy every enemy structure. **Lose:** lose all of yours.

## Repository layout

| Path | Purpose |
|------|---------|
| `generals-zero-hour.html` | The game — canonical source, the file you edit |
| `public/index.html` | Deployed copy served by Firebase Hosting (generated) |
| `firebase.json`, `.firebaserc` | Firebase Hosting config (site `browser-generals`) |
| `deploy.ps1` | Syncs changes to Firebase Hosting **and** commits/pushes to GitHub |

## Deploying / syncing

`deploy.ps1` is idempotent and safe to run repeatedly:

```powershell
./deploy.ps1          # deploy to Firebase if the game changed, then commit + push
./deploy.ps1 -Force   # force a Firebase redeploy regardless of timestamps
```

It only redeploys to Firebase when `generals-zero-hour.html` is newer than the
last deployed copy, and pushes whenever local `main` is ahead of `origin`.

## Continuous deployment (push from anywhere, incl. mobile)

A GitHub Actions workflow ([`.github/workflows/firebase-hosting.yml`](.github/workflows/firebase-hosting.yml))
deploys to Firebase Hosting on every push to `main`. This means a change pushed
from **any** machine — including a Claude session dispatched from a phone — goes
live automatically, without needing this laptop or its local deploy hook.

**One-time setup** — add a single repository secret so the runner can deploy:

1. On a machine with the Firebase CLI, run `firebase login:ci` and copy the token.
2. In the repo: **Settings → Secrets and variables → Actions → New repository secret**
   - Name: `FIREBASE_TOKEN`
   - Value: the token from step 1
3. Push anything to `main` (or run the workflow manually from the Actions tab).

### Editing from your phone

1. Dispatch a Claude session against `sunsetsarge/browser-generals` from the Claude
   mobile app / claude.ai.
2. Describe the change; Claude edits `generals-zero-hour.html` and pushes to `main`.
3. The Action redeploys Firebase — refresh https://browser-generals.web.app to see it.

---

*Single-file RTS · HTML5 Canvas · vanilla JS · Web Audio. Built with Claude Code.*
