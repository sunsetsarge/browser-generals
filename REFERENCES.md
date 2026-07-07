# REFERENCES — Single-File Canvas RTS: Finishing & Monetizing

Curated links for finishing and shipping a C&C Generals-style skirmish RTS (single-file HTML5 Canvas, vanilla JS, ~3400 lines, 8-direction sprites, Web Audio synth).

---

## 1. Open-Source JS/HTML5 RTS Games (study for architecture/feel)

- **[rvounik/rts](https://github.com/rvounik/rts)** — Vanilla JS + Canvas RTS engine, no frameworks, single `<script>` tag design philosophy identical to your project; ships pathfinding.js integration, fog of war, scrollable maps, configurable AI, and mobile canvas scaling. Closest architectural sibling to study line-by-line.
- **[gloomyson/SC_Js](https://github.com/gloomyson/SC_Js)** — StarCraft-style RTS in raw HTML5 canvas/JS (all copyrighted assets stripped); has war fog, unit/building control panel, cheat codes, and 7 test levels — good for UI/control-panel patterns.
- **[charJKL/war-game](https://github.com/charJKL/war-game)** — RTS written in JavaScript with no libraries; smaller/simpler codebase, useful as a "minimum viable RTS loop" reference before diving into bigger engines.
- **[OpenRA (GitHub)](https://github.com/OpenRA/OpenRA)** + **[OpenRA Wiki](https://github.com/OpenRA/OpenRA/wiki)** — Not JS (C#), but the wiki's Traits system, veterancy design, and data-driven MiniYAML rules format are directly inspired by Generals' SAGE design philosophy — excellent for structuring your unit/faction data even in JS.

## 2. Pathfinding & Unit Movement

- **[Red Blob Games: Flow Field Pathfinding](https://www.redblobgames.com/blog/2024-04-27-flow-field-pathfinding/)** — 2024 deep-dive by Amit Patel on flow/vector fields vs Dijkstra/A*, with the math connecting distance fields to flow fields; the canonical modern reference.
- **[How to RTS: Basic Flow Fields](https://howtorts.github.io/2014/01/04/basic-flow-fields.html)** — Practical from-scratch flow-field tutorial built specifically for RTS crowd movement (the whole howtorts.github.io series also covers vision, weapon ranges, and continuum-crowd movement).
- **[jdxdev: RTS Pathfinding 1 – Flowfields](https://www.jdxdev.com/blog/2020/05/03/flowfields/)** — Implementation-focused walkthrough (paired with his **[Boids for RTS](https://www.jdxdev.com/blog/2021/03/19/boids-for-rts/)** post) covering flow fields plus separation/flocking for large unit groups moving together.
- **[Liech/RTSNavigationLib](https://github.com/Liech/RTSNavigationLib)** — Open-source formations + pathfinding library for 2D RTS games; useful for seeing formation-keeping code you can port/adapt to canvas/JS.

## 3. 8-Directional Sprite Generation with AI

- **[PixelLab.ai — 8-Directional Sprite (Pro)](https://www.pixellab.ai/docs/tools/create-8-rotations-pro)** — Purpose-built tool: generates all 8 rotations (N/NE/E/SE/S/SW/W/NW) from a style prompt, a concept image, or a single reference pose — exactly the top-down RTS unit workflow you need. Also has an Aseprite plugin.
- **[Retro Diffusion (Astropulse, itch.io)](https://astropulse.itch.io/retrodiffusion)** — Aseprite extension with an `rd-animation` model tuned for sprite-sheet consistency across frames/angles, hard pixel-grid alignment, and palette-locking (e.g., force 16/32-color output) — good fallback/alternative to PixelLab.
- **[Stable Diffusion Art: Consistent Character from Different Viewing Angles](https://stable-diffusion-art.com/consistent-character-view-angle/)** — Technique using Canny SDXL ControlNet + IP-Adapter FaceID Plus v2 to hold a character consistent across turnaround angles; directly portable to ComfyUI if you want a free/local pipeline instead of a paid SaaS tool.
- **[Scenario: 8-Direction Sprite Generator](https://www.scenario.com/apps/8-direction-sprite-generator)** — Second commercial option for turning one reference image into a consistent 8-direction set; worth comparing output quality/pricing against PixelLab before committing.

## 4. Free/CC0 Game Art Fallbacks (top-down military)

- **[Kenney — Medieval RTS](https://kenney.nl/assets/medieval-rts)** — 120 CC0 assets (no attribution required) sized for top-down RTS; good fallback set if AI-gen art needs replacing fast.
- **[Kenney — Top-down Shooter](https://www.kenney.nl/assets/top-down-shooter)** — 580 CC0 top-down character/weapon sprites; reusable for infantry-style units.
- **[OpenGameArt: Sci-Fi RTS (120+ sprites)](https://opengameart.org/content/sci-fi-rts-120-sprites)** — Confirmed CC0 (Kenney-sourced) top-down RTS pack: structures, vehicles, environment props, units, and tiles — ready to drop in for a sci-fi-leaning faction.
- **[Kenney Game Assets All-in-1](https://kenney.itch.io/kenney-game-assets)** — 60,000+ asset mega-pack, all CC0; one download covers vehicles, terrain tiles, UI icons, and explosions/effects for the whole game if you need to bulk-replace placeholder art.

## 5. Web Audio: Tiny Synth SFX & Procedural Music

- **[ZzFX (KilledByAPixel)](https://github.com/KilledByAPixel/ZzFX)** — Sub-1KB procedural sound-effect generator, 20 tunable parameters, zero dependencies — the standard choice for keeping SFX inline in a single-file game.
- **[ZzFXM (keithclark)](https://github.com/keithclark/ZzFXM)** — 442-byte-gzipped companion music tracker/renderer built on ZzFX's synth engine; produces full stereo music tracks from pattern data with no audio files, ideal for staying single-file.
- **[jsfxr (chr15m)](https://github.com/chr15m/jsfxr)** — JS port of the classic sfxr 8-bit SFX generator; has a hosted UI at [sfxr.me](https://sfxr.me/) for auditioning presets (explosion, laser, pickup, hit) before pasting the generated params into code.
- **[js13kGames/resources](https://github.com/js13kgames/resources)** — Curated tools/assets list from the js13k competition (which mandates single-file-ish, size-constrained games); a good grab-bag for other tiny-footprint audio/graphics techniques that match your project's constraints.

## 6. Distribution & Monetization for Single-File HTML5 Games

- **[itch.io: Uploading HTML5 Games](https://itch.io/docs/creators/html5)** — Official doc: a genuinely single `.html` file can be uploaded directly and marked "This file will be played in the browser" with no ZIP needed (though it then can't reference other uploaded assets — keep everything inlined, which your project already does). ZIP path allows up to 1,000 files / 500MB if you ever split out assets. **Accepts single-file games natively; no forced SDK.**
- **[Poki SDK Documentation](https://sdk.poki.com/)** + **[Poki Requirements](https://sdk.poki.com/requirements)** — Poki (100M+ MAU) requires SDK integration (`gameLoadingFinished()`, `gameplayStart()`, `gameplayStop()` calls) for ad timing and analytics; revenue comes from ads Poki inserts around/within sessions. Requires review/approval before going live — budget dev time for SDK hooks, not just a file upload.
- **[CrazyGames Developer Portal](https://developer.crazygames.com/)** + **[Docs](https://docs.crazygames.com/requirements/intro/)** — Two-stage launch (2-week limited "Basic Launch" test, then "Full Launch" gated on playtime/retention metrics). SDK is mandatory for ad hooks and unlocks a +50% revenue share bump if you also enable in-game ads and grant a short exclusivity window. Payout minimum €100, monthly, PayPal/wire.
- **[GameMonetize SDK (GitHub)](https://github.com/MonetizeGame/GameMonetize.com-SDK)** — Lighter-weight ad SDK/network than Poki or CrazyGames; lower bar to entry, useful as a second/backup monetization channel once the game is already SDK-instrumented for one platform.
- Note on **Newgrounds**: no dedicated official upload doc surfaced in this search, but Newgrounds accepts HTML5 uploads directly (similar to itch.io) with its own ad revenue-share program — verify current terms on the site before submitting since this wasn't independently confirmed here.
- **[Bubblewrap / TWA Guide (Thinktecture)](https://www.thinktecture.com/en/pwa/twa-bubblewrap/)** + **[Google's PWA-in-Play Codelab](https://developers.google.com/codelabs/pwa-in-play)** — Path to wrap the game as a PWA and publish to Google Play via Trusted Web Activity: requires a Lighthouse PWA score ≥80, a `twa-manifest.json`, and a Digital Asset Links (`assetlinks.json`) file proving domain ownership. This is the way to get the single-file game into the Play Store without rewriting it as a native app.

## 7. C&C Generals Design References (for balance/tuning)

- **[C&C Labs — USA Units](https://www.cnclabs.com/generals/factions/usa/units.aspx)** and sibling faction pages — Per-unit cost/strength/weakness breakdowns for all three original factions (USA/China/GLA); the most granular stats reference for tuning an asymmetric design.
- **[StrategyWiki: C&C Generals / Factions](https://strategywiki.org/wiki/Command_&_Conquer:_Generals/Factions)** — Higher-level faction-philosophy summary (GLA = cheap/fast/no-armor, USA = expensive/high-tech/superior air, China = numbers + brute force) — useful as a design North Star for asymmetric identity before drilling into individual unit numbers.
- **[GameReplays.org: Unit Stats HP/DPS thread](https://www.gamereplays.org/community/index.php?showtopic=494675&mode=threaded&pid=5947763)** — Community-compiled HP/DPS numbers and competitive-balance discussion from veteran players; good for sanity-checking your own numbers against what a "solved" competitive meta looked like.
- **[GDC Vault: Classic Game Postmortem — Command & Conquer](https://www.gdcvault.com/play/1025777/Classic-Game-Postmortem-Command-Conquer)** — Louis Castle's postmortem on the original C&C (not Generals specifically, but the direct design ancestor); covers the origin of the RTS formula this whole lineage builds on.

## 8. Reddit / Community Threads

- **[r/gamedev — Notes issue thread, HowToRts repo](https://github.com/HowToRts/HowToRts.github.io/issues/1)** — Community notes/discussion tracking the howtorts pathfinding series; a good pulse-check on what other devs found unclear or extended in the flow-field tutorials.
- **[itch.io forum: Monetization (General Development)](https://itch.io/t/236560/monetization)** — Direct community thread on itch.io's monetization model: confirms itch does **not** support ads or IAP — only direct sales/donations/pay-what-you-want — a key constraint if itch is your primary channel versus an ad-supported portal like Poki/CrazyGames.
- **[HTML5GameDevs Forum: Monetising HTML5 Games](https://www.html5gamedevs.com/topic/40362-monetising-html5-games/)** — Long-running dedicated forum thread (not Reddit, but the equivalent community) comparing portal deals, ad networks, and licensing-vs-ads tradeoffs specifically for indie HTML5 devs — closest thing found to the requested Reddit shipping/monetization discussion.

> Note: targeted Reddit searches for "r/gamedev html5 canvas RTS ship/monetize" and "r/webgames browser game ads" returned no indexable results this pass — the itch.io and HTML5GameDevs forum threads above cover the same ground and are linked as substitutes.

---

## Top 5 Most Actionable

1. **[rvounik/rts](https://github.com/rvounik/rts)** — the single closest open-source analog to your own codebase; read its pathfinding/fog-of-war/AI structure before writing more of your own.
2. **[Red Blob Games: Flow Field Pathfinding](https://www.redblobgames.com/blog/2024-04-27-flow-field-pathfinding/)** + **[How to RTS: Basic Flow Fields](https://howtorts.github.io/2014/01/04/basic-flow-fields.html)** — swap in a flow field for group movement if unit pathing/clumping is still rough; this pairing gives both the theory and the copy-paste implementation.
3. **[PixelLab.ai 8-Directional Sprite tool](https://www.pixellab.ai/docs/tools/create-8-rotations-pro)** — fastest path to finishing consistent unit art; generates all 8 facings from one reference in a single pass.
4. **[ZzFX](https://github.com/KilledByAPixel/ZzFX) + [ZzFXM](https://github.com/keithclark/ZzFXM)** — drop-in, dependency-free, single-file-safe SFX and music; solves "the game needs sound" without breaking the one-file constraint.
5. **[itch.io HTML5 upload docs](https://itch.io/docs/creators/html5)** — ship here first (true single-file upload, zero SDK integration required) to get the game live immediately; layer in **[Poki](https://sdk.poki.com/)** or **[CrazyGames](https://docs.crazygames.com/requirements/intro/)** SDK integration afterward once the core game is stable and you're ready to chase ad-revenue distribution.
