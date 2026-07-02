# RESKIN_MAP.md — Original-IP Rename Table

Companion to `PLAN.md` WS-7.1 and `SPEC.md` §7. Purpose: remove every EA / real-world
trademark from player-visible strings so the game is monetizable, with **zero gameplay
change**. The executing agent applies tables 1–4 mechanically, then runs the §6 banned-term
grep as the acceptance gate.

**Scope rule:** rename DISPLAY strings only (`n:` names, `name/desc/tag`, `<title>`, menu/help/
README text). Do **NOT** rename internal keys (`k:'paladin'`, `FACTIONS.USA`, sprite filenames)
— they are invisible to players; renaming them risks breaking sprite paths and saves for zero
legal benefit. (§5 covers the optional purist key-rename as a separate, later, low-priority job.)

## 1. Game identity

| Old (current) | New |
|---|---|
| Browser Generals — Zero Hour Tribute (`<title>`) | **IRON SUNSET — Browser RTS** |
| BROWSER GENERALS (start-screen h1) | **IRON SUNSET** |
| "A fan-made browser tribute to Command & Conquer: Generals — Zero Hour" (`.sub`) | **"Fast single-file skirmish RTS — by SunsetSarge"** |
| README title/features referencing C&C / Generals / Zero Hour / EA units | Rewrite per new names (WS-7.2) |
| Hosted site `browser-generals.web.app` (rename ONLY with Blaine's confirmation) | `iron-sunset.web.app` |
| Repo `sunsetsarge/browser-generals` (optional; breaks links — Blaine's call) | `sunsetsarge/iron-sunset` |
| Announcer/EVA concept (used in audio WS-3.4 speech lines) | callsign **"OVERSEER"** |

Rationale for the title: ties to the existing SunsetSarge brand; no known game trademark
collision at a quick check — **executing agent must re-verify** (search "Iron Sunset game"
+ USPTO TESS quick query) before store submission and flag hits to Blaine.

## 2. Factions

| Old | New | Short | Identity keywords for desc/tag rewrite (see SPEC §1) |
|---|---|---|---|
| USA | **Meridian Coalition** | Coalition | high-tech, expensive, veteran self-repairing elites, air power; fragile logistics/power |
| China | **Ironclad Pact** | the Pact | massed armor + horde bonus, tough, slow tempo, volatile reactors |
| GLA | **Jackal Syndicate** | Syndicate | cheap, fast, scavenger salvage economy, no power grid; fragile, no aircraft |

Faction colors (blue/red/khaki) are unchanged — colors aren't trademarks.

## 3. Units

### Coalition (was USA)
| key (unchanged) | Old display name | New display name |
|---|---|---|
| ranger | Ranger | **Trooper** |
| missile | Missile Defender | **Lancer** |
| sniper | Pathfinder | **Longsight** |
| humvee | Humvee ⚠ (AM General TM) | **Outrider** |
| crusader | Crusader Tank | **Bastion Tank** |
| paladin | Paladin Tank ⚠ | **Warden Tank** |
| tomahawk | Tomahawk Launcher ⚠ (Raytheon TM) | **Stormcaller Launcher** |
| raptor | F-22 Raptor ⚠ (Lockheed TM) | **Peregrine Interceptor** |
| comanche | Comanche ⚠ (Boeing/Sikorsky) | **Kestrel Gunship** |
| burton | Colonel Cully (already original — Blaine's easter egg) | **Colonel Cully** (keep) |
| avenger | Avenger ⚠ (EA + Boeing system) | **Sunlance** (AA laser — brand tie-in) |
| aurora | Aurora Bomber ⚠ | **Dawnstrike Bomber** |
| chinook | Chinook ⚠ (Boeing TM) | **Skyhook Hauler** |
| bulldozer | Bulldozer (generic) | **Bulldozer** (keep) |

### Ironclad Pact (was China)
| key | Old | New |
|---|---|---|
| redguard | Red Guard | **Iron Guard** |
| hunter | Tank Hunter | **Tankbreaker** |
| dragon | Dragon Tank ⚠ (EA unit) | **Salamander Tank** |
| gattling | Gattling Tank | **Shredder Tank** |
| battlemaster | Battlemaster ⚠ (EA unit) | **Mastiff Tank** |
| overlord | Overlord Tank ⚠ (EA unit; also trade-dress check WS-5.3) | **Colossus Tank** |
| inferno | Inferno Cannon ⚠ (EA unit) | **Pyre Cannon** |
| mig | MiG Fighter ⚠ (Mikoyan TM) | **Firebird Fighter** |
| helix | Helix ⚠ (EA unit) | **Dragonfly Gunship** |
| lotus | Nightshade (already renamed from Black Lotus) | **Nightshade** (keep) |
| nukecannon | Nuke Cannon ⚠ (EA unit) | **Meltdown Cannon** |
| truck | Supply Truck (generic) | **Supply Truck** (keep) |
| dozer | Dozer (generic) | **Dozer** (keep) |

### Jackal Syndicate (was GLA)
| key | Old | New |
|---|---|---|
| rebel | Rebel | **Raider** |
| rpg | RPG Trooper | **Rocket Militia** |
| terrorist | Terrorist ⚠ (content-rating risk, not just IP) | **Fanatic** |
| technical | Technical (generic military term) | **Technical** (keep) |
| quad | Quad Cannon ⚠ (EA unit) | **Quadgun** |
| scorpion | Scorpion Tank ⚠ (EA unit) | **Sandviper Tank** |
| marauder | Marauder Tank ⚠ (EA unit) | **Ravager Tank** |
| buggy | Rocket Buggy (generic) | **Rocket Buggy** (keep) |
| toxin | Toxin Tractor ⚠ (EA unit) | **Venom Sprayer** |
| scud | SCUD Launcher ⚠ | **Hellrain Launcher** |
| jarmen | Deadeye (already renamed from Jarmen Kell) | **Deadeye** (keep) |
| bombtruck | Bomb Truck (generic) | **Bomb Truck** (keep) |
| cycle | Combat Cycle (generic) | **Combat Cycle** (keep) |
| worker | Worker (generic) | **Worker** (keep) |
| battlebus | Battle Bus ⚠ (EA unit + Fortnite association) | **War Wagon** |

## 4. Buildings

| key | Faction(s) | Old | New |
|---|---|---|---|
| hq | all | Command Center | **Headquarters** |
| power | USA | Cold Fusion Reactor | **Fusion Plant** |
| power | CHINA | Nuclear Reactor | **Fission Reactor** (keeps the explode-on-death flavor readable) |
| supply | USA/CHINA | Supply Center | **Supply Depot** |
| supply | GLA | Supply Stash | **Scrap Yard** |
| barracks | all | Barracks (generic) | **Barracks** (keep) |
| training | USA | War College | **Officer Academy** |
| training | CHINA/GLA | Training Camp (generic) | **Training Grounds** |
| factory | USA/CHINA | War Factory | **Assembly Plant** |
| factory | GLA | Arms Dealer ⚠ (EA building) | **Chop Shop** (fits salvage identity) |
| air | USA/CHINA | Airfield (generic) | **Airfield** (keep) |
| def | USA | Patriot Battery ⚠ (Raytheon TM) | **Archer Battery** |
| def | CHINA | Gattling Cannon | **Shredder Turret** |
| def | GLA | Stinger Site ⚠ (Raytheon TM) | **Thorn Site** |
| firebase | USA | Fire Base (generic military term) | **Firebase** (keep) |
| strategy | USA | Strategy Center ⚠ (EA building) | **Command Uplink** |
| particle | USA | Particle Cannon ⚠ (EA superweapon) | **Helios Cannon** (super label: `HELIOS CANNON`) |
| bunker | CHINA | Bunker (generic) | **Bunker** (keep) |
| propaganda | CHINA | Propaganda Center ⚠ (EA building) | **Broadcast Center** |
| nuke | CHINA | Nuclear Missile | **Ballistic Missile Silo** (super label: `BALLISTIC MISSILE`) |
| market | GLA | Black Market (generic term) | **Black Market** (keep) |
| tunnel | GLA | Tunnel Network (generic) | **Tunnel Network** (keep) |
| palace | GLA | Palace (generic) | **Palace** (keep) |
| scudstorm | GLA | SCUD Storm ⚠ | **Rocket Tempest** (super label: `ROCKET TEMPEST`) |
| wall | all | Wall (generic) | **Wall** (keep) |

Superweapon `label` fields inside `super:{...}` and the banner strings built from them
("… ONLINE", "WARNING — ENEMY … DETECTED") update automatically once the labels change —
verify all three.

## 5. Optional purist pass (separate, later, low priority)
Renaming internal keys + sprite filenames (e.g. `paladin_*.png` → `warden_*.png`) removes
trademarks from the served asset URLs too. This is defensible but touches 300+ files, the
`loadDirSprites` table, `deploy.ps1`'s copy, and any saved games. Only do it if a store
review or legal notice ever demands it; the visible-strings rename above is the 95% fix.

## 6. Banned-term grep (acceptance gate for WS-7.1)
Run case-insensitively over the HTML's user-visible strings + README after the rename; zero
hits allowed (code comments exempt but clean them opportunistically):

```
Command & Conquer, C&C, Generals, Zero Hour, EA, Electronic Arts,
USA(as faction name), China(as faction name), GLA,
Humvee, Crusader, Paladin, Tomahawk, Raptor, F-22, Comanche, Avenger, Aurora, Chinook,
Red Guard, Battlemaster, Overlord, Dragon Tank, Gattling, MiG, Helix, Inferno Cannon,
Nuke Cannon, Rebel, RPG Trooper, Terrorist, Quad Cannon, Scorpion, Marauder, Toxin,
SCUD, Battle Bus, Jarmen, Black Lotus, Burton,
Cold Fusion Reactor, Patriot, Strategy Center, Particle Cannon, Propaganda Center,
Arms Dealer, Stinger, SCUD Storm, War College, War Factory
```

Note: "Generals" appearing in the phrase "Browser Generals" is the title itself — it must be
gone after table 1. "USA/China" may legitimately remain ONLY inside internal object keys
(`FACTIONS.USA`) per the scope rule; the grep gate applies to user-visible strings.
