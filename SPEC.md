# SPEC.md — Browser Generals: Design Decisions (Finish & Ship)

Authored 2026-07-02 by the Fable 5 architect session, after a full read of
`generals-zero-hour.html` (2302 lines) and an inventory of `assets\` (417 files).
This document is the WHAT/WHY. `PLAN.md` is the HOW/WHEN. `RESKIN_MAP.md` is the
rename table. Executing agents: treat numbers here as the source of truth; if a
number conflicts with PLAN.md, SPEC.md wins.

Ground truth used throughout (verified in code):
- Damage model: `DMG` table (line ~250), 6 weapon types × armor classes `inf/light/heavy/building` + `air` column.
- Factions: `FACTIONS` object (line ~262) — USA / CHINA / GLA, each ~11 buildings, 13–14 units.
- Veterancy: `VET_REQ=[2,5,9]`, multipliers `VET_DMG/[1,1.20,1.45,1.75]` etc.; PERKS (4, faction-identical).
- Audio: `sfx(kind,x,y)` supports exactly `shoot, rocket, boom, cash, click`; FOV-gated; budget 8 voices/120ms.
- Map: `genMap()` — tree clumps, rocks, 3 carved corridors, supply clusters; NO reachability guarantee.
- Sprites: 42 directional unit sets registered (`loadDirSprites`), 18 building keys registered but only 17 sets on disk — **`bld_tunnel_*.png` is missing**; walls are procedural (`drawWall`).

---

## 1. Faction Asymmetry Design

### Design rules
1. Each faction gets exactly **one signature advantage mechanic** and **one signature disadvantage mechanic**, plus its existing statistical identity (prices/HP/speeds already in `FACTIONS`). Fewer, stronger levers — not a stat soup.
2. Mechanics must work identically for the AI (owner 1) with zero AI-specific code where possible (passive auras/economy hooks, not micro-dependent abilities).
3. All numbers live in one new top-level constant `FACTION_MODS` so balance retuning is a one-place edit:

```js
const FACTION_MODS={
  USA:  {vetKillMul:1.5, idleHealPct:0.015, idleHealDelay:4, lowPowerRate:0.35},
  CHINA:{hordeRadius:160, hordeCount:3, hordeDmg:1.25, hordeSpd:1.10,
         buildTimeMul:1.15, reactorBoom:{dmg:220, aoe:110}},
  GLA:  {salvagePct:0.15, salvageCap:400, buildTimeMul:0.90, hpMul:0.92},
};
```

### USA — "Quality" (few, expensive, self-improving)
- **Advantage — Veteran Edge.** USA kills count ×1.5 toward veterancy (`srcEnt.kills += 1.5` for USA in `killEnt`), and USA units **self-repair 1.5% maxHp/s after 4s without dealing or taking damage** (field drones flavor). USA is the only faction whose army gets *stronger the longer it survives*.
- **Disadvantage — Fragile logistics.** USA has the priciest roster (already encoded: Ranger $200 vs Rebel $120; power plant chain mandatory) and **low power hits USA hardest**: production rate ×0.35 when low-power (vs 0.5 for China; GLA immune). Losing units or reactors hurts USA more than anyone.
- **Economy/tempo identity:** slowest start, strongest late. Chinook harvester flies over terrain (uninterdictable paths) with cap 300 — highest-security income. USA should feel: protect the army, win with tech + air + elite vets.

### China — "Mass" (horde, tough, slow)
- **Advantage — Horde Bonus** (authentic-to-genre, purely passive): any China ground combat unit (has `def.w`, not `harv`/`builder`, not `air`) with **≥3 other friendly China combat units within 160px** gets **+25% damage and +10% speed**. Recompute on the existing `scanT` cadence (~0.3–0.5s), cache as `u.horde=true`, render a small red ★ pip. Works for AI automatically because the AI already masses waves.
- **Disadvantage — Slow, volatile infrastructure.** All China build times ×1.15 (units and buildings, applied at def-load time). **Nuclear Reactors explode on death**: `killEnt` on a China `power` building triggers `splashDamage(x,y,{type:'blast',dmg:220,aoe:110}, -1 /*hits everyone incl. owner*/)`. Raiding China's power grid is now a real counter-strategy — and clustering reactors is a Chinese player's own mistake to make.
- **Economy/tempo identity:** mid game is China's window. Cheap $150 Red Guard pairs (`count:2`) and $800 tank line; horde bonus means China's army value multiplies when massed, but it arrives late to fights (slow speeds, slow builds).

### GLA — "Scavenger" (cheap, sneaky, fragile)
- **Advantage — Salvage economy.** When a GLA-owned unit destroys any enemy unit or building, the GLA player instantly receives **15% of the victim's cost (cap $400)** with a "+$X scrap" floating text. Combined with the existing no-power rule, Black Market ($8/s), and the cheapest+fastest roster (build times ×0.90), GLA *profits from fighting* and cannot be power-crippled.
- **Disadvantage — Fragile and grounded.** GLA unit maxHp ×0.92 (applied at load), **no aircraft at all** (already true — this is now official design, do not add GLA air), and no self-repair. GLA loses any stand-up fight of equal cost; it must trade, raid, and rebuild cheaper than the enemy.
- **Economy/tempo identity:** fastest start (cheapest barracks $400, Worker builds AND harvests). GLA wants constant early-mid aggression; every trade feeds the salvage loop. If the game goes long against USA air/superweapons, GLA is losing.

### The triangle (why it's complementary, not mirrored)
- **USA > GLA:** splash (Aurora/Tomahawk), air power GLA can barely reach, and snipers erase the cheap infantry mass. GLA's −8% HP and salvage cap mean it can't out-trade precision AoE; USA's few-unit army gives salvage little to feed on.
- **GLA > China:** China's slow, expensive horde is a salvage buffet — every $800 tank GLA kills pays $120. Reactor explosions reward exactly the hit-and-run raids GLA's fast cheap units (Technical 145 sp, Cycle 170 sp) are built for, and GLA ignores the power game entirely.
- **China > USA:** horde bonus outscales veterancy in big fights (+25% dmg on 20 units beats +45% on 6), and USA can't afford 1:1 trades against a roster ~30–40% cheaper. Gattling everything blunts USA's air edge.
- Every faction has a clear "prey" and a clear "predator." None of the three mechanics is a mirrored copy of another (self-improvement vs. mass-scaling vs. economy-from-combat).

### UI surfacing (required, or the design is invisible)
- Faction cards on the start screen: rewrite `desc`/`tag` to name the advantage AND disadvantage explicitly.
- In-game: horde ★ pip (China), "+$X scrap" text (GLA), subtle green cross pip while a USA unit is self-repairing, tooltip lines in `tooltipFor()`.

---

## 2. Balance Model — damage-vs-armor intent + faction layer

The existing `DMG` matrix encodes the counter web. Its INTENT (preserve when tuning):

| weapon | beats | loses to (deals ≤0.25×) | carried by |
|---|---|---|---|
| bullet | infantry (1.0), air (0.45 w/ aa) | heavy armor, buildings (0.25) | rifles, gattling, humvee |
| cannon | light+heavy vehicles (1.0), buildings (0.9) | air (0), poor vs inf (0.6) | tank lines |
| rocket | everything moderately; only reliable AA (1.1 air) | nothing hard-countered | AT inf, AA, jets |
| flame | infantry (1.4), buildings (1.1) | heavy (0.6), air (0) | Dragon, Toxin, Inferno |
| sniper | infantry only (3.0) | all vehicles/buildings (≤0.15) | Pathfinder, heroes |
| blast | buildings (1.4), general splash | air (0) | artillery, superweapons, suicide |

Faction asymmetry (§1) layers ON TOP of this matrix; it does not modify the matrix itself. Tuning knob order when a matchup feels wrong: (1) FACTION_MODS number, (2) unit cost, (3) unit stat, (4) DMG cell — touch the matrix last, it moves everything.

**Canonical duel checks** (run via debug panel spawn, equal total cost, flat ground, attack-move into each other; "wins" = survivors ≥ 25% of start value):
1. $2400 Battlemasters (3) vs $2400 Rangers (12) → tanks win (cannon 0.6 vs inf is still enough vs bullets 0.25 vs heavy).
2. $2400 Rangers (12) vs $2400 Dragon Tanks (3) → Dragons win (flame 1.4 vs inf).
3. $1800 Gattling Tanks (2.25≈2) + $700 → vs 1 Comanche $1500 → Gattlings win (AA bullet).
4. 1 Paladin $1100 vs 1.5 Scorpions $1050 → close/Paladin slight edge (quality tax visible but not free).
5. China horde check: 8 Battlemasters clustered vs 8 spread (vs same defense line) → clustered clear ≥25% faster.
6. GLA econ check: GLA kills a $1800 Overlord → +$270 shown and banked.

---

## 3. Audio Design

### Constraints & sourcing decision
Single-file architecture stays. **All v1 audio is Web-Audio synthesis** — zero licensing exposure, zero bytes of assets. Embedding sampled voice/music as base64 would add MBs and create licensing surface; rejected for v1. Two clearly-labeled options beyond synth:
- **EVA-style announcer via `speechSynthesis`** (built into browsers, no assets, no license): OFF by default behind a settings toggle; voice quality varies by OS. Text lines like "Unit ready", "Base under attack", "Superweapon detected".
- **Music:** v1 ships a procedural ambient bed (below). A composed loop is Parity Backlog; if ever sourced, it MUST be CC0 or explicitly commercially-licensed royalty-free, license text committed to the repo (`AUDIO_LICENSES.md`) — attribution-required tracks (e.g., CC-BY) need the credit string in-game.

### Engine changes
Keep `sfx(kind,x,y)` signature, FOV gating, and the voice budget (raise 8→10). Add: per-kind pitch jitter ±12% (breaks machine-gun monotony), a master `sfxGain` + `ambGain` (persist volume + mute in `localStorage`), and non-positional alert kinds that bypass `sfxVol` but carry their own cooldown so alarms can't spam.

### Sound event table
P = positional (FOV-gated), N = non-positional. All synth unless noted.

| # | Event | Trigger point in code | Kind | Synth recipe (concise) | Pos | Cooldown |
|---|---|---|---|---|---|---|
| 1 | UI click | existing call sites | `click` | keep existing triangle 520Hz | N | — |
| 2 | Insufficient funds / can't place | `queueUnit`/`tryPlaceAt` fail paths (owner 0) | `deny` | square 180Hz, 90ms, two dips | N | 0.3s |
| 3 | Place building | `tryPlaceAt` success | `place` | low thud: sine 120→60Hz + noise tick | P | — |
| 4 | Construction complete | `updateBuilding` `b.done=true` | `built` | rising triad arpeggio 440/554/659, 0.35s | N (owner 0) | — |
| 5 | Unit ready | production spawn in `updateBuilding` | `ready` | two-tone chirp; base pitch per faction: USA 660, China 520, GLA 440Hz | N (owner 0) | 0.5s |
| 6 | Select acknowledge | selection code paths | `ack` | 30ms radio-squelch noise burst + faction-pitch blip | N | 0.15s |
| 7 | Move/attack order | `issueCommand`/`issueAMove` | `order` | ack + upward 60ms sweep (attack: downward) | N | 0.15s |
| 8 | Bullet fire | `fire()` type bullet | `shoot` | keep; add pitch jitter | P | budget |
| 9 | Cannon fire | `fire()` type cannon | `cannon` | 60Hz sine thump + 80ms lowpass noise crack | P | budget |
| 10 | Rocket fire | `fire()` rocket | `rocket` | keep sawtooth whoosh + jitter | P | budget |
| 11 | Flame fire | `fire()` flame | `flame` | 0.25s bandpassed noise "whoosh", 400→200Hz | P | budget |
| 12 | Sniper fire | `fire()` sniper | `sniper` | sharp crack: square 1400→180Hz in 40ms + noise tick | P | budget |
| 13 | Blast/artillery fire | `fire()` blast | `thump` | deep 50Hz sine + slow noise tail 0.4s | P | budget |
| 14 | Small explosion | `explosion()` size<30 | `boom` | keep existing | P | budget |
| 15 | Large explosion | `explosion()` size≥30 | `bigboom` | boom + 0.9s 45Hz sub layer + longer noise | P | budget |
| 16 | Building destroyed | `killEnt` building | `collapse` | 1.2s brown-noise rumble, lowpass 300Hz, 3 debris ticks | P | — |
| 17 | Cash deposit | harvester deposit | `cash` | keep | P | — |
| 18 | Salvage pickup (GLA) | salvage grant | `scrap` | cash recipe pitched −5 semitones | P | — |
| 19 | Veterancy promote | `checkPromote` | `promote` | two-note bugle-ish square 523→784Hz | N (owner 0) | — |
| 20 | Low power alarm | `lowPower(0)` rising edge | `alarmPower` | alternating 440/330Hz square, 3 cycles | N | 12s |
| 21 | Base under attack | `dealDamage` on owner-0 building, player not looking (reuse `pings` logic) | `alarmAttack` | klaxon: saw 600→300Hz ×2 | N | 12s |
| 22 | Enemy superweapon online | `onSuperBuilt` enemy branch | `alarmSuper` | 3 descending minor notes, ominous 0.8s | N | — |
| 23 | Own superweapon ready | `superT` reaches 0 (owner 0) | `superReady` | bright major fanfare 0.6s | N | — |
| 24 | Superweapon launch | `fireSuper` | `superFire` | rising shriek saw 200→1200Hz 0.7s, then rely on booms | N | — |
| 25 | Victory | `endGame(true)` | `win` | 4-note major fanfare, 1.6s | N | — |
| 26 | Defeat | `endGame(false)` | `lose` | 3-note descending minor, 1.6s | N | — |
| 27 | Ambient bed | starts after `audioInit`, gameplay only | `amb` | looping filtered brown noise "wind", gain 0.015; battle-intensity sublayer (gain follows explosions in last 5s, max 0.03) | N | continuous |
| 28 | Music | menu + gameplay | — | **Parity Backlog.** Procedural loop or licensed track later. | — | — |

Acceptance criteria for the audio workstreams are in PLAN.md WS-3.x.

---

## 4. Sprite QC Rubric + Regenerate Loop

### Why a harness first
Headless agents cannot judge art. Ship a **sprite gallery mode** (`?gallery=1`): renders every registered unit key × 8 frames and building key × 3 states in a labeled grid on the game canvas, on the actual terrain-sand background color, at actual in-game size AND ×3 zoom. One screenshot of this page = the whole QC review input. (PLAN WS-0.2.)

### Rubric — a sprite set PASSES only if all 8 checks pass
1. **Type-read:** at in-game size on sand (#a8915c), a reviewer who has NOT seen the label can name the class (infantry / truck / tank / artillery / jet / heli / building-of-role). If the answer is "blob" or wrong class → FAIL.
2. **Facing:** frame 0 nose/barrel points East within ±15°; frames advance clockwise in 45° steps (verify cardinals: 0=E, 2=S, 4=W, 6=N). NOTE: facing was already remapped and verified for vehicles/air; infantry were always correct — this check is for NEW/regenerated art. Do not re-flip existing frames.
3. **Transparency:** fully transparent background; no white/checkerboard box; edge halo ≤1px.
4. **Scale sanity:** rendered at its registered `size` (30–62px table in `loadDirSprites` calls), respects the hierarchy infantry(30) < light vehicle(32–36) < MBT(36–40) < Overlord/SCUD(44–50) < dozers/bus(54–62). A Humvee must not out-bulk a Paladin.
5. **Perspective:** consistent high-angle 3/4 top-down; no side-view or front-view frames mixed into a set.
6. **Lighting:** light from top/upper-left in every frame; no frame-to-frame light flips (causes strobing while turning).
7. **Cleanliness:** no baked text/watermarks, no floating disconnected parts, no extra limbs/barrels, no heavy JPEG noise.
8. **Buildings only:** `_0` pristine, `_1` clearly damaged (scorch, holes, smoke stains), `_2` heavily wrecked — same footprint, silhouette, and camera angle across all three.

### Regenerate loop (per failing asset)
1. Record which rubric check(s) failed (that's the whole review output — one line per asset).
2. Generate 4 candidates (ComfyUI local or Stability MCP) using the standing prompt template: *"top-down 3/4 view military <unit description>, game sprite, facing right, neutral desaturated hull, desert palette, clean silhouette, transparent background, no text"* + negative prompt targeting the specific failure (e.g., "side view" / "white background" / "text, watermark").
3. Background-strip (`stability-ai-remove-background` or ComfyUI rembg), scale to frame size, then rotate/derive the 8 facings the same way the existing pipeline did (or regenerate per-facing if the source pipeline was per-angle).
4. Re-run gallery → vision re-review. Max 3 rounds per asset, then flag for Blaine with the candidates side-by-side.

Known items entering the loop: **`bld_tunnel_0..2.png` (missing entirely — game currently falls back to the 🕳️ emoji)**, plus whatever the first gallery review fails.

---

## 5. Terrain & Static Objects

### What "realistic terrain" means here (single-file, procedural)
No image assets. Everything is drawn once into the pre-rendered `terrCanvas` (already exists — zero per-frame cost), upgraded from "flat sand + polka dots" to layered procedural ground:

1. **Biomes (3):** chosen per match (random, or a new menu row). Each biome = a palette object `{base, mottleA, mottleB, roadColor, treeKind, rockA, rockB, waterAllowed}`:
   - `desert` (current look: #a8915c base, green scrub trees, tan rocks)
   - `steppe` (olive #8f9455 base, darker green trees, grey rocks)
   - `badlands` (rust #a3714f base, sparse dry shrubs, red-brown mesas, no water)
2. **Ground texture:** seeded 2-octave value noise (implement a tiny `mulberry32` PRNG + bilinear noise, ~30 lines) rendered as low-alpha light/dark patches at two scales (dune banding ~200px wavelength + fine grain ~40px). Keep the existing subtle tile grid.
3. **Roads:** after `carve()` runs, stamp the carved corridor paths onto `terrCanvas` as packed-dirt roads (darker strip, 2 faint wheel-rut lines, alpha ~0.25). The three corridors become *visible*, which doubles as gameplay legibility (players see the attack routes).
4. **Cliff/cluster edges:** blocked-terrain clusters get a 2px dark rim + 1px top highlight on the north edge so obstacles read as raised, not painted.
5. **Water (new):** `terr` value 3, impassable (blockGrid 1). 0–3 ponds per map (biome-gated), blob-grown 4–12 tiles, ≥12 tiles from any base center and never on carved corridors. Drawn as layered blues with a pre-rendered 2-frame shimmer (swap every 0.8s — two small canvases, still cheap). Air units ignore it; pathfinding already respects blockGrid.
6. **Decor variety:** trees get per-instance radius/hue jitter (exists) + 2 new shapes per biome (cactus column, dry shrub); rocks get the biome palette.

### The ALGORITHMIC no-wall-in guarantee (hard requirement)
After `genMap()` finishes (terrain + rocks + water + supplies placed, BEFORE `blockGrid.set(terr)` consumers run):

```
repeat up to 12 times:
  comp = BFS flood-fill of open tiles from P_BASE tile
  bad  = []
  if A_BASE tile ∉ comp: bad.push(A_BASE)
  for each supply pile: if no open tile in its 8-neighborhood ∈ comp: bad.push(pile)
  if comp.size < 0.90 × total open tiles: bad.push(centroid of largest unreached open region)
  if bad is empty: PASS → done
  else: carve(P_BASE → bad[0]) using the existing 5-wide carve(), re-loop
if still failing after 12 iterations: regenerate the whole map (fresh genMap), max 3 regens, then throw
```

Cost: BFS on ≤128²=16,384 tiles is sub-millisecond; runs once per match. Additional standing rules: the existing base-clear radius (9 tiles) stays; supply clusters keep their "not on terrain" placement check; AI building placement (`aiPlace`) cannot create wall-ins because `canPlace` requires open tiles and units path around buildings — player self-walling with the wall tool is allowed (it's a strategic choice, and dozers can demolish).

**Test harness:** `?test=map` URL param auto-runs 50 generations × {small,medium,large} × {bl,tl,tr,br,center}, logs `MAPTEST PASS n/n` or failing seeds to console, and renders the last map. Acceptance = 100% pass. (PLAN WS-2.3.)

---

## 6. Animation Spec

- **Infantry (sprite path):** sprites are single top-down images per facing — correct decision was made to stop squash/bob. Restore gait by drawing the EXISTING procedural leg cycle (already implemented in the vector fallback, lines ~1676–1698) **underneath the sprite image** when `u.moving`, rotated to `u.face`, legs poking out below the torso silhouette. Sprite torso covers the hips; net effect = walking legs under every infantry sprite. Scale legs to `spr.size/30`.
- **Vehicles:** keep recoil kickback + tread dust. Add: 3px turret-flash offset already exists via muzzle `flash` particle — verify it spawns at the sprite barrel tip (use `spr.size*0.45` forward, not hardcoded `u.r`).
- **Helis:** keep spinning rotor overlay + downwash. No change.
- **Jets:** add a thin contrail particle pair when `u.moving` (2 alpha-fading line particles/frame-ish, budgeted), spawned behind wings (`-0.4*size` along facing ±20% lateral).
- **Buildings:** damage smoke exists; add slow "working" pulse on production buildings (1px glow border oscillation while `queue.length>0`) so activity reads at a glance.
- **Harvesters:** carry-state already drawn (gold box). Keep.

---

## 7. Monetization / IP

### Two paths — pick per goal
- **Path A — personal tribute build (no revenue):** keep names, skip re-skin. Honest note: even non-commercial use of "Command & Conquer", "Zero Hour", and EA unit marks in the title/subtitle carries takedown risk (DMCA/trademark), historically low for non-commercial fan work but never zero. Do not run ads on it, ever — ads = commercial use.
- **Path B — commercial (app stores / any revenue):** the re-skin is **mandatory before the first dollar**. Execute `RESKIN_MAP.md` (mechanical rename — gameplay untouched), retitle to **IRON SUNSET**, remove the tribute subtitle, replace README/branding, and spot-check visual trade-dress: any sprite that is unmistakably an EA-designed unit (the double-barreled Overlord silhouette is the main one) gets a regenerate pass with a differentiated design (e.g., single oversized cannon + missile rack). Real-world vehicle shapes (an F-22-looking jet) are fine; *EA's fictional designs* are the trade-dress risk. Also rename "Terrorist" → "Fanatic" (RESKIN_MAP) — beyond IP, a player-controlled "Terrorist" suicide unit is an app-store content-rating landmine.

### Packaging (honest effort levels)
| Target | Approach | Effort | Notes |
|---|---|---|---|
| Web (exists) | Firebase Hosting, already live | done | browser-generals.web.app; rename site for Path B |
| Installable web | PWA: manifest + service worker + icons | 1 agent-day | Offline-capable since single-file; "Add to Home Screen" on Android/iOS Safari. **Do this first — 80% of the mobile win.** |
| Google Play | Capacitor (or Bubblewrap/TWA since it's a PWA) | 2–4 agent-days + human steps | $25 one-time dev account, keystore, privacy policy URL, content rating questionnaire (war themes + "Fanatic" unit → likely Teen), store listing assets. TWA route is far less code than Capacitor for a game that's already a working PWA. |
| Apple App Store | Capacitor + Xcode | highest friction | Requires a Mac + $99/yr + review that is hostile to "website in a wrapper" apps — Apple guideline 4.2 risk is REAL for a wrapped canvas game. Recommendation: ship PWA (installable on iOS Safari) and skip the App Store for v1. |

### Monetization recommendation (anti-hype, per operating doc)
Ranked: (1) **Free web + $2.99 one-time on Google Play** ("supporter build", maybe + a couple of exclusive maps). (2) itch.io pay-what-you-want mirror (zero gatekeeping, real RTS audience). (3) Ads — **rejected** for v1: AdMob inside a canvas RTS wrecks UX, adds privacy-policy/consent work, and single-player browser RTS traffic won't cover the effort. Honest expectation: without a marketing motion this is a portfolio piece earning coffee money; the demand-generation work is out of scope of this plan and should not be assumed.

---

## 8. Explicit non-goals for this plan (Parity Backlog — post-ship)
Deferred, honestly, because they don't fit single-agent passes or aren't needed to ship:
- Generals' Powers / promotion tree (the sidebar generals abilities from ZH)
- Garrisonable neutral civilian buildings; capturable tech structures
- Naval anything; superweapon variety beyond the 3 existing
- Multiplayer (architecture is single-process lockstep-hostile; would be a rewrite)
- Campaign / scripted missions / Generals Challenge; replays/observers
- Composed music score; sampled voice acting
- Map editor; more than 3 biomes; save-file versioning beyond v1 snapshot
