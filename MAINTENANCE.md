# MAINTENANCE.md — Standing protocol for working on Iron Sunset

**Audience: any Claude model (Sonnet/Opus/other) starting a session on this game with
zero prior context.** Read this file FIRST, top to bottom, before touching anything.
It tells you how to evaluate the game, how to make changes safely, and how to prove
your change worked.

## 1. Project map (read in this order)
| File | What it is |
|---|---|
| `MAINTENANCE.md` | This protocol. |
| `FINISH_PLAN.md` | Current defect fixes + completion workstreams (the active work queue). |
| `SPEC.md` | Design source of truth — faction numbers, audio table, terrain rules. Numbers here WIN over any other doc. |
| `ROADMAP.md` | Post-1.0 backlog + monetization ladder. Pick new work from here once FINISH_PLAN is done. |
| `RESKIN_MAP.md` | IP naming rules. NEVER reintroduce trademarked names in visible strings. |
| `REFERENCES.md` | Curated external resources (repos, articles, tools). |
| `generals-zero-hour.html` | THE GAME. One self-contained file (~3400 lines). |
| `assets/` | `<key>_0..7.png` unit frames (0=East, clockwise), `bld_<key>_0..2.png` building health states. `*_sheet.png` = source art, not deployed. |
| `deploy.ps1` | One-command deploy: Firebase Hosting + GitHub push. `-Force` for asset-only changes. |
| `vendor/` | Downloaded MIT libs staged for inlining (zzfx.js, zzfxm.js). |

## 2. Hard rules (violations have burned us — do not repeat)
1. **Single file.** All game logic stays in `generals-zero-hour.html`. No external JS/CSS,
   no build step. Libraries get pasted inline with an attribution comment.
2. **Never rename internal keys** (`k:'paladin'`, `FACTIONS.USA`) or sprite filenames.
   Display names (`n:'…'`) only. Renaming keys breaks sprites + saves for zero benefit.
3. **Sprite facing:** frame 0 faces EAST (right), clockwise (2=S, 4=W, 6=N). AI-generated
   8-frame sheets are unreliable per-frame — **cardinal checks are NOT enough; always
   review diagonals (frames 1/3/5/7) visually.** True-overhead art (infantry, helis) must
   be produced as ONE East frame + programmatic rotation (see FINISH_PLAN §2), never as
   8 independent AI generations.
4. **No trademarked strings** in anything player-visible (RESKIN_MAP §6 grep list).
5. **Edit surgically.** Read the region, then targeted Edits. Never rewrite the file.
   Line numbers in docs drift — re-locate by grep.
6. **Verify before deploy, deploy after verify** (§4, §5). Never claim a fix without
   running the relevant check. Report failures honestly.
7. OneDrive has EATEN files in this folder before. Git is the backup: if files vanish,
   `git status` + `git restore .` — do not panic-recreate.
8. Match the file's terse code style; comments only for non-obvious constraints.

## 3. How to EVALUATE the game (run this audit when asked "what's the status?")
1. `git log --oneline -15` + read FINISH_PLAN.md — what's done vs pending.
2. Serve locally: the preview config `generals-clone` (port 8741) or
   `python -m http.server 8741` in the project dir.
3. Built-in harnesses (all headless-safe):
   - `?test=map` → console must print `MAPTEST 750/750 PASS`.
   - `?gallery=1` → sprite review pages (canvas renders even headless if you set
     `canvas.width/height` manually before dispatching an ArrowRight keydown).
   - Normal load → `spriteAudit()` console.table: 42/42 unit sets, 54/54 bld frames.
4. In-game sim smoke test (paste in console / preview eval):
   `startGame('USA','normal','small','bl');` → then for a combat unit `u`:
   `setMove(u,u.x+300,u.y); u.order={t:'move'};` tick `update(1/60)` ×45 →
   `dirIndex(u.face,8)` must be 0. Repeat N/W/S/SE → expect 6/4/2/1.
5. Save/load round-trip: `writeSave()`, wipe `G.units.length=0`, `deserialize(JSON.parse(
   localStorage.getItem('bg_save')))` → counts/money restored, no exceptions.
6. Screenshot evidence: force `canvas.width=1500; canvas.height=850; computeLayout();
   render();` then `canvas.toDataURL()` → decode and LOOK at it (vision). Headless
   browsers here report innerWidth=0 — this manual-size trick is the workaround.
7. Payload check: deployed sprites should stay ≤4MB after WS-A7 (`du -cm assets/*_[0-7].png`).
8. Zero console errors across all of the above.

## 4. How to MAKE A CHANGE (the loop)
1. Pick ONE workstream from FINISH_PLAN.md (or ROADMAP.md if FINISH_PLAN is done).
   Respect the `[sonnet-ok]` tags: untagged workstreams want a stronger model;
   `[ASSET-GEN]` needs ComfyUI + a vision review step.
2. Read the WS spec fully, including its Acceptance criteria. SPEC.md wins conflicts.
3. Implement per §2 hard rules.
4. Run the WS's acceptance checks + the §3 audit items your change could affect.
5. Sprite changes additionally require: the diagonal montage review (vision), the size
   lint, and an in-engine render check (`drawUnit` to an offscreen canvas AFTER
   `startGame(...)` — faction lookup needs a started game).
6. Commit with a message naming the WS; deploy via `deploy.ps1` (`-Force` if only
   assets changed); curl the live site to confirm the change is served
   (`https://browser-generals.web.app/...` → 200 / new content).
7. Update FINISH_PLAN.md status (append "DONE date + evidence" to the WS) so the next
   session doesn't redo the work.

## 5. Asset pipeline quick reference (details in FINISH_PLAN §2 + the
`browser-game-builder` skill at `C:\Claude\sarges-skills\skills\browser-game-builder\`)
- Python: `C:/ComfyUI/.venv/Scripts/python.exe` (has PIL/numpy).
- ComfyUI recipe (LOCKED): `dreamshaperXL_v21TurboDPMSDE`, dpmpp_sde/karras, 14 steps,
  cfg 3.0, img2img denoise 0.35–0.42 off existing art, BiRefNet-general bg removal.
- Rotation derivation for overhead units: `make_dirs.py` (WS-A1) — one East frame in,
  8 normalized frames out.
- Verify: `verify_facing.py <key> --frames 0-7` + diagonal vision review. Remaps
  `--mirror`/`--flip` fix whole-set errors ONLY — per-frame drift means regenerate.
- Quantize before shipping new art: WS-A7 script (~80% smaller, 128 colors).

## 6. When things break (triage table)
| Symptom | First move |
|---|---|
| Units move backwards / sideways | Engine is proven correct — it's the ART. Run §3.4 sim test to confirm frame indices, then diagonal montage of the suspect unit. |
| Sprite invisible / vector fallback appears | A frame 404'd → `loadDirSprites` deletes the whole set. Check spriteAudit table + Network tab. |
| Game won't load after edit | `node --check` won't parse HTML — extract the script or eyeball the last Edit; check first console error; `git diff` vs last commit. |
| Save fails to load | Schema changed — bump save version `v` and fail closed (existing pattern in `saveMeta`). |
| Live site stale after deploy | SW cache: bump the cache name in `sw.js` (`browser-generals-vN`), redeploy `-Force`, hard-reload. |
| Files missing from folder | OneDrive sync loss: `git restore .` |
| Firebase deploy skipped | mtime gate: rerun `deploy.ps1 -Force`. |
| Push rejected | Phone-dispatched session pushed first: `git pull --rebase origin main`, review what came in, then push. |

## 7. Model routing (cost discipline)
- Planning/judging/diagnosis of weird bugs: strongest available model.
- `[sonnet-ok]` workstreams, batch scripts, doc updates: Sonnet.
- Mechanical bulk (renames, batch image ops): Haiku is fine WITH the script already
  written; don't let small models design pipelines.
- ASSET-GEN vision review: any model with image input, but it must output per-rubric
  verdicts (FINISH_PLAN §V), not "looks fine".
