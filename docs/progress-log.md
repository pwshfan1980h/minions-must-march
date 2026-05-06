# Minions Must March - Progress Log

Use this file to keep durable notes across sessions.

## 2026-05-04 - Initial planning

- Created initial doc structure for **Minions Must March** in the project repository.
- Captured phased rollout from planning through demo pack.
- Defined initial mechanics assumptions around automatic walking minions, blocker, builder, digger, tunneler, terrain, hazards, and rescue goals.
- Proposed 1280x720 target with 32px grid and SVG/procedural asset strategy.
- Drafted first three starter puzzle levels:
  1. Bridge School - blocker + builder tutorial and first polish target
  2. Basement Shortcut - digger/vertical route tutorial
  3. Side Tunnel - tunneler/sideways route tutorial

## Current Recommendation

Start implementation with **Level 1: Bridge School** only. Build it crude, test mechanics, run an early Web export trial, then polish enough to validate fun before expanding.

## 2026-05-04 - Tech stack exploration

- Will asked about trying Python for this project and specifically called out original Lemmings-style damageable terrain with small terrain edits.
- Added `docs/tech-stack-options.md`.
- Initial exploration considered **pygame-ce**, because direct mutable surfaces plus masks are a strong fit for pixel/bitmap-style destructible 2D terrain.

## 2026-05-04 - Project location update

- Will confirmed the intended tone: relaxing and funny like actual Lemmings.
- Moved/planned project location into a dedicated project repository.

## 2026-05-04 - Godot decision

- Will confirmed he has used Godot and loves it.
- Tech stack decision changed from exploratory Python/pygame-ce to **Godot 4**.
- Updated `docs/tech-stack-options.md` into a Godot-focused tech stack decision doc.
- Current terrain architecture direction: chunked bitmap/image terrain with generated or sampled collision, deterministic minion movement, and terrain-editing brushes for digging/tunneling/building.

## 2026-05-04 - Web export target

- Will said the project will likely work toward exporting to web.
- Updated `docs/tech-stack-options.md` with Godot Web export implications.
- Important follow-up: run an early Web export smoke test after Level 1 works on desktop, before expanding content.

## 2026-05-04 - Early vertical slice web trial

- Will asked to include an early vertical slice trial run with exported web content in the plans.
- Updated `docs/tech-stack-options.md` with an explicit Early Vertical Slice Web Trial milestone and success criteria.
- The dedicated implementation roadmap includes this milestone before broad content expansion.

## 2026-05-04 - Phased roadmap update

- Will asked to plan phases and provide a Claude prompt for review/checks.
- Rewrote `docs/project-plan.md` into a Godot-focused phased roadmap.
- Added explicit phases for Godot project skeleton, core simulation, first job mechanics, early vertical slice web trial, Level 1 polish, destructible terrain prototype, mechanics expansion, content pipeline, and demo pack.
- Updated `docs/README.md` so the tech stack link reflects the Godot decision instead of the earlier Python exploration.

## 2026-05-04 - Theme locked to lanky skeleton minions

- Will clarified the game should stay **Minions Must March**, with the minions as **little lanky skeletons**.
- Reworked planning docs around spooky-cute skeleton minions, ruins, crypts, cracked stone, dirt, and underground tunnels.
- Digger is explicitly downward digging.
- Tunneler is explicitly sideways/horizontal tunneling.
- Builder uses planks, rib-bone steps, tombstone slabs, or scrap dungeon boards.
- Blocker uses a braced skeleton pose, sign, or shield.


## 2026-05-04 - Crypt theme details

- Will clarified the theme should lean into crumbling crypts, bats, and whatever fits that spooky skeleton-minion world.
- Updated docs to emphasize crumbling crypts, catacombs, bats, cobwebs, candles, cracked stone, light pillars, bone piles, crypt traps, and unstable masonry.
- Ambient bats/spiders are currently flavor/background first, not core hazards until mechanics are proven.


## 2026-05-04 - Godot project bones created

- Created initial Godot 4 project skeleton in the project root.
- Added `project.godot`, `scenes/GameRoot.tscn`, core scene folders, scripts, placeholder terrain, placeholder object markers, placeholder UI, and one procedurally drawn lanky skeleton minion.
- Added placeholder `levels/level_001_bridge_school.json` for future level data/schema work.
- Next implementation step: open in Godot, confirm the main scene runs, then replace placeholder movement/terrain with deterministic collision and spawn logic.

## 2026-05-04 - Godot installed and smoke-tested

- Installed Godot via Homebrew cask: `godot` 4.6.2 stable.
- Verified CLI availability with `godot --version`.
- Ran a headless project smoke test: `godot --headless --path . --quit`.
- The placeholder project loaded and printed readiness messages from `LevelController`, `GameUI`, and `GameRoot`.

## 2026-05-04 - Editor launch confirmed by Will

- Will opened the Godot project and confirmed the placeholder scene is visible/running in the editor.
- Project bones are validated enough to start real gameplay implementation next.

## 2026-05-04 - First playable Godot core loop

- Implemented static terrain collision using `StaticBody2D` rectangles.
- Converted skeleton minions to `CharacterBody2D` with gravity, floor collision, wall/edge turning, fall death hooks, and rescue/death signals.
- Implemented spawn queue: 20 minions, timed release, active/saved/lost counters.
- Implemented exit detection via `Area2D`; minions are rescued and removed on entry.
- Implemented level completion once spawning is done and active minions reach zero; success requires 12 rescued.
- Updated UI with live counters and win/fail result text.
- Added screenshot capture hook using `MMM_SCREENSHOT_PATH`, `MMM_SCREENSHOT_DELAY`, and `MMM_EXIT_AFTER_SCREENSHOT`.
- Captured screenshots in `docs/screenshots/`: `core-loop-initial.png`, `core-loop-mid-spawn.png`, `core-loop-finish.png`.
- Smoke-tested with `godot --headless --path . --quit`.

## 2026-05-06 - Core loop visually confirmed by Will

- Will opened/accessed the Godot game and confirmed the skeleton minions are now correctly walking along the platform and correctly exiting when needed.
- Next planned work remains the Phase 2 manual test checklist, then Phase 3 Blocker/Builder mechanics for Level 1: Bridge School.

## 2026-05-06 - Gravity test layout prepared

- Will confirmed spawn rate and exiting look great.
- Reworked the current Godot prototype layout into a gravity test: skeleton minions spawn in open air, fall safely onto a lower crypt walkway, then march into the exit.
- Updated `scripts/terrain/terrain_root.gd`, `scripts/minions/minion_root.gd`, `scripts/objects/object_root.gd`, and `levels/level_001_bridge_school.json` to match the gravity-test setup.
- Verification: `godot --headless --path . --quit` passed, and a 720-frame fixed-FPS headless run completed without script/runtime errors.

## 2026-05-06 - Fall-damage test layout prepared

- Will confirmed the safe gravity test looks okay for falling speed and results.
- Reworked the current prototype layout into a fatal fall test: skeleton minions spawn high in open air, land on a lower crypt walkway, and should shatter/loss-count on landing before reaching the exit.
- Verification: Godot headless smoke test and 720-frame fixed-FPS run both completed without script/runtime errors after the fall-damage layout change.

## 2026-05-06 - Bone splash death feedback

- Will confirmed skeleton minions perish correctly on fatal falls and asked for a bone splash on death.
- Added `scenes/effects/BoneSplash.tscn` and `scripts/effects/bone_splash.gd`, a short-lived procedural burst of small bone shards/skull-like bits with gravity and fade-out.
- Updated `scripts/minions/skeleton_minion.gd` so `_die()` spawns the bone splash at the minion position before queue-free.
- Verification: Godot headless smoke test and 720-frame fixed-FPS run completed after fixing GDScript variant typing in `bone_splash.gd`.

## 2026-05-06 - First Blocker mechanic slice

- Will liked the bone splash and asked for the next step.
- Added the first Blocker mechanic slice: click a grounded skeleton minion to spend a blocker charge and make it brace in place.
- Blocker minions join a `blockers` group, draw with a braced pose/highlight, and cause approaching minions to turn around before overlap.
- Updated UI status text to show remaining blockers and the click-to-blocker hint.
- Reworked the current prototype into a blocker test layout: minions spawn on the right, march left, and can be redirected back toward the exit by placing a blocker.
- Verification: Godot headless smoke test and 720-frame fixed-FPS run completed after fixing GDScript type inference in blocker detection.

## 2026-05-06 - Removed ledge self-preservation

- Will found an important behavior bug: skeleton minions were turning around at platform edges on their own.
- Fixed baseline minion behavior so they only turn around on walls or blockers, not ledges. If terrain ends, they now walk off and fall.
- Updated `docs/mechanics-spec.md` and `levels/level_001_bridge_school.json` to capture that this ledge-death/blocker requirement is the intended core Mission 1 problem.

## 2026-05-06 - Job selection UI foundation

- Will noted levels should come last and asked for the next design element.
- Added the first job-selection UI foundation instead of hardwiring every click to Blocker forever.
- Added a bottom-bar Blocker button with hotkey `1`; the selected job now flows from `GameUI` -> `GameRoot` -> `LevelController` -> `MinionRoot`.
- Current behavior is intentionally still only Blocker, but the control path is now ready for future jobs like Builder/Digger without rewriting minion click handling.

## 2026-05-06 - Resume March blocker toggle

- Will noticed blockers could permanently trap the level after doing their job.
- Added `resume_march()` on skeleton minions so clicking an existing blocker releases it back into walking mode.
- Updated Blocker click handling to toggle blockers: placing a blocker spends one charge, releasing via Resume March refunds the charge up to the level's blocker cap.
- Updated the Blocker button/status hint to teach: "Click blocker to Resume March".
- Verification: Godot headless smoke test and 720-frame fixed-FPS run completed.

## 2026-05-06 - Procedural SFX first pass

- Added a Godot headless generation script for deterministic procedural WAV files under `assets/audio/generated/`.
- Generated eight starter SFX: bone clack, bone splash, blocker brace, resume march, exit rescue, job select, level success, and level fail.
- Added an `SfxPlayer` node to `GameRoot` and wired sound requests through `MinionRoot` -> `LevelController` -> `GameRoot`.
- Hooked SFX to blocker assignment/resume, minion rescue/loss, job selection, and level success/fail.
- Added a resource check script to verify all generated WAVs import/load as `AudioStream`s.
- Verification: generated assets with Godot, imported assets headlessly, loaded all generated AudioStreams, ran Godot headless smoke test, and ran a 720-frame fixed-FPS simulation.

## 2026-05-06 - Roadmap reshaped for small sessions

- Updated `docs/project-plan.md` with a current status snapshot and a small-session roadmap.
- Broke the next work into focused sessions: Builder design lock, Builder v0 implementation, Level 1 solvable loop, UX/feedback pass, Web export recheck, and Level 1 polish start.
- Marked completed/partial phase statuses so future sessions can quickly pick the next useful target without rereading the whole plan.

## 2026-05-06 - Quick Underworld/Styx art pass

- Replaced the plain bottom support/spike-floor direction with a pitch brownish-black River Styx-style water hazard at the bottom of the playfield.
- Added a simple procedural crypt backdrop: black-to-grey/purple gradient, faint underworld glow, drifting ground fog/dust, animated water wave lines, and pale soul shapes floating in the water.
- Added a `StyxDeathWater` area so minions can know they died to `styx_water` instead of generic fall death.
- Updated skeleton death handling so water deaths keep the bone splash and then fade/sink away before being counted lost.
- Updated mechanics/asset/level docs to make underworld water the first-wave bottom hazard direction.

## 2026-05-06 - Design docs updated for Styx delta

- Expanded design docs so the River Styx art pass is treated as the intended first-wave underworld direction, not a throwaway placeholder.
- Documented death-kind intent: shared bone-splash failure language plus death-specific treatments like `styx_water` fade/sink.
- Updated Level 1 notes/layout to remove the old spike/support-floor mental model and represent the bottom hazard as water.
- Added near-term polish guidance for waterline readability, souls/fog, and crypt backdrop restraint.

## 2026-05-06 - Styx soup and audio placeholder refinement

- Checked `assets/` for external sound candidates; only generated WAVs are currently present, so better imported SFX can be swapped in later when added.
- Added a generated `styx_impact.wav` placeholder for sludgy water impact and made `bone_splash.wav` more brittle/death-like for now.
- Softened `exit_rescue.wav` into a smoother, lower chime so saves feel less sharp.
- Moved death SFX to a new immediate `death_started` signal so impact/bone sounds play when the death begins, not after water fade completes.
- Updated Styx deaths so skeletons impact at the water surface, squash slightly, then sink/fade like thick soup while preserving the bone splash.
- Reduced and redesigned souls: fewer, slower, angled tadpole/garment shapes with fading tails instead of frequent lure-like blobs.
- Darkened/reworked crypt platforms with cracks, underworld trim, and faint ghost-green sigil accents; kept lighting as fake/procedural glow for now rather than full Godot Light2D.

## 2026-05-06 - Exit pillar direction and non-doctrinal wording

- Replaced the placeholder exit arch/letter with a procedural pillar of light and upward drifting motes.
- Updated rescue behavior so skeletons entering the exit float upward, glow, shrink/fade, and disappear instead of instantly hiding.
- Removed the remaining spike object/death check from the object layer; Styx water is now the bottom failure boundary.
- Updated design docs away from explicit doctrine wording. The tone should stay loosely pop-culture underworld/afterlife inspired without naming doctrine or using explicit belief-system labels.

## 2026-05-06 - Imported shared sound candidates

- Found the shared asset stash under `/Users/devwm8/projects/assets/audio` after Will clarified the parent project assets folder.
- Imported three candidate sounds into this project:
  - `assets/audio/imported/death_bone_rattle.wav` from the pixel-combat hit-rattle pack for death/bone splash feedback.
  - `assets/audio/imported/styx_soup_impact.wav` from the pixel-combat sand-impact pack for thicker Styx impact feedback.
  - `assets/audio/imported/exit_pillar_soft.wav` from the UI pack for smoother exit/rescue feedback.
- Updated `SfxPlayer` to use those imported sounds for `bone_splash`, `styx_impact`, and `exit_rescue` with per-sound volume offsets.
- Kept generated SFX in place as source/fallback material, but the runtime map now tries the better shared candidates first.

## 2026-05-06 - Side-view skeleton animation pass

- Reworked procedural skeleton drawing from front-facing stick placeholders into side-view walking profiles that face left/right based on march direction.
- Added dynamic walk timing: lanky alternating legs, arm counter-swing, subtle bob, and forward spinal lean while moving.
- Added small per-skeleton height/posture/stride variation so the crowd feels less cloned.
- Made heads more skull-shaped with side eye socket, jaw/cheek block, and nose/mouth strokes instead of simple circles.
- Added explicit foot/toe bones and a braced side-view blocker stance.
- Follow-up detail pass added restrained pelvis, clavicle, elbow, and knee hints so the skeletons read better without becoming noisy medical diagrams.

## 2026-05-06 - Builder design lock

- Completed Small-Session Roadmap Session A.
- Locked Builder v0 behavior in `docs/mechanics-spec.md`: assign only grounded alive non-blocker skeletons; place six scene collision pieces; 28x8 px pieces; 24 px forward / 8 px upward offsets; one piece every 0.18s; resume walking after completion or deterministic stop.
- Chose scene collision pieces for Builder v0 instead of waiting for the future destructible-terrain API.
- Updated `levels/level_001_bridge_school.json` with Builder charges, tutorial hints, and the Builder v0 data block.
- Updated `docs/project-plan.md` so the next target is Builder v0 implementation.

## 2026-05-06 - Click-target debug/fairness pass

- Added a separate, larger minion `ClickArea` so selecting skeletons is easier without inflating their physics collision body.
- Routed clicks through the new click area and disabled it cleanly during rescue/death animations.
- Added `F3` debug toggle for click hitboxes; the UI status bar shows whether hitbox debug is on.
- New minions inherit the current debug-hitbox setting as they spawn.

## 2026-05-06 - Skeleton fall dynamism pass

- Tuned ledge-fall rotation to be a subtler varied spin instead of a uniform hard tumble.
- Added light airborne limb flailing so falling skeletons feel loose and dynamic without becoming cartoonish.
- Added a small sideways drift/sink wobble as bodies disappear into the Lake of Souls.

## 2026-05-06 - Skeleton ledge tumble pass

- Skeletons now start a visual topple/tumble when they walk off a ledge, rotating while gravity pulls them down instead of staying upright in midair.
- Non-fatal landings reset the tumble; fatal lake falls carry the rotation into the Styx impact.
- Styx deaths now snap to the surface, squash on impact, then sink deeper/farther into the Lake of Souls while fading out.

## 2026-05-06 - Lake of souls interaction pass

- Searched ClawHub for Godot skills; `openclaw-godot-skill` was flagged suspicious and not installed, so installed/read `godot-dev-guide` instead.
- Improved Styx death impact: skeletons now create surface ripples and vertical goop jets along with bone fragments when they hit the lake.
- Reworked the Lake of Souls flow with a wavy surface skin, layered counter-moving current lines, angular eddies, and more souls distributed across the full level width.
- Added periodic grasping hands emerging from the goop, with staggered cycles so the lake feels alive instead of static.

## 2026-05-06 - Shape-language cleanup pass

- Replaced many repeated oval/ellipse fog and glow stamps with wispy vertical mist lines, torn smoke veils, irregular polygon light shards, and faceted exit/spawn glow shapes.
- Reduced the “oblong spheroid everywhere” look while preserving rising off-gas, underworld lighting, and soul-lantern readability.

## 2026-05-06 - Atmosphere readability pass

- Reworked the uniform fog into vertical rising/off-gassing mist columns that drift upward from cracks and the Styx line, with varied green-gray and sulfur-yellow tints.
- Added background light pools to break up the flat darkness and create stronger visual pockets across the wider level.
- Added underworld street lights/soul-lanterns with dim green/yellow flicker and ground glow.

## 2026-05-06 - Level 1 teaching puzzle pass

- Reshaped level 1 into **Don't March Into the Soup**: skeletons spawn from a right-side crypt chute, initially march left toward a Styx drop, and need one blocker to turn the crowd back to the exit.
- Added a crypt chute/bone-pipe spawn visual with green glow, rim stones, bone slats, and faint dust puffs.
- Added platform visual variants: crypt stone, skull endcaps, bone bridge, obsidian slab, and chain-suspended platform treatment.
- Tuned the first level to `12` skeletons, `8` required rescues, and `1` blocker. A braced blocker no longer prevents level completion after the wave resolves.

## 2026-05-06 - Underworld background direction

- Captured upper-screen/background ideas in `docs/background-art-ideas.md`.
- Picked an initial low-clutter implementation slice: crimson upper sky, faint dead treetop silhouettes, distant tower/crypt silhouettes, broken bridge lines, and subtle green/yellow portal glow.
- Expanded the prototype level width to 2400 px so scrolling can be judged. Spawn moved far right, exit moved left, and the crypt causeway now stretches across the wider map.
- Added prototype manual camera panning with `A/D`, `Left/Right`, or `Z/X`; camera starts near the spawn side.
- Added more scroll-visible background set pieces: extra portals, distant towers, broken bridge spans, rib arches, and a faint skull mountain.

## 2026-05-06 - Skeleton scale, gait, and redraw polish

- Reduced skeleton collision capsule and procedural visual scale so minions read smaller against the same field of view.
- Reworked the leg gait into an explicit two-phase side-view walk: front/back hips, knees, ankles, and feet now share a stable ground line so shin-to-foot connections read cleaner.
- Simplified the skeleton draw pass slightly: fewer ribs/joint dots and smaller line widths at the new scale.
- Reduced skeleton redraw rate from every physics frame to animation-frame changes at 14 FPS, which should help when the full roster is on screen.
- Throttled animated terrain/Styx and exit-pillar redraws to 30 FPS instead of every process frame.
- Follow-up pass reduced skeletons another notch and changed feet into shorter angled bones, closer to a 45-degree extension from the lower leg instead of long flat feet.
- Fixed a gait issue where both legs drifted through the same horizontal phase; near/far legs now move opposite each other so one plants while the other passes forward.

## 2026-05-06 - Local Web export feasibility test

- Will asked to try a local hosted Web export now that the baseline is playable.
- Added `export_presets.cfg` with a Godot Web export preset targeting `builds/web/index.html`.
- Installed official Godot 4.6.2 Web export templates (`web_nothreads_debug.zip` and `web_nothreads_release.zip`) into Will's Godot template directory.
- Exported the project successfully to `builds/web/`.
- Started a local static server for the export on port 8088 using `/usr/bin/python3`.
- Verification: HTTP HEAD checks passed for `index.html` and `index.wasm`; local web export serving worked.

## 2026-05-06 - Web export browser smoke confirmed

- Will tested the exported Godot Web build in browser and confirmed it works well when served from `localhost`.
- LAN IP hosting is reachable after allowing Python through macOS firewall, but Godot Web secure-context requirements mean `http://192.168.x.x` is not sufficient for this build/browser path.
- Current early-web feasibility result: **pass for local browser testing**. For phone/LAN/external testing later, use HTTPS via local cert (`mkcert`), Cloudflare Tunnel, ngrok, Tailscale Funnel, or real hosting.

## 2026-05-06 - Builder Demo #1 level scaffold

- Replaced the temporary blocker teaching layout with a focused **Builder Demo #1 - First Rib Bridge** scaffold.
- Minions now spawn on the left, march right, and encounter one narrow Styx gap before the exit; the camera starts on the demo area instead of the old far-right spawn.
- Tuned the demo to `8` skeletons, `6` required rescues, `0` blockers, and `1` intended Builder charge so Builder mechanic #1 can be tested without blocker timing noise.
- Added a gold build-line marker plus six translucent rib-bone ghost pieces showing the exact expected Builder v0 placement: 28x8 px pieces at 24 px forward / 8 px upward increments.
- Updated `levels/level_001_bridge_school.json` to describe the demo geometry and expected piece centers for implementation verification.
- Verification: `python3 -m json.tool levels/level_001_bridge_school.json`, Godot headless smoke, and Web export pack all passed. Headless screenshot capture is unavailable with Godot's dummy rendering backend.
