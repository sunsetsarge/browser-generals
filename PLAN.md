# PLAN.md — Browser Generals: Finish & Ship Execution Plan

Authored 2026-07-02 (Fable 5 architect pass). Companion docs: `SPEC.md` (all design
numbers — SPEC wins on conflict), `RESKIN_MAP.md` (rename table).

## How to execute this plan
- **One workstream = one implementation agent pass** (Opus 4.8 for CODE unless noted; Sonnet is fine for WS marked [sonnet-ok]). Agents have no memory of the planning session — each WS below is self-contained.
- **File under change:** `C:\Users\blain\OneDrive\Documents\Claude\Projects\Generals_Clone\generals-zero-hour.html` — a single self-contained HTML file (~2300 lines, vanilla JS + Canvas 2D + Web Audio). **HARD RULE: keep it single-file, zero dependencies.** Assets live in `assets\` (`<key>_0..7.png` unit facings, 0=East clockwise; `bld_<key>_0..2.png` building health states).
- **Verify after every WS:** open the file locally in a browser, start a match each faction, play ≥2 minutes, watch the console for errors. Then run `./deploy.ps1` only when Blaine asks.
- **[CODE]** = fully automatable. **[ASSET-GEN]** = image generation + a VISION review step (a human or vision-capable agent must look at rendered output — a headless agent must NOT self-certify art quality).
- Phases are ranked by value-to-ship. Within a phase, workstreams are ordered; cross-phase dependencies are listed per WS.

### Phase order (value ranking)
| Phase | Theme | Why this rank |
|---|---|---|
| 0 | Test harness + verification | Everything downstream needs the gallery + map test to be checkable |
| 1 | Faction asymmetry | The #1 gameplay gap the owner named; pure code; high fun-per-line |
| 2 | Terrain + map integrity | Visible quality jump + the hard wall-in guarantee |
| 3 | Audio | Second-biggest named gap; pure code (synth) |
| 4 | Animation & visual polish | Cheap wins on top of existing systems |
| 5 | Sprite completion & QC | ASSET-GEN track; can run in parallel with 2–4 |
| 6 | Game-feel / UX / performance | Pause menu, save, perf guard — ship-quality items |
| 7 | Re-skin to original IP | REQUIRED for monetization path; optional for personal build |
| 8 | Package & ship | PWA → Play Store; monetization wiring |

---

## PHASE 0 — Harness & Verification

### WS-0.1 [CODE] [sonnet-ok] Facing + fallback verification sweep
- **Objective:** confirm the just-fixed sprite facing is correct everywhere and no registered sprite silently 404s.
- **Files/functions:** `loadDirSprites`, `dirIndex`, `drawUnit`, `BLD_SPRITES` registration; `deploy.ps1` asset filter.
- **Steps:** (1) Add a console table on load listing every registered sprite key with loaded-frame count (`set.ready`/`n`) and every building key with per-state ready flags. (2) Cross-check against `assets\` on disk; expected: all 42 unit sets 8/8, 17 building sets 3/3, `tunnel` 0/3 (known missing — falls back to emoji; fixed in WS-5.1). (3) In-game spot check: spawn (debug panel) one of each of humvee, crusader, raptor, comanche, overlord, scud, battlebus; order each to move E, S, W, N; sprite nose must lead within one 45° step. (4) Confirm infantry were NOT re-flipped (ranger moving East shows frame 0).
- **Acceptance:** console table shows expected counts exactly; 7-unit × 4-direction spot check passes; zero 404s in the network tab for `_0..7`/`_0..2` files that exist on disk.
- **Dependencies:** none.

### WS-0.2 [CODE] Sprite gallery mode (`?gallery=1`)
- **Objective:** one-screenshot review surface for all art — the enabler for every ASSET-GEN acceptance test in this plan.
- **Files/functions:** new `renderGallery()` + a branch in `frame()`/init when `location.search` contains `gallery`.
- **Steps:** when `?gallery=1`: skip menu, fill the canvas with terrain-sand (#a8915c), and draw a labeled grid: every registered unit key (all 8 frames in a row, frame index captioned, at registered size AND a second row at ×3), then every building key ×3 health states at 3-tile size. Include vector-fallback renders for anything without a loaded sprite (labeled "FALLBACK"). Paginate with ←/→ keys if it overflows; `?gallery=2` etc. deep-links pages.
- **Acceptance:** `file:///...generals-zero-hour.html?gallery=1` renders with zero console errors; every one of the 42 unit keys and 18 building keys appears exactly once across pages, labeled; a screenshot of each page is legible at 1920×1080.
- **Dependencies:** none. (Do this before Phase 5.)

### WS-0.3 [CODE] [sonnet-ok] Map test mode (`?test=map`)
- **Objective:** automated reachability regression harness (consumed by WS-2.3).
- **Files/functions:** new `runMapTests()`; `genMap`, `setMapSize`, `setupBases`.
- **Steps:** when `?test=map`: for each size {small,medium,large} × position {bl,tl,tr,br,center}, run `setMapSize+setupBases+genMap` 50×; after each, BFS flood-fill open tiles from P_BASE and record: A_BASE reachable? every supply pile edge-reachable? main-component share of open tiles ≥0.90? Log per-config pass counts and any failing seed (seed the PRNG per run — add a tiny seeded `mulberry32` used by `rand` only in test mode, or log `Math.random` replacement seed). Render the final map + print `MAPTEST n/750 PASS`.
- **Acceptance:** harness runs to completion in <30s and reports honest numbers. (Pre-WS-2.3 it may legitimately report failures — that's the point; record the baseline failure rate in the console output.)
- **Dependencies:** none.

---

## PHASE 1 — Faction Asymmetry (SPEC §1 — all numbers there)

### WS-1.1 [CODE] FACTION_MODS core + load-time stat application
- **Objective:** create the single balance-knob object and apply the passive stat layers.
- **Files/functions:** new `FACTION_MODS` const next to `PERKS`; def-load patch block (after the FACTIONS build-out patches, ~line 378); `unitHpMax`, `lowPower`-consuming `rate` sites in `updateBuilding`/`updateBuild`.
- **Steps:** (1) Add `FACTION_MODS` exactly as in SPEC §1. (2) At load: for CHINA defs multiply all `t` (build times, units+buildings) ×1.15; for GLA ×0.90; for GLA units multiply `hp` ×0.92 (round). Do this ONCE by mutating defs at startup (defs are shared by AI — correct, mods apply to both owners). (3) Low-power production rate: replace the two hardcoded `0.5` rates with `facOf(owner).key==='USA'?0.35:0.5`. (4) Update the three faction `desc`/`tag` strings on the start-screen cards to state advantage + disadvantage per SPEC §1 UI-surfacing.
- **Acceptance:** (a) tooltip build times differ: China Battlemaster shows t≈10.4s equivalent (queue completes ~15% slower than USA Crusader at equal base t — verify with a stopwatch on the queue progress bar); (b) GLA Rebel HP shows 101 (110×0.92) in selInfo; (c) with USA low power, a queued Ranger takes ~2.9× base time (1/0.35) vs China's 2× ; (d) faction cards show new text; (e) no console errors, all 3 factions playable.
- **Dependencies:** none.

### WS-1.2 [CODE] China Horde Bonus
- **Objective:** +25% dmg / +10% speed for massed China ground combat units.
- **Files/functions:** `updateUnit` (piggyback on `scanT`), `unitDmg`, `unitSpeed`, `drawUnit` (pip), `tooltipFor`.
- **Steps:** (1) Eligibility: `facOf(u.owner).key==='CHINA' && u.def.w && !u.def.harv && !u.def.builder && !u.air`. (2) Every scan tick (~0.35s), count OTHER friendly eligible China units within 160px (reuse the loop pattern from `acquire`; it's O(n) per unit per 0.35s — acceptable; if profiling shows pain, share WS-6.4's spatial grid). Set `u.horde=cnt>=3`. (3) `unitDmg` ×1.25 and `unitSpeed` ×1.10 when `u.horde`. (4) Draw a 3px red ★ (or triangle pip) above the HP-bar anchor when `u.horde`. (5) One line in China unit tooltips: "Horde: +25% dmg +10% speed near 3+ comrades".
- **Acceptance:** debug-spawn 4 Battlemasters clustered → selInfo DMG reads 69 (55×1.25) and pip shows; move one 200px away → remaining 3 lose the pip within 1s and DMG reads 55. Duel check SPEC §2 #5 passes (clustered clear ≥25% faster — time with a stopwatch vs a fixed defense line spawned via debug).
- **Dependencies:** WS-1.1.

### WS-1.3 [CODE] GLA Salvage + China reactor explosion + USA veteran edge
- **Objective:** the remaining three signature mechanics (they're each ~10 lines and share `killEnt`).
- **Files/functions:** `killEnt`, `dealDamage`→`splashDamage`, `checkPromote`/kill-credit line in `killEnt`, new idle-heal block in `updateUnit`, `drawUnit` (heal pip).
- **Steps:** (1) **Salvage:** in `killEnt`, if `srcEnt` is a GLA-owned unit and victim is enemy: `addMoney(srcEnt.owner, Math.min(400, Math.round(victim.def.cost*0.15)))` + floating text `+$X scrap` + `sfx('scrap')` fallback `'cash'` until WS-3.x lands. (2) **Reactor boom:** in `killEnt`, if victim is a building, `def.k==='power'`, owner faction CHINA: `splashDamage(x,y,{type:'blast',dmg:220,aoe:110}, -1, null)` — pass owner `-1` so BOTH sides take damage (verify `splashDamage` skips only `e.owner===owner`; -1 matches nobody). Add explosion visuals sized 110. (3) **USA vet rate:** kill-credit line becomes `srcEnt.kills += (facOf(srcEnt.owner).key==='USA'?1.5:1) * (srcEnt.owner===0?DBG.xpRate:1)`. (4) **USA idle heal:** track `u.lastCombatT` (set on dealing damage in `fire`/`engage` and on taking damage in `dealDamage`); in `updateUnit`, if USA-owned, alive, `G.time-u.lastCombatT>4`, `hp<maxHp`: `hp=Math.min(maxHp, hp+maxHp*0.015*dt)`; draw a small green cross pip while actively healing. Buildings excluded.
- **Acceptance:** (a) GLA unit kills a debug-spawned enemy Overlord → money increases by exactly $270 and text shows; a NON-GLA killer gets nothing. (b) Kill a China power plant with 3 adjacent friendly-to-it units around it → they take blast damage (China's own units hurt too); USA/GLA power plants don't explode. (c) USA Ranger reaches vet 1 after 2 kills' worth counted at 1.5× → i.e. 2 real kills (ceil(2/1.5)=2) but vet 2 after 4 real kills (5/1.5→3.33); verify selInfo kill counter increments by 1.5. (d) Damaged USA Crusader parked 5s starts visibly regaining HP (~10 hp/s on 680max... ≈10.2/s) with pip; China/GLA units don't. (e) SPEC §2 duel #6 passes.
- **Dependencies:** WS-1.1.

### WS-1.4 [CODE] [sonnet-ok] Asymmetry balance pass — run the canonical duels
- **Objective:** verify the whole SPEC §2 duel table; tune ONLY via `FACTION_MODS`/costs per SPEC's knob order; document results.
- **Files/functions:** `FACTION_MODS`, possibly unit `cost` fields; append a `## Balance log` section to README.md.
- **Steps:** run all 6 canonical duels from SPEC §2 via the debug panel (spawn owner Me vs Enemy, attack-move into each other). Record winner + surviving value. If a duel fails its expected outcome, adjust per knob order and re-run. Max 3 tuning iterations; if still off, log honestly in the Balance log and move on (flag for Blaine).
- **Acceptance:** all 6 duels' outcomes recorded in README Balance log with numbers; ≥5 of 6 match SPEC expectation; deviations flagged with a one-line hypothesis.
- **Dependencies:** WS-1.1, 1.2, 1.3.

---

## PHASE 2 — Terrain & Map Integrity (SPEC §5)

### WS-2.1 [CODE] Procedural ground upgrade + biomes
- **Objective:** layered noise ground, 3 biome palettes, corridor roads, cliff rims.
- **Files/functions:** `renderTerrain` (bulk of work), `genMap` (record carved paths into a `roads` array), new `BIOMES` const + per-match selection in `startGame`; optional start-screen row.
- **Steps:** implement SPEC §5 items 1–4: `mulberry32` PRNG + 2-octave value noise; biome palettes desert/steppe/badlands (random per match; if adding a menu row, copy the existing `diffRow` pattern); stamp roads along the carve paths (store waypoints when `carve()` runs); dark rim + top highlight on blocked clusters. Keep total `renderTerrain` time <150ms on a 128² map (it runs once).
- **Acceptance:** 3 screenshots (one per biome, forced via console `startGame` with a biome override) show visibly distinct, non-flat ground with readable roads between bases; `renderTerrain` console.time logs <150ms at 128²; minimap still legible; no per-frame FPS change (terrain is pre-rendered).
- **Dependencies:** none (WS-2.2 water plugs into the same palette object).

### WS-2.2 [CODE] [sonnet-ok] Water terrain type
- **Objective:** impassable ponds with cheap shimmer, biome-gated.
- **Files/functions:** `genMap` (terr value 3 growth + placement rules), `renderTerrain` (draw), `render` (2-frame shimmer swap), `blockGrid` semantics (3 → blocked), minimap.
- **Steps:** per SPEC §5.5: 0–3 blob ponds (4–12 tiles), ≥12 tiles from base centers, never on corridor paths; blockGrid treats 3 as blocked (audit every `terr[...]===1`/`>0` comparison); two pre-rendered pond overlays swapped every 0.8s; minimap shows water as blue.
- **Acceptance:** on maps with ponds: ground units path around water (order a tank across a pond → it routes around), air flies over, buildings can't be placed on it, shimmer visible, fps unchanged (±2) vs no-water map at 200 units.
- **Dependencies:** WS-2.1 (biome gate), WS-0.3 (test mode must treat water as blocked).

### WS-2.3 [CODE] Reachability guarantee (the wall-in fix)
- **Objective:** implement SPEC §5's flood-fill/carve/repair loop so no start or supply is ever enclosed.
- **Files/functions:** `genMap` tail; `runMapTests` (WS-0.3) as the oracle.
- **Steps:** exactly the SPEC §5 pseudocode: BFS from P_BASE; require A_BASE reachable, every supply edge-reachable, main component ≥90% of open tiles; carve toward the first offender; ≤12 repair iterations then full regen (≤3) then throw. Runs after water placement, before supplies are trusted (re-validate supplies since carving can't hurt them).
- **Acceptance:** `?test=map` reports **750/750 PASS** (50 × 3 sizes × 5 positions); added generation time <50ms average (log it). Baseline failure rate from WS-0.3 recorded before → after in the console output.
- **Dependencies:** WS-0.3, WS-2.2.

---

## PHASE 3 — Audio (SPEC §3 — the event table is the contract)

### WS-3.1 [CODE] Audio engine v2
- **Objective:** master/ambient gain nodes, persisted volume+mute, pitch jitter, alert cooldowns, budget 8→10.
- **Files/functions:** `audioInit`, `sfx`, `toggleMute`, new `AUDIO` settings object + `localStorage` persistence; topbar volume control (a small slider next to the mute button, hidden on mobile — mobile keeps mute only).
- **Steps:** route all voices through `sfxGain`→destination and a parallel `ambGain`; ±12% playbackRate/frequency jitter helper; `alertCd` map keyed by kind; persist `{vol, muted}`; restore on load.
- **Acceptance:** volume slider audibly scales all sfx; setting survives a reload; firing 30 bullets/s doesn't sound like a single flat tone (jitter audible); muting kills everything including ambient.
- **Dependencies:** none.

### WS-3.2 [CODE] Combat & world sounds (SPEC table rows 3, 9, 11–16, 18)
- **Objective:** distinct synth voices per weapon type + impacts + building collapse + salvage.
- **Files/functions:** `sfx` new kinds (`place, cannon, flame, sniper, thump, bigboom, collapse, scrap`); call sites `fire()` (switch on `w.type` — currently collapses everything to shoot/rocket), `explosion()` (size threshold 30), `killEnt` (building branch), WS-1.3's salvage grant.
- **Steps:** implement each recipe from the SPEC table verbatim; wire call sites; keep every voice ≤0.4s except collapse (1.2s) so the budget holds.
- **Acceptance:** with eyes closed, a reviewer can tell cannon vs bullet vs sniper vs flame vs artillery fire from a staged battle (spawn each type via debug, fire at a wall); building death sounds distinct from unit death; GLA kill plays the scrap chime. No budget starvation: a 40-unit battle still plays explosions (audible test) and console shows no AudioContext warnings.
- **Dependencies:** WS-3.1 (jitter/gain plumbing), WS-1.3 (salvage hook exists).

### WS-3.3 [CODE] Feedback & alert sounds (SPEC table rows 2, 4–7, 19–26)
- **Objective:** production/selection/order acknowledgements, alarms with cooldowns, super/victory stingers, promote sting.
- **Files/functions:** `sfx` new kinds; call sites: `queueUnit`/`tryPlaceAt` deny paths, `updateBuilding` (done + unit spawn), selection handlers (`selectRect`, click/tap select), `issueCommand`/`issueAMove`, `checkPromote`, `lowPower(0)` rising-edge detector in `update` (track prev state), owner-0 building damage → `alarmAttack` (reuse the `G.pings` push site, only when the building is off-screen — check against `G.cam` viewport), `onSuperBuilt`, superT-ready rising edge, `fireSuper`, `endGame`.
- **Steps:** per SPEC table; faction-pitched ready/ack chirps (USA 660 / China 520 / GLA 440 Hz); 12s cooldowns on the two alarms; 0.15s throttle on ack/order so drag-selects don't machine-gun.
- **Acceptance:** build a barracks → `built` chime on completion; train a Ranger → faction-pitched `ready`; select/move/attack each produce distinct short acks, throttled (drag-select 20 units = one ack); kill player power → alarm once, not again for 12s; enemy superweapon completes → ominous alert + banner (existing) together; win and lose → distinct stingers. All alerts audible with the camera far away (non-positional).
- **Dependencies:** WS-3.1.

### WS-3.4 [CODE] [sonnet-ok] Ambient bed + optional speech announcer
- **Objective:** SPEC rows 27 + the OFF-by-default `speechSynthesis` announcer.
- **Files/functions:** `audioInit`/game-state watcher for the loop; `AUDIO.announcer` flag + settings toggle (pause menu WS-6.1 hosts the toggle; until then a debug-panel row); announcer lines: "unit ready", "construction complete", "base under attack", "superweapon detected", "low power".
- **Steps:** looping filtered brown-noise wind at gain 0.015 during play only; battle-intensity sublayer driven by an explosion counter decaying over 5s (max +0.03 gain); `speechSynthesis.speak` wrapper with a 3s per-line cooldown, only if flag on.
- **Acceptance:** wind audibly present but unobtrusive (start a match, don't fight — it's there; mute kills it); a big battle raises the bed noticeably; announcer OFF by default, and when toggled on speaks "base under attack" on the alarm event without overlapping itself.
- **Dependencies:** WS-3.1, WS-3.3 (shares rising-edge detectors).

---

## PHASE 4 — Animation & Visual Polish (SPEC §6)

### WS-4.1 [CODE] Infantry gait under sprites
- **Objective:** moving infantry visibly walk (legs animate under the static sprite torso).
- **Files/functions:** `drawUnit` — the existing vector leg-cycle block (~lines 1676–1698) refactored into `drawLegs(c,u,scale)` and called in BOTH the vector fallback and the sprite branch (before `drawImage`, rotated to `u.face`, scale `spr.size/30`).
- **Steps:** extract, parameterize, call under sprites for `cls==='inf'` only; verify legs are hidden by the torso when standing (draw only when `u.moving` plus the existing idle stance), tune leg color to a dark neutral (#26261e) rather than faction dark so it works under any sprite.
- **Acceptance:** a moving Ranger/Rebel/Red Guard shows an alternating leg cycle under the sprite in all 8 facings with no legs poking through the torso top; idle infantry look unchanged; zero fps impact at 100 infantry (legs are 4 strokes).
- **Dependencies:** none.

### WS-4.2 [CODE] [sonnet-ok] Vehicle/jet/building micro-anims
- **Objective:** SPEC §6 remainder: muzzle flash at sprite barrel tip, jet contrails, production-building working glow.
- **Files/functions:** `fire()` (muzzle offset `spr? spr.size*0.45 : (src.r||10)`), `updateUnit` (contrail particles for `cls==='jet'` while moving, budgeted ≤2/frame per jet), `drawBuilding` (1px oscillating glow border while `b.queue.length>0`).
- **Acceptance:** Raptor leaves a fading twin contrail; a firing Paladin's flash appears at the barrel tip not the hull center (visual check in 4 facings); a producing War Factory glows subtly, an idle one doesn't; fps at 200 units unchanged (±2).
- **Dependencies:** none.

---

## PHASE 5 — Sprite Completion & QC  ⚠ ASSET-GEN track (vision review REQUIRED)

### WS-5.1 [ASSET-GEN] Missing + fallback art: bld_tunnel set
- **Objective:** create `bld_tunnel_0..2.png` (GLA Tunnel Network — currently an emoji fallback).
- **Steps:** generate per SPEC §4 regenerate-loop (desert tunnel entrance: sandbagged hole, wood/canvas frame, GLA-khaki-neutral); 3 damage states per rubric check 8; drop into `assets\`; verify in `?gallery=1` and in-game (build one).
- **Acceptance:** rubric §4 all-8 PASS from a vision review of the gallery screenshot; in-game GLA tunnel shows sprite not emoji; `deploy.ps1` filter picks the files up (names end `_0.._2`).
- **Dependencies:** WS-0.2 (gallery).

### WS-5.2 [ASSET-GEN] Full-roster QC sweep + regeneration
- **Objective:** every unit (42 sets × 8) and building (18 × 3) passes the SPEC §4 rubric; regenerate failures.
- **Steps:** (1) Screenshot every `?gallery` page. (2) Vision review each set against the 8 checks — output one line per set: `PASS` or `FAIL: check#, note`. (3) For each FAIL run the SPEC §4 regenerate loop (4 candidates, background strip, facing derivation, max 3 rounds). (4) Re-verify in gallery. Track in a simple `assets\QC_LOG.md` checklist (this is a working artifact, not a report).
- **Acceptance:** QC_LOG.md shows all 60 sets PASS, or a residual FAIL list ≤5 sets explicitly flagged for Blaine with candidate images staged in `assets\_candidates\`.
- **Dependencies:** WS-0.2. **Note for the orchestrator:** this WS needs a vision-capable reviewer (Opus with image input reviewing gallery screenshots) — do not hand it to a text-only pass, and treat "looks fine to me" without the per-check output as a failed review.

### WS-5.3 [ASSET-GEN] [conditional — Path B only] Trade-dress spot check
- **Objective:** per SPEC §7: regenerate any sprite that is unmistakably an EA-designed fictional unit (primary suspect: the double-barreled Overlord silhouette).
- **Acceptance:** Overlord (→"Colossus") reads as a super-heavy tank but NOT a twin-barrel Overlord copy; vision reviewer confirms; other flagged sets (if any) addressed.
- **Dependencies:** WS-5.2, WS-7.1 (do together with the re-skin).

### WS-5.4 [CODE] [sonnet-ok] Asset housekeeping
- **Objective:** stop shipping/keeping cruft; keep the repo lean.
- **Steps:** move non-runtime files out of `assets\` into `assets\_source\` (the `*_sheet.png` files, `supply_truck.png`, `crusader-tank*.png`, `406ca9d8*.png`, `wj.png` etc. — anything not matching `<registeredKey>_[0-7].png` / `bld_<key>_[0-2].png`); confirm root-level gifs/zips aren't referenced; update README repo-layout table.
- **Acceptance:** game runs with zero 404s after the move; `assets\` contains exactly 42×8 + 18×3 runtime files (or documented exceptions); deploy copies only runtime frames (already filtered, verify).
- **Dependencies:** WS-5.1 (so the count includes tunnel).

---

## PHASE 6 — Game Feel, UX, Performance

### WS-6.1 [CODE] Pause menu & settings
- **Objective:** a real pause overlay: Resume / Restart / Quit-to-menu, volume slider, announcer toggle, help.
- **Files/functions:** new overlay div (copy `.ov` pattern); `P`/pause button routes here; `startGame` refactor so Quit-to-menu returns to `startScreen` cleanly WITHOUT `location.reload()` (reset G arrays, cancel placement/drag state; note `btnRestart` currently reloads — keep reload as the fallback if state reset proves flaky, but try clean reset first).
- **Acceptance:** pause → menu shows, game frozen behind it; Resume continues exactly; Restart starts a fresh match same settings; Quit returns to faction select and a new different-faction match works with no leaked units/buildings/fog from the previous match; volume/announcer settings live here and persist.
- **Dependencies:** WS-3.1 (settings object).

### WS-6.2 [CODE] Save / load (single snapshot)
- **Objective:** one localStorage save slot: Save from pause menu, Continue from the start screen.
- **Files/functions:** new `serialize()/deserialize()`; the tricky bits: entity cross-references (`order.tg`, `tmpTg`, `node`, `depot`, `cargo[]`, `garrison[]`, `G.sel`, `groups`) must be saved as ids and re-linked; defs saved as `{facKey, k}` refs, never inline; map = seed? No — map is random: save `terr`, `blockGrid` (base64 of the Uint8Arrays), decor, supplies, fogExp; rebuild `terrCanvas` via `renderTerrain` on load (roads array must be saved too after WS-2.1).
- **Steps:** write serializer; version-stamp the blob (`v:1`); "Continue" button on startScreen when a save exists; autosave every 60s during play (cheap: <5MB limit is fine — 128² arrays ≈ 16KB each raw).
- **Acceptance:** save mid-battle with units in transports, garrisons, an attack order, a charging superweapon, and a half-built building → reload page → Continue → all of it intact (spot-check each listed case); saving+loading twice is stable; corrupt/old-version blob → Continue hidden, no crash.
- **Dependencies:** WS-6.1 (menu hosts the button), after Phase 1–2 land (schema covers their fields: `horde`, `lastCombatT`, roads, water).

### WS-6.3 [CODE] [sonnet-ok] Production & control QoL
- **Objective:** close the small ZH-feel gaps in the sidebar/HUD.
- **Steps:** (1) per-building queue display: selecting a production building shows its queue with per-item cancel (right-click already cancels last globally — add click-to-cancel on the queue icons in selInfo). (2) Double-click a unit in the world = select all of that type on screen (desktop parity with the existing mobile double-tap). (3) Idle-worker/harvester button in the topbar (cycles idle harvesters+builders; shows count). (4) Low-power icon over affected defenses exists — also gray out production buttons' progress bar when low power. (5) `H` toggles help (exists) — add `F` = jump camera to last ping (attack alert follow-up).
- **Acceptance:** each of the 5 items demonstrated working in one session; no regressions to existing hotkeys (A/S/P/M/Esc/1-9 all still work).
- **Dependencies:** none.

### WS-6.4 [CODE] Performance guard
- **Objective:** hold ≥55 fps with 300 units on a mid laptop; the known hot spot is O(n²) `separation()`.
- **Files/functions:** `separation` (spatial hash grid, cell = 2×max radius ≈ 40px, rebuilt per call), particle cap (`G.parts` hard cap ~600, drop oldest cosmetic first), `acquire` (early-out via the same grid if profiling justifies), fps meter in debug panel.
- **Steps:** add debug fps/unit-count readout; profile with 300 debug-spawned units fighting; implement grid for separation (and horde counting from WS-1.2 if it shows up); cap particles.
- **Acceptance:** 300 mixed units in active combat: ≥55 fps on the dev machine (record before/after numbers in the debug panel screenshot); zero behavior change at low counts (duels from WS-1.4 spot-checked unchanged).
- **Dependencies:** WS-1.2 (shares grid if needed).

### WS-6.5 [CODE] [sonnet-ok] Victory/defeat flow + match stats
- **Objective:** better end screen: existing stats + match timeline (money graph optional), faction played/against, difficulty, biome/map size, "Play again" (same settings) AND "Change setup".
- **Acceptance:** end screen shows the added fields; Play Again restarts immediately with identical settings (no reload); Change Setup returns to menu.
- **Dependencies:** WS-6.1 (clean reset machinery).

---

## PHASE 7 — Re-skin to Original IP  ⚠ REQUIRED for monetization (Path B); SKIP for personal build (Path A)

### WS-7.1 [CODE] Mechanical rename per RESKIN_MAP.md
- **Objective:** zero EA/real-world trademarks anywhere player-visible; gameplay byte-identical.
- **Files/functions:** `generals-zero-hour.html` display strings ONLY — `FACTIONS` `name/desc/tag`, every unit/building `n`, `<title>`, startScreen h1 + `.sub`, helpBox, endScreen, `tooltipFor` free text; README.md; `deploy.ps1` message strings. **Do NOT rename internal keys (`k:`, sprite filenames, `FACTIONS.USA` object keys)** — keys are invisible to players and renaming them risks breaking sprite paths and save files for zero legal value. (Path-B-purist option to rename keys+files is listed in RESKIN_MAP §5 as a follow-up, explicitly optional.)
- **Steps:** apply every row of RESKIN_MAP.md tables 1–4; grep the file afterward for the banned-terms list (RESKIN_MAP §6) — zero hits allowed outside code comments; update README title/features; retitle the hosted page.
- **Acceptance:** the banned-term grep over the HTML's user-visible strings returns 0; a full playthrough of each faction shows no old names in cards/sidebar/tooltips/selInfo/banners/end screen; game behavior unchanged (WS-1.4 duel #1 re-run gives the same result).
- **Dependencies:** RESKIN_MAP.md (done), ideally after Phase 1 (so new card text is written once in the new IP).

### WS-7.2 [CODE] [sonnet-ok] Rebrand shell
- **Objective:** IRON SUNSET identity: new title screen treatment (title, palette accent, `SunsetSarge presents`), favicon + app icons (generate a simple emblem — can be code-drawn SVG→PNG), remove "tribute" phrasing everywhere, LICENSE/README rewrite, new Firebase site name decision (`iron-sunset.web.app`) + deploy.ps1/firebase.json update **behind Blaine's confirmation** (URL change breaks existing links).
- **Acceptance:** loading the game shows no EA-referencing text from first paint to end screen; icon set exists (192/512 PNG); README describes an original game; deploy targets whichever site Blaine confirmed.
- **Dependencies:** WS-7.1.

---

## PHASE 8 — Package & Ship (SPEC §7 packaging table)

### WS-8.1 [CODE] PWA
- **Objective:** installable, offline-capable web app — the highest-value packaging step.
- **Steps:** `manifest.webmanifest` (name, icons from WS-7.2, display standalone, orientation landscape), tiny service worker (cache-first for `/`, `/assets/*`; version-keyed cache busted by deploy), iOS meta tags exist already; wire into `public/` via deploy.ps1 (it currently copies ONLY index.html + frames — extend to copy manifest+sw+icons).
- **Acceptance:** Lighthouse PWA audit passes installability; airplane-mode reload works after first visit; Add-to-Home-Screen on an Android phone launches fullscreen landscape.
- **Dependencies:** WS-7.2 icons (Path B) or temp icons (Path A).

### WS-8.2 [CODE+HUMAN] Google Play via TWA
- **Objective:** Play Store listing of the PWA (Bubblewrap/TWA — far less code than Capacitor for an already-working PWA).
- **Steps (agent):** Bubblewrap project, assetlinks.json on the hosting origin, signed AAB build docs, store-listing copy + screenshots (from gameplay), content-rating questionnaire answers drafted honestly (fantasy war violence; note the Fanatic rename matters here). **Steps (Blaine, cannot be delegated):** Play Console account ($25), keystore custody, final submit.
- **Acceptance:** an AAB that installs and runs on a physical Android device; a checklist doc of the exact human steps remaining, with nothing hand-waved.
- **Dependencies:** WS-8.1, WS-7.x complete (do NOT submit EA-marked builds), Blaine's go decision on pricing ($2.99 one-time per SPEC §7 recommendation).

### WS-8.3 — iOS: **deliberately deferred.** Per SPEC §7: PWA installs on iOS Safari today; App Store wrapper needs a Mac, $99/yr, and carries real 4.2-rejection risk. Revisit only if Play/web traction justifies it. (Listed so nobody "helpfully" starts it.)

---

## Parity Backlog (post-ship — NOT promised in this plan)
Copied from SPEC §8 so executors don't scope-creep: Generals' Powers tree, garrisonable civilian buildings, capturable tech buildings, naval, multiplayer, campaign/missions, composed music, sampled voice packs, map editor, replays. Anyone tempted to add these inside a workstream above: don't — file it here.

## Workstream census
- CODE: 20 (0.1–0.3, 1.1–1.4, 2.1–2.3, 3.1–3.4, 4.1–4.2, 6.1–6.5, 7.1–7.2, 8.1) — of which 9 are [sonnet-ok]
- ASSET-GEN (vision review required): 3 (5.1, 5.2, 5.3) + housekeeping 5.4 [CODE]
- CODE+HUMAN: 1 (8.2)

## Biggest risks (ranked, honest)
1. **Sprite QC bottleneck (WS-5.2):** 60 sets × 8-point rubric needs real vision review; regeneration loops can eat days and some sets may never beat the rubric with current gen tooling. Mitigation: fallback vector art is already decent — ship with residual FAILs flagged rather than blocking.
2. **Save/load (WS-6.2):** entity-reference re-linking is the classic bug farm. Mitigation: acceptance list names the exact hairy cases; keep it one slot, version-stamped, and allowed to fail closed.
3. **"As good as Zero Hour" expectation:** this plan ships a polished single-file skirmish RTS with faction identity — it will NOT match ZH's content breadth (powers, campaign, 9 sub-generals). That gap is the Parity Backlog by design, not a surprise at the end.
