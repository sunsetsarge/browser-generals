# ROADMAP.md — Iron Sunset: post-1.0 development roadmap

Companion to FINISH_PLAN.md (which gets the game to shippable v1.0). This file is the
prioritized backlog beyond it. Constraint held throughout: **one distributable HTML
file** (+ sibling sprite PNGs/PWA shell, which zip cleanly for any portal that wants
an archive). Ordered by value-to-players ÷ effort.

## R1 — Content depth (first post-ship wave)
1. **Skirmish settings screen:** starting money, unit cap, superweapons on/off,
   AI count (1v2 comp-stomp using existing AI with shared-team flag), map seed input
   (seed the existing mulberry32 → shareable maps).
2. **Neutral map content ("new enemies" without a 4th faction):**
   - Garrisonable civilian buildings (reuse bunker logic; infantry inside gain range).
   - Creep camps: 2–4 neutral defenders (reskinned existing units, owner 2) guarding
     bonus crates ($ or a free veteran unit) — makes map control matter early.
   - Tech buildings to capture (Oil Derrick = +$20/s; Repair Pad = heals vehicles) —
     capture via infantry standing 5s adjacent, classic Generals feel.
3. **Unit abilities (one button per select group):** Coalition drone-repair toggle,
   Pact mine-drop, Syndicate wreck-loot; plus per-unit specials later (flashbang,
   ECM, sprint). Data-driven: `def.ability={k,cd,fn}` + one UI slot.
4. **More maps:** 3 handcrafted layouts (chokepoint valley, island-bridges, oil-rich
   center) encoded as seed + carve overrides; map picker thumbnail = minimap render.

## R2 — Presentation upgrade (graphics wave 2)
1. **Per-faction building sprites** (the interim color-wash finally retired):
   generate per-faction variants with the locked ComfyUI recipe (img2img off the
   existing building at denoise ~0.5 with faction style prompts: Coalition=blue-grey
   hi-tech, Pact=red industrial, Syndicate=tan improvised). 18 keys × 3 factions ×
   3 damage states — batch + vision QC via the FINISH_PLAN §V protocol.
2. **Unit portraits** (sidebar/selection): one 64px bust per unit — same pipeline,
   big visual richness for 40 small images.
3. **Terrain props pack:** biome-specific decor variety (wrecks, ruins, power poles),
   animated water edge foam, scorch decals that fade.
4. **Death/wreck art:** husk sprite per vehicle class (grey-tint of frame 0 in code —
   zero new assets — Syndicate can loot husks, ties into faction identity).
5. **UI skin pass:** 9-slice panel art, faction-colored HUD accents, custom cursor set.

## R3 — Systems & modes
1. **Generals'-powers tree v2:** rank points from XP unlock power upgrades
   (FINISH_PLAN WS-B2 ships the base 9 powers; this adds choice).
2. **Campaign-lite:** 6 scripted missions (fixed maps + triggers: survive N waves,
   destroy target, escort) using a tiny trigger table {condition→action}; story text
   between missions. This is the single biggest "feels like a real game" feature.
3. **Replays:** record per-tick command log (orders are already discrete) + seed →
   deterministic playback; share as a base64 string.
4. **Map editor:** paint terr/decor/supplies on the existing grid, export seed+overrides
   string the skirmish picker accepts.
5. **Achievements** (localStorage): 20 simple ones (win with each faction, win <10min,
   no-superweapon win, 100 salvage kills…) surfaced on the end screen.
6. **Multiplayer (stretch, last):** the fixed-timestep sim is lockstep-ready; WebRTC
   DataChannel + command-lockstep for 1v1. Big lift — only after everything above.

## R4 — Distribution & monetization ladder
Stage gates — do not skip ahead; each stage feeds the next audience-wise.
1. **Gate: NAMING.** "Iron Sunset" collides with a 2015 indie browser game (flagged in
   the re-skin report). Either clear it (USPTO TESS search + keep) or rename before ANY
   store/portal submission (title is display-strings-only — 5-minute swap; candidates:
   SCRAPFRONT, IRONVEIL, RUST DOMINION, SUNSET DOCTRINE).
2. **itch.io (free, week 1):** accepts single-file HTML (or zip) with NO SDK
   requirement. Free + optional donations. Purpose: playtesters + feedback + a public
   page. Devlog posts on the itch feed.
3. **Web portals (ads revenue):** CrazyGames / Poki submissions — both require their
   JS ad SDK (loading-screen + interstitial hooks between matches) and a review for
   fun/retention. Add the SDK behind a `PORTAL` build flag so the itch/PWA build stays
   clean. GameMonetize/Newgrounds as lower-bar alternates.
4. **Google Play (TWA, ~$25 once):** the PWA already qualifies; Bubblewrap wrap +
   privacy policy page + content rating questionnaire ("Fanatic" rename already done).
   Monetize: free with rewarded ads (extra starting cash / cosmetic HUD skins) or
   $2.99 premium unlock (campaign + skins) — decide after portal retention data.
5. **iOS (last):** needs a Mac + $99/yr; Capacitor wrap; only if Play numbers justify.
6. **Marketing loop:** r/webgames + r/rts posts with a 30s GIF, one devlog per shipped
   roadmap item, itch metadata/screenshots refresh each wave.

## R5 — Tech debt / infra
- Automate SW cache-busting + version stamp in deploy.ps1 (FINISH_PLAN WS-B7).
- Sprite-atlas option: pack frames into one PNG + JSON offsets (fewer requests,
  faster SW precache) — keep loose files as the dev format, atlas as a build step.
- Optional purist re-skin pass (RESKIN_MAP §5): rename internal keys + asset
  filenames only if a store review ever demands it.
- CI: GitHub Action already deploys when FIREBASE_TOKEN is set — add the token, then
  phone-dispatched changes auto-deploy (currently local-only deploys).

## References
See REFERENCES.md (curated 2026-07-07: open-source JS RTS repos to study, flow-field
pathfinding articles, PixelLab/Retro Diffusion for consistent 8-dir sprites, Kenney
CC0 fallback art, ZzFX/ZzFXM audio, itch/CrazyGames/Poki submission requirements,
C&C Generals balance wikis).
