# Minions Must March - Project Plan

## Game Pitch

**Minions Must March** is a Lemmings-inspired 2D puzzle game where a crowd of little lanky skeleton minions marches through crumbling crypts, catacombs, haunted ruins, and underground tunnels. The player assigns limited jobs to redirect, protect, dig, tunnel, build, or modify terrain so enough minions reach the exit crypt/portal.

Tone: spooky-cute skeleton minion chaos, light crypt comedy, readable puzzle design, clear hazards, practical UX.

## Current Technical Direction

- Engine: **Godot 4**
- Language: **GDScript first**
- Target: desktop during development, with an early **Godot Web export** vertical slice
- Movement/collision: deterministic custom minion logic rather than full rigid-body physics
- Terrain direction: eventually chunked bitmap/image terrain with sampled or generated collision for Lemmings-style destructible terrain

## Guiding Constraints

- Theme should center on crumbling crypts, catacombs, bats, cobwebs, bones, candles, portals, cracked stone, and spooky-cute undead slapstick.
- Favor SVG, procedural, vector, or simple stylized assets where practical.
- Build mechanics before content volume.
- Prove Godot Web export early, before the project accumulates too much content or engine-specific complexity.
- Polish one tiny playable slice before committing deeply to Levels 2 and 3.
- Keep levels human-solvable and readable, not puzzle-brutal.
- Prefer deterministic puzzle behavior over physics chaos.
- Use docs as source of truth and update them as implementation changes.

## Phased Roadmap

### Phase 0 - Foundation Planning

**Goal:** Define the minimum viable rules, engine direction, level format assumptions, rendering assumptions, and starter level designs.

Deliverables:

- Core mechanics spec
- Asset/sizing assumptions
- Starter level paper designs
- Godot tech stack decision
- Web export target note
- Progress log

Testing / review gate:

- Design review: can each starter level be explained in one paragraph?
- Feasibility review: does Level 1 require only MVP mechanics?
- Technical review: is the Godot plan compatible with eventual destructible terrain and web export?

Exit criteria:

- Docs clearly describe what we are building first and what we are explicitly postponing.

Status: in progress / mostly complete.

---

### Phase 1 - Godot Project Skeleton

**Goal:** Create a clean Godot 4 project structure that can support a Lemmings-like prototype without over-engineering.

Deliverables:

- Godot 4 project committed to repo
- Basic scene tree structure:
  - `GameRoot`
  - `LevelController`
  - `TerrainRoot`
  - `MinionRoot`
  - `ObjectRoot`
  - `UI`
- Placeholder camera and viewport settings
- Initial input actions for pause/restart/job selection
- A tiny test level scene or prototype scene
- Basic project export preset stub, if practical

Implementation notes:

- Keep simulation code separated from visuals where reasonable.
- Avoid Godot physics bodies for core skeleton minion behavior unless they prove clearly useful.
- Start with simple static terrain before full destructible terrain.

Testing gate:

- Project opens cleanly in Godot.
- Main scene runs without errors.
- Restart/reload path is possible, even if crude.
- No native plugins or desktop-only assumptions are introduced.

Exit criteria:

- A minimal Godot scene runs and gives us a stable place to implement skeleton minion behavior.

---

### Phase 2 - Core Simulation Prototype

**Goal:** Make skeleton minions march, collide, fall, get lost/removed, and reach an exit crypt/portal in a crude level.

MVP mechanics:

- Spawn entrance
- Exit goal
- Walking skeleton minions
- Direction reversal on walls
- Terrain support sampling
- Gravity/falling
- Lethal fall threshold
- Rescue/loss counters
- Win/loss condition
- Restart level

Suggested level:

- Tiny internal test map before Level 1 proper
- Then Level 1: **Bridge School**

Testing gate:

- Manual test checklist:
  - Skeleton minions spawn at expected rate.
  - Skeleton minions walk and turn predictably.
  - Skeleton minions fall when unsupported.
  - Falls only remove skeleton minions when above the unsafe threshold.
  - Exit rescues skeleton minions reliably.
  - Level can fail cleanly.
  - Restart resets skeleton minions, counters, and terrain state completely.

Exit criteria:

- A crude level is winnable, losable, restartable, and understandable with placeholder visuals.

---

### Phase 3 - First Job Mechanics Slice

**Goal:** Add the first player-assigned jobs needed for Level 1.

Required jobs:

- **Blocker**
  - Stops/redirects traffic.
  - Can become a simple permanent state at first.
- **Builder**
  - Creates fixed stair/bridge segments.
  - Should use the same terrain-modification philosophy we will later use for destructible terrain where practical.

Optional, only if Level 1 needs it:

- Digger or Tunneler

Implementation notes:

- Keep job assignment forgiving enough for a small prototype.
- Builder output should be deterministic and readable.
- Do not add every classic Lemmings job yet.

Testing gate:

- Blocker stops or turns skeleton minions predictably.
- Builder creates reliable walkable stairs/bridges.
- Job UI clearly shows available counts.
- Assigning a job to the wrong skeleton minion fails gracefully or is easy to recover from.
- Level 1 can be won with the intended Blocker/Builder solution.

Exit criteria:

- Level 1 proves the core “assign jobs to save enough skeleton minions” loop.

---

### Phase 4 - Early Vertical Slice Web Trial

**Goal:** Export a tiny playable Godot Web build early enough to catch browser/export problems while the project is still cheap to change.

This is a required milestone before broad content expansion.

Minimum slice:

- One tiny playable level
- Spawn entrance and exit
- Walking/falling skeleton minions
- At least one assignable job, preferably Builder
- Basic job UI
- Restart
- Win/loss state
- Exported Web build deployed somewhere Will can open by URL

Success criteria:

- Browser load works without manual setup.
- Input works correctly.
- Framerate is acceptable on Will’s target browser/device.
- Audio, if present, behaves acceptably under browser autoplay/input rules.
- Restart fully resets terrain/skeleton minions/counters.
- No export-only crashes, missing assets, broken fonts, or broken UI scaling.
- If hosting on GitHub Pages fails due to headers/browser requirements, we identify the hosting requirement early.

Testing gate:

- Desktop playthrough still passes.
- Web playthrough passes at least once from a clean browser load.
- We record any Godot version/export setting constraints in docs.

Exit criteria:

- We know whether Godot Web export is viable for this project and what constraints it imposes.

---

### Phase 5 - Level 1 Polish Slice

**Goal:** Make Level 1 feel like a real game slice before expanding content.

Add:

- Skeleton minion placeholder art upgraded to readable stylized sprites or simple animated vector sprites
- Terrain style pass
- Entrance/exit art
- Job icons
- Hover/selection feedback
- Basic sound hooks, even if placeholder
- Level intro text or tutorial prompt
- Clear end screen
- First pass of web-friendly asset sizes/import settings

Testing gate:

- Visual readability pass at target resolution and scaled sizes.
- UX pass:
  - Can the player identify spawn, exit, hazards, and job counts instantly?
  - Are job assignments forgiving enough?
  - Is the intended solution discoverable without instructions beyond basic tooltips?
- Regression checklist from Phases 2-4.
- Web export smoke test still passes after polish assets are added.

Exit criteria:

- Level 1 is polished enough to show someone and ask, “Is this fun?” without apologizing for it.

---

### Phase 6 - Destructible Terrain Prototype

**Goal:** Prove the classic Lemmings-style damageable terrain approach before designing levels around it.

Deliverables:

- Editable terrain image/chunk prototype
- Solid/empty sampling API
- Brush operation API:
  - erase terrain
  - add terrain
  - mark dirty regions/chunks
- One terrain-removal job prototype:
  - Digger downward or Tunneler sideways
- Optional dev overlay for terrain/collision visualization

Implementation notes:

- Start with one simple terrain surface if needed, then chunk it once behavior is proven.
- Prefer deterministic sampled collision for minions.
- Avoid regenerating expensive full-level collision every frame.
- Browser performance matters; profile Web export after terrain edits work.

Testing gate:

- Brush removes/adds expected pixels.
- Skeleton minions treat edited terrain correctly.
- Terrain visual and collision data stay synchronized.
- Restart restores original terrain exactly.
- Web export can run the terrain edit prototype at acceptable performance.

Exit criteria:

- We know the terrain architecture is viable before adding terrain-heavy levels.

---

### Phase 7 - Mechanics Expansion for Levels 2-3

**Goal:** Add only the mechanics needed by the next two starter levels.

Likely additions:

- Refined Digger and Tunneler depending on selected starter levels
- One hazard type: spikes, acid slime, crusher blocks, holy wards, crumbling floors, bats-as-ambience, or similar
- Optional bone/charm/relic collectible pickup
- Improved level metadata/data format
- Better tutorial prompts

Testing gate:

- Each new mechanic gets a tiny mechanic-test level or dev sandbox.
- Starter Levels 2 and 3 each have one intended solution.
- Alternate solutions are allowed if they are fun and do not trivialize the lesson.
- Web export smoke test still passes.

Exit criteria:

- Three levels are playable in sequence.

---

### Phase 8 - Content Pipeline and Editor-Lite

**Goal:** Make levels easier to create and iterate.

Options:

- Godot scenes with shared level scripts/resources
- Custom `.tres` level config resources
- JSON level files if external editing becomes useful
- In-game dev overlay/grid
- Hot reload level data during local development
- Screenshot/export of level map
- Simple editor tooling later, but not before core fun is proven

Testing gate:

- Load all levels from the chosen data/pipeline approach.
- Validate level files/resources for:
  - missing spawn
  - missing exit
  - invalid job counts
  - impossible rescue goals
  - missing terrain references
- Adding a basic new level does not require editing engine code.

Exit criteria:

- We can create and iterate levels quickly without corrupting the engine architecture.

---

### Phase 9 - Demo Pack

**Goal:** Build a small demo pack worth sharing with friends/testers.

Content shape:

- 3 tutorial levels
- 4 mechanic-combo levels
- 2 optional bone/charm/relic collectible challenge levels
- 1 capstone level

Testing gate:

- Full demo playthrough on desktop.
- Full demo playthrough in web build.
- Restart/stuck-state pass.
- Browser/device compatibility pass.
- Performance check with max intended skeleton minion count.
- Basic audio/UI/readability pass.

Exit criteria:

- Demo is shippable to friends/testers.

## Risk List

| Risk | Mitigation |
| --- | --- |
| Godot Web export has hosting/header/browser issues | Run Phase 4 early; document export settings and hosting requirements before content expansion |
| Terrain collision becomes fiddly | Start with deterministic sampling; prototype terrain edit API before terrain-heavy levels |
| Browser performance suffers from terrain texture updates | Use chunks/dirty regions; profile Web export during Phase 6 |
| Builder stairs are hard to implement | Define builder output as fixed deterministic stair segments first |
| Physics causes puzzle unpredictability | Avoid rigid-body physics for core skeleton minion movement |
| Asset scope balloons | Use simple readable placeholder/procedural/vector assets first |
| Puzzle levels become too hard | Keep early levels single-concept and allow generous rescue thresholds |
| Cloning too directly | Lean into skeleton minion theme, bone/charm/relic collectibles, cracked stone, bone piles, bats, cobwebs, crypt traps, crumbling masonry, spooky hazards, and undead slapstick problem-solving |

## Recommended First Build Target

Build **Level 1: Bridge School** as the first vertical slice path using:

- Godot 4
- Simple static terrain initially
- One pit
- Walking/falling skeleton minions
- Exit rescue
- Blocker + Builder
- Restart
- Early Web export after the tiny slice works

Postpone Digger/Tunneler and full destructible terrain until after the Level 1 loop and early Web export trial are proven, unless implementation shows Builder should share the terrain editing system immediately.
