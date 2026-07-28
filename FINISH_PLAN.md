# FINISH_PLAN.md — Iron Sunset: v2 Finishing Plan (post-playtest)

Authored 2026-07-07 by the Fable 5 architect after Blaine's first real playtest and a
full evidence-based diagnosis (screenshots, in-engine sim tests, per-frame sprite
audits). This plan supersedes the completed PLAN.md phases. **SPEC.md remains the
design source of truth for numbers; RESKIN_MAP.md governs naming.**

## How to execute this plan (read first, every session)
- One workstream (WS) per implementation agent/session. Tags: `[sonnet-ok]` = a mid-tier
  model can do it; untagged = use Opus-tier. ASSET-GEN workstreams need ComfyUI +
  a vision-capable reviewer at the end.
- The game is ONE file: `generals-zero-hour.html` (~3400 lines). Keep it single-file,
  no external deps. Sprites live in `assets\<key>_0..7.png` (units) and
  `assets\bld_<key>_0..2.png` (buildings). NEVER rename internal keys or sprite paths.
- Line numbers below are anchors from 2026-07-07; they WILL drift — re-locate by grep.
- After each WS: run the Verification Protocol (§V), then `deploy.ps1` (add `-Force`
  if only assets changed). Commit messages describe the WS.
- Python for all scripts: `C:/ComfyUI/.venv/Scripts/python.exe`. Sprite pipeline
  scripts live in `C:\Claude\sarges-skills\skills\browser-game-builder\scripts\`.

---

## §0 Current state (evidence-based, 2026-07-07)

**Working and verified live** (browser-generals.web.app): asymmetric factions
(FACTION_MODS; horde/salvage/vet mechanics all numerically verified), procedural
terrain with 750/750 reachability guarantee, 26-kind Web Audio synth engine,
pause menu + save/load (schema v1, zero dangling refs), spatial-hash perf
(~2ms/tick @300 units), installable offline PWA (395-entry SW cache), IRON SUNSET
re-skin (0 trademark hits in visible strings). Harnesses: `?gallery=N`, `?test=map`.

**Engine facing logic: CORRECT** (verified by live sim: move E→frame 0, N→6, W→4,
S→2, SE→1, movement deltas match). All facing bugs below are ART-side.

## §1 Confirmed defects (each verified with rendered evidence)

| # | Defect | Root cause (verified) |
|---|---|---|
| D1 | Infantry sizes wildly inconsistent | P5 batch frames were bbox-trimmed but never scale-normalized: ranger_0 content = 129px, jarmen_0 = 44px. Engine draws every frame at `h = spr.size` → kneeling/cropped poses render zoomed-in huge, full-body poses tiny. |
| D2 | Double legs: stick legs swing while sprite legs stay frozen | `drawLegs()` overlay (grep `drawLegs`, called in the sprite branch of `drawUnit` when `cls==='inf'&&u.moving`) was designed for legless blob sprites; P5 sprites have baked-in legs → both render. |
| D3 | Units face backward/wrong while moving | Diagonal frames (1,3,5,7) have PER-UNIT facing drift: ranger's SE aims down-left (mirrored), rebel's SW duplicates its SE, hunter's diagonals scrambled. Cause: 8 img2img cells redraw independently at denoise 0.40; cardinals held, ambiguous diagonals flipped. **A whole-set remap cannot fix per-frame drift.** In-game paths are mostly diagonal → constant visibility. |
| D4 | Helis show static baked blades PLUS spinning code blades | comanche/chinook frames all contain baked rotor blur; code rotor overlay (grep `G.time*26`) draws on top. |
| D5 | Chinook flips upside-down when turning | chinook set frames are not consistent 45° rotations of one aircraft (audit montage shows mixed orientations/poses). |
| D6 | (Audit needed) vehicle diagonals unverified | Vehicles were fixed by whole-set mirror remaps (a consistent transform), so they are probably fine — but nobody has eyeballed their frames 1/3/5/7. |

## §2 The fix architecture — canonical frame + programmatic rotation

**Key insight:** the regenerated infantry (and any heli body) are TRUE overhead
(top-down ~90°) sprites. Truly-overhead art CAN be rotated in code — the
"never rotate sprites" rule only applies to 3/4-view art with baked horizon
perspective (the tanks). Therefore:

> For every true-overhead unit (all 12 infantry + comanche + chinook), keep exactly
> ONE canonical EAST-facing frame per unit (per animation pose) and DERIVE the other
> 7 directions by rotating it programmatically. Facing and size become correct **by
> construction** — D1, D3, D5 cannot recur. Vehicles/jets (3/4 view) keep their
> existing 8-frame sets.

### WS-A1 `[sonnet-ok]` — `make_dirs.py` rotation-derivation tool
**Objective:** one script that turns `staging/<key>_east.png` into normalized
`assets/<key>_0..7.png`.
**Location:** add to `C:\Claude\sarges-skills\skills\browser-game-builder\scripts\`
(it's a reusable pipeline tool) and use from the project.
**Spec:**
1. Input: an East-facing RGBA frame (transparent bg). Args: `key`, `--height H`
   (target content height px), `--out assets`, optional `--pose N` suffix support.
2. Trim to alpha bbox → uniform-scale so content height == `H` → paste centered on a
   square canvas of `ceil(H*1.5)` (rotation headroom).
3. For i in 0..7: rotate by `-45*i` degrees (PIL `rotate(angle, resample=BICUBIC,
   expand=False)`; NEGATIVE because canvas y-down means clockwise compass = negative
   PIL angle — VERIFY empirically with frame 2 pointing down) and save `<key>_i.png`.
4. Print a facing self-check: for frames 0/2/4/6, compute the content
   center-of-mass offset from canvas center; frame 0's mass should lean the same
   way frame 2's leans after +90° rotation (sanity, not proof — the montage in §V
   is the proof).
**Target-height table (content px, engine sizes stay as registered):**
inf standing (ranger, missile, burton, redguard, hunter, rebel, rpg, terrorist,
jarmen, worker) = 120; crouched (sniper, lotus) = 100; comanche body = 150;
chinook body = 170.
**Acceptance:** running on a test frame produces 8 files; `verify_facing.py <key>`
montage shows smooth 45° clockwise rotation with frame 0 East; all 12 infantry
render within ±10% of each other's on-screen height in the §V size-lint.
NOTE: per-frame size consistency must be checked by OPAQUE-PIXEL AREA (±5%), not
bbox height — AABB height is not rotation-invariant for non-square content.
**✅ DONE 2026-07-07.** Tool at `sarges-skills/skills/browser-game-builder/scripts/make_dirs.py`.
Rotation sign −45°/step proven empirically (arrow test: frame 2 down, frame 6 up).
Tested on ranger+worker @height 120: area variance 0.0%/0.3%, vision-verified montages
show correct clockwise sweep incl. diagonals. Ready for WS-A2/A3 consumption.

### WS-A2 [ASSET-GEN] — regenerate 12 infantry as single canonical frames
**Objective:** one clean East-facing overhead frame per infantry unit; then WS-A1
derives directions.
**Recipe (LOCKED, from the proven P5 re-pilot):** ComfyUI, checkpoint
`dreamshaperXL_v21TurboDPMSDE.safetensors`, `dpmpp_sde`/`karras`, 14 steps, cfg 3.0.
img2img off the unit's CURRENT `assets/<key>_0.png` (it already faces East and is
overhead) upscaled to 768px, **denoise 0.35–0.42**. Background strip: BiRefNet-general
(`remove_background` node; stage input into `C:\ComfyUI\input\` first).
**Prompt template:** `top-down overhead view, single <UNIT DESC> seen from directly
above, facing right, standing neutral pose, legs together, helmet/head and shoulders
and <WEAPON> visible from above, desaturated <FACTION> military palette, clean game
sprite, plain background` — negatives: `side view, eye-level, face visible, multiple
figures, grid, low angle, blurry, text, watermark`.
**Unit descriptions:** reuse the P5 batch list (missile=SAM tube, sniper=long scoped
rifle CROUCHED, burton=rifle commando, redguard=red-accent rifle, hunter=RPG tube,
lotus=slim dark operative — give her a visible SMG for silhouette, rebel=tan militia
rifle, rpg=shoulder launcher, terrorist=bulky vest satchel, jarmen=long rifle +
headscarf, worker=hardhat + shovel, ranger=rifle).
**Weapon must read at 30px and point RIGHT in the frame.**
**Output to `assets\_regen2\<key>_east.png`** (staging; gitignored pattern exists for
`assets/_regen/` — add `_regen2/`). Run WS-A1 per unit into `assets\_regen2\derived\`
first; only copy into live `assets\` after §V passes.
**Optional A2b (walk cycle, do AFTER base works):** second frame per unit
(`legs mid-stride scissored`, img2img off the accepted east frame, denoise 0.30) →
`make_dirs.py --pose 1` → engine WS-A4b swaps poses at ~7Hz while moving. 2-frame
walks read shockingly well at 30px.
**Acceptance:** §V gallery + size-lint + diagonal montage all pass; a vision reviewer
confirms every unit reads as its type AND every frame's weapon points at its compass
label. Max 3 re-rolls per unit, then fall back to keeping that unit's current
cardinal frames with rotation-derived diagonals (WS-A1 applied to its existing _0).
**✅ DONE 2026-07-08 (commit 063e1f5, live).** All 12 gen-new (ranger via sibling
method — old _0 was 3/4-view); vision-reviewed 12×8 montage incl. diagonals; sizes
uniform by construction; registration 30→45 (120px content in 180px canvas ≈ 30px
on-screen); SW cache →v2. Accepted-weak: terrorist (no directional weapon — inherent),
lotus (faint SMG), missile (bg wisp). A2b walk-pose NOT done (optional, later).

### WS-A3 [ASSET-GEN] — heli bodies without blades (fixes D4 + D5)
**Objective:** comanche + chinook single East frames, overhead, **rotor blades
absent** (hub/mast only); WS-A1 derives 8 directions; the existing code rotor
overlay becomes the ONLY blades.
**Prompt add-ons:** `rotor blades removed, rotor hub only` / negative `spinning
blades, rotor disc, motion blur`. Chinook = twin-rotor: draw TWO hubs (front+rear);
engine change in WS-A4 draws two overlay rotors for chinook at ±0.28×size along
facing (grep the rotor overlay; add a per-key config `{chinook:{rotors:[-0.28,0.28]},
default:{rotors:[0]}}`).
**Acceptance:** in the §V gallery, heli frames show NO baked blades; in a live spin
test (spawn heli, order moves in a circle) the body rotates smoothly with no
upside-down frame and exactly one set of spinning blades per hub.
**✅ DONE 2026-07-08.** Two generation rounds: round 1 (init-img2img den 0.42) rejected
by orchestrator vision review (flat mock-ups); round 2 with anatomy-rich inits + denoise
sweep passed at den 0.50 (0.58+ regrows blades — SDXL prior). Deterministic post-fixes
(comanche hub composite, chinook tail-artifact erase) in scratchpad postfix_a3.py.
Engine: per-hub rotor overlay (chinook twin ±0.26×size, desynced; comanche single);
registrations 46→69 (centered-content geometry). Verified in-engine: rotors track hubs
across facings, no baked blades, zero console errors. LESSON: txt2img cannot make a
blade-free helicopter (model prior); always init-control composition.

### WS-A4 `[sonnet-ok]` — engine animation fixes (do with/after A2/A3)
1. **Remove the stick-leg overlay for sprite infantry:** in `drawUnit`'s sprite
   branch, delete the `if(cls==='inf'&&u.moving) drawLegs(...)` call (keep
   `drawLegs` itself — the vector-fallback branch still uses it).
2. **Gait for baked-leg sprites:** while `u.moving`, draw the sprite in two slices —
   upper 55% static, lower 45% sheared with `c.transform(1,0,shear,1,0,0)` where
   `shear = sin(G.time*10 + u.id*2.1) * 0.22`, both slices rotated into facing space
   (translate→rotate(u.face)→draw slices→restore). At 30px this reads as stepping.
   If A2b (2-pose walk) ships, replace the shear with pose-swap at 7Hz instead.
3. **Chinook twin rotor overlay** per WS-A3. Verify comanche keeps a single rotor.
4. Muzzle-flash offset, recoil, dust: unchanged (already correct).
**Acceptance:** moving infantry show exactly ONE set of legs, visibly stepping;
idle infantry are static; §V in-game sim frames still map E→0/N→6/W→4/S→2.
**✅ DONE 2026-07-08.** SPEC CORRECTION: the two-slice waist shear (item 2) was written
for 3/4-view sprites and is WRONG for true-overhead art (the image's lower half isn't
"legs"). Implemented the overhead-honest gait instead: lateral sway ±1.1px
perpendicular to travel + body wobble ±0.055rad at 2× step frequency, moving only.
Stick-leg overlay removed from the sprite branch (kept for vector fallback). Chinook
twin rotor landed in WS-A3. Verified: moving renders vary per phase, idle pixel-stable,
no double-leg pixel signature, zero console errors.
DEPLOY NOTE (feeds WS-B7): sw.js is cache-first INCLUDING index.html — every deploy
that changes html/assets MUST bump the sw.js cache version or returning players stay
stale. Manual bumps v2(A2) v3(A3) v4(A4) so far; automate in B7.

### WS-A5 `[sonnet-ok]` — automated art lints (regression-proofing)
Add `scripts/sprite_lint.py` to the project:
1. **Size lint:** for every registered infantry key, compute drawn on-screen height
   (`spr.size` × contentH/frameH from the PNG). FAIL if any two infantry differ >15%.
2. **Set-consistency lint:** per unit, all 8 frames' content bbox areas within ±20%
   of each other (catches a drifted/duplicated frame).
3. **Facing spot-montage:** auto-build the 1/3/5/7 diagonal montage for every unit →
   one image for a vision reviewer (this is what caught D3 — cardinals alone are NOT
   sufficient, always review diagonals).
**Acceptance:** lint runs clean on the new sets; wire a note into README dev section.

### WS-A6 `[sonnet-ok]` — vehicle/jet diagonal audit (D6)
Run the WS-A5 diagonal montage over all 3/4-view sets (humvee, crusader, paladin,
avenger, tomahawk, dragon, gattling, battlemaster, overlord, inferno, nukecannon,
technical, quad, scorpion, marauder, buggy, toxin, scud, cycle, bombtruck, truck,
battlebus, bulldozer, dozer, raptor, aurora, mig). Whole-set transforms (their fix
history) preserve internal consistency, so expect PASS — but verify. Any unit whose
diagonals are mirrored as a SET: fix with the standard remap (`--mirror` =
new[i]=old[(4-i)%8], `--flip` = new[i]=old[(i+4)%8], both self-inverse). Any unit
with PER-FRAME drift: schedule regeneration like WS-A2 (but 3/4 view vehicles cannot
use rotation-derivation — regenerate the bad frames via img2img off a good
neighboring frame).

### WS-A7 `[sonnet-ok]` — sprite payload quantization (measured 2026-07-07)
Deployed sprite payload is **15MB / 444 files** — all precached by the service worker on
first visit. PIL quantization test: `im.quantize(colors=128, method=FASTOCTREE)` +
`optimize=True` shrinks bld_tunnel_2 316→59KB, bld_palace_0 233→50KB, ranger_0 21→4KB
(**~80%**). Write `scripts/quantize_assets.py`: batch all `assets/*_[0-7].png` +
`bld_*_[0-2].png` → `assets/_quant/`, build a before/after A/B montage of the 6 biggest
for VISION review (banding on gradients is the risk — bump to 192 colors per-file if a
sprite visibly bands), then replace originals (git is the backup), bump SW cache version.
**Acceptance:** total deployed payload ≤4MB; A/B montage shows no visible degradation at
game scale; game loads clean; live site serves the small files.

### WS-A8 `[sonnet-ok]` — world-render polish (from 2026-07-07 screenshots)
1. **Roads look like shadow rays:** carved-corridor roads render as straight dark
   streaks radiating from the HQ (screenshot evidence). Fix in `renderTerrain`'s road
   stamping: draw along the actual corridor polyline (not base-to-base straight lines),
   clip road alpha under building footprints, and cap width ~14px with soft edges.
2. **Blocky fog edges:** fog canvas is tile-resolution scaled up hard. Render fogCanvas
   at tile res but draw it scaled with a 1-tile blur (`ctx.filter='blur(6px)'` on the
   composite, or draw fog to a half-res canvas and let smoothing blur it).
**Acceptance:** re-capture the §V in-game screenshot: roads read as roads (follow
corridors, no HQ starburst), fog boundary is soft; fps unchanged.

---

## §3 Completion workstreams (after Track A, toward "done game")

### WS-B1 `[sonnet-ok]` — music + audio polish
Procedural music keeps single-file: either (a) hand-rolled Web Audio 2-oscillator
pad + bass loop with intensity tied to `ambBattle` level, or (b) embed ZzFXM
(**already downloaded to `vendor/zzfx.js` + `vendor/zzfxm.js`, MIT** — paste inline
with attribution comment) + 2 short tracked loops (menu, battle). Add: per-faction ack pitch already exists; add volume ducking
(alarms duck ambient by 50% for 2s). Acceptance: menu + gameplay music loops,
mute/volume still master everything, file grows <40KB.

### WS-B2 — Generals' Powers (the big missing ZH feature)
3 powers per faction, charged by a global timer + kills (like superweapons but
army-scale). Add `POWERS` table + UI row above the minimap + targeting cursor +
AI usage (fire at largest enemy blob on cooldown). Per SPEC faction identity:
- Coalition: Precision Strike (missile volley at target, 250 dmg aoe 90),
  Field Surgeons (all units heal 30% over 10s), Paradrop (3 Troopers + 2 Lancers
  at target).
- Pact: Artillery Barrage (12 shells over 4s in aoe 140), People's Rally (horde
  bonus everywhere for 20s), Minefield (drop 8 mines at target).
- Syndicate: Ambush (spawn 4 Raiders + 2 RPG at target), Scrap Bounty (2× salvage
  for 25s), Tunnel Strike (teleport up to 6 selected units to any explored point).
Charge: first at 4min, +25% per subsequent. Acceptance: all 9 castable, AI casts,
icons+cooldown rings render, save/load persists charge state.

### WS-B3 `[sonnet-ok]` — mobile touch pass
Playtest-driven: bigger touch targets (min 44px), two-finger pan + pinch zoom
verification, long-press = attack-move, drag-select handle size, sidebar collapse,
`orientation: landscape` lock message for portrait. Acceptance: playable start-to-win
on a 390×844 viewport with only touch (use preview_resize mobile).

### WS-B4 `[sonnet-ok]` — AI personalities + difficulty polish
Easy/Normal/Hard exist; add per-faction AI flavor: Coalition AI techs faster + uses
air; Pact AI masses 2× wave sizes; Syndicate AI raids harvesters + rebuilds cheap.
Implement as a small `AI_STYLE` table consumed by the existing wave logic.
Acceptance: 3 test games (one per enemy faction) show visibly different pressure.

### WS-B5 `[sonnet-ok]` — match flow & meta
End-screen upgrade: stats table (units built/lost, damage, salvage, match time,
score), Play Again with same settings, difficulty/faction stats persisted to
localStorage (career W/L per faction). A 6-step first-game hint overlay
(build power → barracks → train → harvest → expand → destroy HQ), dismissable,
shown once (localStorage flag). Acceptance: hints show on fresh profile only;
end screen numbers match G.stats.

### WS-B6 — balance sim harness + tuning pass
Headless auto-battle: `?test=balance` pits scripted armies (the 6 SPEC §2 duels +
3 full AI-vs-AI matches per matchup) using seeded RNG and logs winner + surviving
value to console. Tune via FACTION_MODS/costs only (SPEC knob order). Acceptance:
each faction wins ≥40% of its favored matchup sims; results appended to README
Balance log.

### WS-B7 `[sonnet-ok]` — performance & robustness gate
300-unit fight ≥55fps (re-verify after A4 slicing changes — two-slice draw is 2×
drawImage calls for moving infantry); SW cache version bump on deploy (automate:
deploy.ps1 rewrites `browser-generals-v1` → content hash); error telemetry hook
(window.onerror → console + optional localStorage ring buffer for bug reports).

---

## §V Verification Protocol (run after every WS above)
1. `?gallery=1..N` — every changed sprite reads correctly, labeled, no fallbacks
   unexpectedly appearing. (Real browser or via the offscreen-render eval.)
2. **Diagonal montage** (WS-A5 script) for changed units — a VISION review, frames
   1/3/5/7 weapon/nose direction must match labels. Cardinals alone are not enough.
3. **In-game sim facing test** (paste into console / preview eval):
   `startGame('USA','normal','small','bl');` then for a player combat unit `u`:
   `setMove(u,u.x+300,u.y); u.order={t:'move'};` tick `update(1/60)`×45 → assert
   `dirIndex(u.face,8)===0`; repeat for N/W/S/SE expecting 6/4/2/1.
4. `?test=map` still prints 750/750 PASS.
5. Save/load round-trip (serialize→wipe→deserialize→compare unit/bld counts, money).
6. Zero console errors across: normal load, one started match per faction, gallery,
   map test.
7. Deploy (`deploy.ps1`, `-Force` for asset-only), then curl the live site for the
   changed asset (200) and load once.

## Definition of Done (v1.0 shippable)
- All Track A defects fixed and §V green.
- WS-B1..B7 complete.
- 3 full playthroughs (one per faction, Normal) by a human with zero visual anomalies
  and a win each.
- PWA install + offline verified on a real phone.
- Name decision made (see ROADMAP §Naming) and store-prep items ticked.

---

## §4 TRACK C — Source-Look Art Upgrade (added 2026-07-09 from the four-lane audit)
Read `ART_DIRECTION.md` FIRST — it is the binding style bible (locked ~40° camera,
palettes, prompt scaffold, IP guardrails, tooling map). Audit evidence in
`AUDIT_2026-07-09.md`. ⚠ ComfyUI Desktop (:8000) must be running for ASSET-GEN WS.
Order within Track C = the order below (Tier 1 → Tier 2).

### WS-C1 `[sonnet-ok]` — asset hygiene sweep (zero regeneration risk)
Erase contamination blobs on inferno_0/nukecannon_0/overlord_0/battlemaster_0
(sheet-slice bleed at frame tops); hard-key bulldozer's semi-transparent white box
(64% semi-alpha) to true alpha; delete the redundant dozer-vs-bulldozer duplicate
(keep one key, alias the other in UNIT_SPRITE_REG); desaturate MiG ~15%; fix the
size-hierarchy inversion in the registration table (dozer/bulldozer must be ≈ MBT
size, not 1.6×); investigate + fix the "boxed green circle" object seen in
screenshots (suspected decor tree drawn with a blocked-tile rim outline).
**Acceptance:** re-render §V scene screenshots — no ghost boxes, no stray
fragments, dozer ≤ tank on screen, mystery object resolved.
**✅ DONE 2026-07-09.** 14 contaminated frames fixed via connected-component alpha
analysis (cardinals of inferno/nukecannon/battlemaster + overlord 2/6); bulldozer
ghost box hard-keyed; dozer files replaced by bulldozer art (defs untouched);
MiG desaturated 15%; dozer sizes 62→40; mystery box = cliff rim drawn on isolated
single terr tiles — fixed with 8-dir neighbor check (MAPTEST still 750/750).
Orchestrator spot-checked live assets on tan: PASS.

### WS-C2 [ASSET-GEN] — GLA vehicle roster at hero fidelity (9 units)
technical, quad, scorpion, marauder, buggy, toxin, scud, cycle, bombtruck are ALL
64×64 top-down pixel minis from an early batch — a different game visually.
Regenerate at ~140px painted fidelity matching the USA/China vehicles, Syndicate
palette (khaki/rust/scrap/tarps), via the locked prompt scaffold + ControlNet
silhouette lock (derive canny from existing minis to keep readable shapes) or
init-controlled img2img (the WS-A3 proven method). 8 facings per unit: until the
Tier-2 3D-proxy pilot lands, generate East + use per-facing img2img off the
matching crusader-facing for elevation reference; verify every facing per §V.
**Acceptance:** gallery + in-scene screenshot shows GLA units at same scale/style
family as USA/China; facing montage passes; no EA trade-dress look-alikes.

### WS-C3 [ASSET-GEN] — helicopter fidelity repaint (2 units)
comanche (24.9% opaque wisp) and chinook (flat box) get repainted at raptor/mig
fidelity: keep the blade-free-body + code-rotor architecture (WS-A3), same
overhead camera FOR NOW (Tier 2 re-shoots at 40° later), but with painted panel
lines, canopy, weathering via low-denoise img2img over the current bodies.
**Acceptance:** side-by-side vs raptor reads as the same game; rotors still track
hubs; §V.

### WS-C4 `[sonnet-ok]` — terrain texture + water + roads + grid (code-only)
In renderTerrain: overlay a procedurally-built tiling detail texture (sand grain /
cracked earth per biome — generate one 256px tile per biome offline into assets/,
or synthesize with layered noise), REMOVE the visible tile grid, blend water
shorelines (soft edge + shore ring instead of tile-quantized rectangles — fixes
the flat-blue-squares screenshot bug), redraw roads along corridor polylines with
soft edges (kills the HQ starburst rays), add scorch/crater decals on explosions
(ring buffer, fade), map-edge dark vignette instead of hard black cut.
**Acceptance:** §V base-view + battle screenshots: ground reads textured, no grid,
water has soft shores + shimmer, roads read as roads, explosions leave marks.

### WS-C5 [ASSET-GEN] `[sonnet-ok]` — painted decor sprites
Replace vector trees/rocks/cacti with small painted sprites (3 trees, 2 rocks,
1 cactus, 1 shrub, 2 wrecks per biome palette) generated with the scaffold;
engine draws them with the shared runtime shadow. **Acceptance:** decor no longer
clashes with painted buildings in screenshots.

### WS-C6 `[sonnet-ok]` — unified shadows + team-color trim (code)
Strip reliance on baked shadows: draw one runtime ellipse shadow (same offset/
alpha, single global light) under every unit/aircraft; add house-color system:
2px trim stripe on vehicles, canopy tint on helis, small flag/light on buildings
(player=blue-band, enemy=red-band by default, faction palettes unchanged).
**Acceptance:** mixed-generation sprites sit on one ground plane in screenshots;
ownership readable at a glance without HP bars.

### WS-C7 `[sonnet-ok]` — combat FX density pass (code)
Muzzle flashes + short tracer lines per shot, shell-impact sparks, bigger layered
explosions (fireball + debris + oily smoke column), lingering scorch decals
(shares WS-C4 buffer), impact camera micro-shake (2px, 80ms, big blasts only).
Budgeted: respect PART_CAP; scale counts by zoom. **Acceptance:** staged 16-unit
battle screenshot reads as a firefight (multiple flashes/tracers/smoke visible);
300-unit fight >=55fps.

### WS-C8 — UI de-emoji + cameo command bar
Replace ALL emoji with drawn assets: cameo build buttons auto-cropped from each
unit's East frame + building sprites (one script renders 64px cameos with colored
frames + dark outline into assets/cameo_*.png), stat icons as tiny drawn glyphs,
stencil display font (embed a free SIL-licensed one, subsetted) for headers,
minimap in a framed radar housing, selected-unit portrait + veterancy chevrons
panel. Keep the existing dark-olive CSS layout. **Acceptance:** zero emoji in the
shipped UI; build buttons show unit imagery; screenshot side-by-side reads
war-room, not web app.

### WS-C9 [ASSET-GEN, Tier 2 PILOT] — 3D-proxy camera unification pilot
The structural fix for camera anarchy (see ART_DIRECTION §3 Tier 2): Meshy (1074
credits) or Blender-built low-poly proxy for ONE tank (crusader) + ONE infantry
(ranger); render 8 yaws at the locked 40° camera in Blender (Blender MCP;
checkpoint .blend first per its skill rules); batch-restyle renders via img2img/
Qwen-Edit into the painted look; integrate as <key>_0..7 and A/B screenshot vs
current. **GATE: Blaine reviews the A/B before the roster batch is approved.**
If passed -> follow-up WS batches all vehicles/aircraft/infantry + 3/4 building
facades per faction; rotation-derivation retires for units done this way.

## §5 TRACK D — Engine hardening (top audit code findings, added 2026-07-09)
### WS-D1 `[sonnet-ok]` — deploy pipeline correctness
deploy.ps1: copy public/index.html only AFTER firebase deploy succeeds (or restore
mtime on failure) — the current copy-then-deploy order makes a failed deploy
silently skip forever after; AUTO-BUMP the sw.js cache version (content-hash stamp
into browser-generals-HASH) on every deploy; generate the sw.js precache
unit/building lists FROM the HTML's UNIT_SPRITE_REG at deploy time (hand-sync
drifts -> broken offline).
### WS-D2 `[sonnet-ok]` — save system fixes
Two slots (manual vs auto) + validate-before-wipe in deserialize (parse fully into
a staging object, only then resetMatchState); reset G.upgrades in startGame (the
warCollege leak persists across matches); round path floats + drop per-unit path
tails in serialize (autosave hitch/quota); construction-damage fix (updateBuild
must not overwrite battle damage: track damageTaken separately).
### WS-D3 `[sonnet-ok]` — devicePixelRatio rendering
resize() must size canvas at CSSxDPR and scale the context — the whole game is
blurry on phones today, undermining every art WS. Verify perf at DPR 2 (may need
render-scale cap on weak devices).
### WS-D4 — canvas memory on Large maps
terrCanvas + two water canvases allocate ~315MB RGBA on 128^2 maps — iOS eviction
risk. Water shimmer -> small per-pond canvases (4-12 tiles each); consider terrain
tiling into 1024px chunks rendered lazily.
### WS-D5 — input-mode state machine (pre-B2 dependency)
Consolidate G.placing/amoveMode/swTargeting/wallDrag/touch.mode into one explicit
mode enum with enter/exit fns — the Powers targeting (WS-B2) needs a 6th mode and
the current 5-flag convention is where it will break.
### WS-D6 `[sonnet-ok]` — AI polish bugs
AI superweapon + wave targeting must exclude wall segments (a nuke on a $60 wall
tile) — filter target pools by def.cost>=200 or !def.wall.
