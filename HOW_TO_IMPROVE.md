# HOW_TO_IMPROVE.md — Blaine's step-by-step guide

Plain-English instructions for improving Iron Sunset whenever you want, from your PC
or your phone. No memorization needed — the docs in this folder carry all the context;
your job is just to point a Claude session at them and review results.

---

## A. The 30-second version
1. Open a Claude Code session (any model tier).
2. Say: **"Read Generals_Clone/MAINTENANCE.md and FINISH_PLAN.md, then execute the next
   pending workstream."**
3. When it reports done, spot-check (section D below), then say **"deploy"** if it
   hasn't already.
That's the whole loop. Everything below is detail.

## B. Starting a work session (PC)
1. Open Claude Code in `...\Documents\Claude\Projects`.
2. Pick your model by cost: cheap model for workstreams tagged `[sonnet-ok]` in
   FINISH_PLAN.md; strongest model for untagged ones, art generation, or "something's
   weird and I don't know why".
3. First message, copy-paste ready:
   > Read Generals_Clone/MAINTENANCE.md fully, then FINISH_PLAN.md. Tell me the next
   > pending workstream and its acceptance criteria, then execute it. Verify per the
   > protocol before telling me it's done.
4. If you instead want something NEW (not in the plan), still start with:
   > Read Generals_Clone/MAINTENANCE.md first. Then: <your idea>. Add it to ROADMAP.md
   > or FINISH_PLAN.md as a proper workstream before implementing.
   (This keeps the docs the single source of truth so future sessions know about it.)

## C. Working from your phone (dispatch)
1. Dispatch a session with the same opening message as B.3.
2. Phone sessions push to GitHub but can't deploy to Firebase. Next PC session, say:
   > Pull latest and run deploy.ps1 -Force
3. (Optional, one-time fix: add the `FIREBASE_TOKEN` secret to the GitHub repo —
   Settings → Secrets → Actions — and phone pushes will auto-deploy via CI.
   Get the token by running `firebase login:ci` on the PC.)

## D. How to review what a session did (5 minutes)
1. Open **https://browser-generals.web.app** — hard-refresh (Ctrl+F5 on PC; on phone,
   close the tab/app fully and reopen — the offline cache is sticky).
2. **Art changes:** open `https://browser-generals.web.app/?gallery=1` — flip pages with
   ←/→. Every unit should read as its type, face RIGHT in frame 0, and all 8 frames of a
   unit should be the same size.
3. **Map/terrain changes:** open `.../?test=map` with the browser console open (F12) —
   you want `MAPTEST 750/750 PASS`.
4. **Gameplay changes:** play 5 minutes. Watch specifically for: units facing the wrong
   way while moving, size mismatches, double legs/blades, anything that made you say
   "that looks wrong" — screenshot it if so.
5. Your screenshots are GOLD. Paste them into the next session with one line about
   what's wrong — that's exactly how the current defect list was built.

## E. If something looks broken after an update
1. Don't debug it yourself. Screenshot it.
2. New session, strongest model, paste screenshot(s) + this:
   > Read Generals_Clone/MAINTENANCE.md §6 (triage). Here's what I see. Diagnose with
   > evidence (render tests/montages) before fixing, fix, verify per protocol, deploy.
3. Nuclear option (game completely dead): tell the session
   > Roll back: git log to find the last good commit, git revert the bad ones, deploy.
   Every deploy is a commit, so rollback is always safe and quick.

## F. Spending guardrails
- One workstream per session keeps costs predictable and results reviewable.
- The `[sonnet-ok]` tags in FINISH_PLAN.md exist to save money — use them.
- Art generation runs on YOUR GPU via ComfyUI (free); if a session proposes paid
  image APIs, tell it to use local ComfyUI per MAINTENANCE.md §5.
- If a session seems stuck in a loop, stop it and restart with a stronger model and
  the specific error pasted in.

## G. When FINISH_PLAN is done → shipping & money
1. Say: **"Read ROADMAP.md, execute R4 stage by stage."** Stage gates in order:
   naming decision (Iron Sunset collides with a 2015 indie game — pick/clear a name
   BEFORE store submission), itch.io free release, portal SDK build (CrazyGames/Poki),
   Google Play TWA (~$25 one-time + privacy policy + content questionnaire — these
   store steps are yours, a session can draft everything for you).
2. Keep the web version at browser-generals.web.app as your always-on demo.

## H. Two-line cheat sheet
- Improve: *"Read Generals_Clone/MAINTENANCE.md + FINISH_PLAN.md, execute next
  workstream, verify, deploy."*
- Fix: *"Read Generals_Clone/MAINTENANCE.md §6. [screenshot] Diagnose with evidence,
  fix, verify, deploy."*
