# ART_DIRECTION.md — Iron Sunset art bible (source-material look)

Authored 2026-07-09 from the four-lane audit (art/code/gameplay/style-research) +
in-game screenshot evaluation. This is the WHAT/WHY for making the game read like
its source genre (C&C Generals-era gritty military RTS). Execution workstreams live
in FINISH_PLAN.md **Track C**; this file is the standing reference every art WS
must follow.

## 1. The verdict driving everything: camera anarchy
The build currently mixes FOUR art generations on one battlefield:
painted side-profile hero vehicles (USA/China), 64×64 top-down pixel minis (ALL
nine GLA vehicles), rotation-derived true-overhead infantry/helis, and plan-view
painted buildings — on flat vector terrain with emoji UI. Worse, camera elevation
flips WITHIN single vehicle sheets (verified: crusader E/W = side profile, N/S =
elevated 3/4 — the tank changes perspective as it turns).

**North star: ONE locked camera.** The source's actual camera is a fixed-pitch
~37.5° bird's-eye (GameData.ini), sun key-light from upper-left, uniform sharpness.
Every asset eventually renders at that one elevation, one light, one grit level.

## 2. Locked style constants (use in every generation)
- **Camera:** ~40° above horizontal, one yaw per facing, NEVER mixed within a set.
- **Light:** warm sun from upper-left; ONE shared shadow direction. Strip baked
  AI shadows; the engine draws a consistent runtime ellipse shadow instead.
- **Grade:** gritty desaturated realism, dusty; painted-over-photo texture crunch
  (chunky readable detail, slight blur — NOT photoreal noise, NOT cartoon).
- **Faction palettes:** Coalition = light metallic grey + blue accents, clean
  high-tech. Pact = olive-drab + red trim/star-like iconography, heavy riveted
  industrial. Syndicate = khaki/rust scrap, tarps, welded plates, mudbrick.
- **Team color:** small house-color trim decals (stripe/canopy/flag), never
  whole-unit tint.
- **Proportions:** slightly oversized turrets/weapons; infantry oversized relative
  to vehicles (readability at RTS zoom). In-engine size hierarchy: infantry <
  light vehicle < MBT < dozer ≈ MBT+ < super-units; FIX the current dozer(62) >
  tank(38) inversion via the registration table.
- **Shared prompt scaffold:** "aerial three-quarter military RTS unit render, seen
  from 40 degrees above, gritty realistic 2003 video game style, desaturated dusty
  palette, warm sunlight from upper left, painted texture detail, plain background"
  (+ faction palette line + unit archetype line).

## 3. The tiered path (playable at every step)
**Tier 1 — cohesion without re-cameraing (cheap, big visible payoff):**
hygiene sweep (contaminated frames, bulldozer ghost-box, dupes, MiG saturation),
GLA vehicle regeneration at hero fidelity, heli repaint at jet fidelity, terrain
painted-texture pass + water/roads/grid fixes, UI de-emoji (cameo buttons), FX
density pass, unified runtime shadows, team-color trim. After Tier 1 the game
reads as ONE cohesive (if hybrid-camera) RTS.

**Tier 2 — camera unification via the 3D-proxy pipeline (how the original did it):**
build rough low-poly models (Meshy — installed, ~1074 credits — or Blender MCP),
render each at the locked 37.5–40° camera at 8 yaws in Blender → perfect facing +
elevation consistency by construction (supersedes rotation-derivation) → restyle
the renders via low-denoise img2img/Qwen-Edit into the painted look. PILOT on one
tank + one infantry first; batch the roster only after the pilot passes vision
review. Buildings re-shot as 3/4 facades per faction (3 factions × key buildings).

**Tier 3 — own-style LoRA:** once 20–40 sprites are unified, train a lightweight
SDXL LoRA on OUR outputs (comfyui MCP train_* tools, RTX 3080) so all future
content lands on-style automatically. IP-clean by construction.

## 4. Local tooling map (verified on disk 2026-07-09)
- READY: SDXL checkpoints (juggernaut/dreamshaper), Qwen-Image-Edit-2511 GGUF +
  Lightning LoRA (commercial-safe batch restyler), controlnet-union-sdxl-promax +
  full SD1.5 ControlNet suite, ComfyUI-RMBG, Ultimate SD Upscale + 4x-UltraSharp,
  IPAdapter_plus NODES, Meshy (1074 credits), Blender MCP, comfyui MCP batch +
  LoRA-train tooling. Military_Uniform + ww2-style LoRAs already on disk.
- INSTALL (free, small): ip-adapter-plus_sdxl_vit-h.safetensors (~850MB — unlocks
  IPAdapter STYLE transfer; encoder already present); Civitai "C&C Generals Style"
  LoRA (models/1475301, SDXL) — LOW WEIGHT (≤0.5), palette/atmosphere only.
- FLUX-dev/Kontext: NON-COMMERCIAL license — do NOT use for Iron Sunset art.
- ⚠ ComfyUI Desktop (:8000) must be RUNNING before any art WS (it was down during
  the audit; MCP config may still point at :8188 — use HTTP :8000 directly).

## 5. IP guardrails (binding — monetization-bound project)
- Copy freely: camera angle, palettes, UI layout conventions (bottom command bar,
  cameo grid, portrait), mechanics, FX language. None of that is protectable.
- NEVER reproduce EA's specific trade dress: no one-to-one silhouettes of signature
  designs (twin-barrel deck-tank, uplink-ring cannon, launcher-cluster superweapon,
  Generals-styled airframes). Redesign from the generic archetype every time.
- The Civitai C&C LoRA is trained on EA screenshots: low weight, never prompt named
  EA units, human similarity pass on every shipped sprite; regenerate look-alikes.
- No EA names/marks/audio anywhere (extend the RESKIN grep gate); no ripping/
  tracing game files or OpenSAGE-loaded assets; no C&C imagery in store marketing.
- No real logos/insignia; generic archetype unit descriptions only.

## 6. FX + presentation language (Track C targets)
Combat must read as fireworks: muzzle flashes with short tracer lines, shell-impact
sparks, oily black smoke columns, orange fireball explosions with debris, lingering
scorch decals, movement dust. UI: bottom-bar identity — minimap-left in a framed
radar housing, cameo build grid center (painted unit portraits, colored frames,
dark outlines), selected-unit portrait + veterancy right, stencil display font for
headers, zero emoji. Terrain: tiling painted detail texture over the noise base,
splat-blended transitions, road splines that read as roads, blended shorelines,
craters/debris props, no visible debug grid; map edge fades dark instead of
hard-cutting to black.
