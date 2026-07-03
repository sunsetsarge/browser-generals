# IRON SUNSET — Browser RTS

A complete, single-file real-time strategy game. The entire game (engine,
rendering, AI, audio, and art) lives in one self-contained HTML file with **zero
dependencies**. Double-click it, or play the hosted build.

### ▶ Play it live: https://browser-generals.web.app

## Features

- **3 factions** — the **Meridian Coalition** (air superiority, marksmen, cruise
  launchers), the **Ironclad Pact** (massed armor hordes, super-heavy tanks,
  napalm), and the **Jackal Syndicate** (cheap swarms, suicide units, rocket
  artillery, no power needed).
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

> The source filename, Firebase site, and GitHub repo slug keep their legacy
> `browser-generals` / `generals-zero-hour` names for now — renaming them breaks
> links, saved games, and sprite paths for no player-facing benefit. Only the
> display strings are re-skinned to **Iron Sunset**.

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

1. Dispatch a Claude session against the repo from the Claude mobile app / claude.ai.
2. Describe the change; Claude edits `generals-zero-hour.html` and pushes to `main`.
3. The Action redeploys Firebase — refresh the live URL to see it.

---

## Balance log

Phase 1 (Faction Asymmetry) canonical duels — run 2026-07-02 via a headless
duel harness (equal total cost, flat ground, attack-move into each other; each
step pumps `update(0.05)`; "win" = surviving value ≥25% of start). Faction mods
(`FACTION_MODS`) apply to both owners as designed. Expected outcomes from SPEC §2.

| # | Matchup (equal cost) | Expected | Result | Survivor value | Verdict |
|---|---|---|---|---|---|
| 1 | 3 Mastiff Tanks ($2400) vs 12 Troopers ($2400) | Tanks win | **Tanks win** in 27.2s | Tanks 67% (2/3), Troopers 0% | ✅ match |
| 2 | 12 Troopers ($2400) vs 3 Salamander Tanks ($2400) | Salamanders win | **Salamanders win** in 7.1s | Salamanders 100%, Troopers 0% | ✅ match |
| 3 | 2 Shredder Tanks ($1600) vs 1 Kestrel Gunship ($1500) | Shredders win | **Shredders win** in 9.1s | Shredders 100%, Kestrel 0% | ✅ match |
| 4 | 2 Warden Tanks ($2200) vs 3 Sandviper Tanks ($2100) | Close / Warden edge | **Wardens win** in 17.8s | Wardens 50% (1/2), Sandvipers 0% | ✅ match (quality tax visible — lost half) |
| 5 | 8 Mastiff Tanks clustered vs spread | Clustered ≥25% faster | Clustered deals **+32.6% damage** in a 20s DPS test (7351 vs 5543); per-unit horde bonus verified exact (×1.25 dmg, ×1.10 spd) | ⚠️ directional pass (see note) |
| 6 | Syndicate unit kills a $1800 Colossus Tank | +$270 shown & banked | **+$270 exactly**; non-Syndicate killer gets $0; cap holds at $400 on a $5000 target | ✅ match |

**Result: 5/6 clean matches + 1 directional pass. No tuning applied — every duel
landed inside SPEC expectation on the first pass.**

Note on duel 5: a perfectly-isolated "spread" comparison is not achievable
headlessly because attack-move funnels all attackers onto a single target, so the
"spread" group re-clusters at contact and partially earns the horde bonus too
(measured horde 5/8 vs 8/8). The mechanic itself is verified exact numerically
(a clustered Mastiff Tank reads DMG 69 = 55×1.25 and speed 86 = 78×1.10; moving
one out of range drops it back to 55/78 within ~1s). With a fully-massed group vs
a truly unmassed one the gap is ≥25% by construction. Not tuned — flagged only as
a test-harness limitation, not a balance miss.

### Verified acceptance numbers (Phase 1)

- WS-1.1: Syndicate Raider HP **101** (110×0.92); Pact Mastiff Tank build time
  **10.35s** (9×1.15) vs Coalition Bastion Tank **10s** unchanged; Syndicate
  barracks **6.3s** (7×0.90); Coalition low-power production rate **0.35** (vs 0.5
  others); faction cards state each advantage + disadvantage.
- WS-1.2: 4 clustered Mastiff Tanks → **horde on**, DMG **69**, speed **86**, red
  ★ pip; moving one 200px away drops the group to **55 / 78** within ~1s.
- WS-1.3: Syndicate kill of a Colossus Tank → **+$270**; Pact reactor death blasts
  nearby units (incl. its own owner's); Coalition/Syndicate power buildings do
  **not** explode; Coalition kill credit **×1.5** (kills go 1.5→3→4.5→6, vet 1 at
  2 kills, vet 2 at 4); isolated damaged Coalition Bastion Tank self-repairs
  **7.5 HP/s** (500×0.015) with a green cross pip; Pact/Syndicate units do not
  self-repair.

---

*Single-file RTS · HTML5 Canvas · vanilla JS · Web Audio. Built with Claude Code.*
