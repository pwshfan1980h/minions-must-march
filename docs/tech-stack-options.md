# Minions Must March - Tech Stack Decision

## Decision

Use **Godot 4** for Minions Must March.

Will has used Godot and likes it, which makes Godot the best practical choice despite the earlier Python/pygame-ce exploration. The project benefits from Godot's editor, scene workflow, UI tools, audio pipeline, animation tooling, and export support.

## Key Requirement: Destructible 2D Terrain

Classic Lemmings-style terrain behaves like a mutable bitmap/mask:

- Skeleton minions collide against solid pixels.
- Tools remove or add small regions of terrain.
- Digger/tunneler tool actions carve repeated brush shapes.
- Visual terrain and collision terrain must stay synchronized.

In Godot, the best approach is likely **chunked image terrain with generated collision**, not rigid-body physics.

## Recommended Godot Architecture

### Engine

- Godot 4.x
- GDScript first
- 2D project
- Deterministic custom movement/collision for minions

Avoid trying to make this a generic physics simulation. Lemmings-style behavior should be controlled, readable, and puzzle-deterministic.

## Terrain Strategy

### Preferred: Chunked Bitmap Terrain

Represent terrain as editable image chunks.

Each terrain chunk owns:

1. **Visual image/texture**
   - Stores the current visible terrain pixels.
   - Updated when digging, tunneling, dust-bursting, or building.

2. **Collision data**
   - Generated from the image alpha/solid mask.
   - Used for skeleton minion foot/body checks.
   - May also feed StaticBody2D/CollisionPolygon2D if needed, but custom mask sampling is preferred early.

3. **Dirty region tracking**
   - Terrain edits mark small regions dirty.
   - Only affected chunks/regions update, not the entire level every frame.

### Why Chunks?

Full-level image edits are simple but can become expensive. Chunks keep updates small and make later optimization easier.

Suggested chunk size:

- 128x128 px or 256x256 px
- Start with 256x256 unless performance says otherwise

### Terrain Editing Brushes

Tools apply reusable brush masks:

- Digger: downward repeated shovel/pick/scrape eraser.
- Tunneler: horizontal tunnel eraser in the facing direction.
- Miner: optional diagonal tunnel eraser, later only if useful.
- Burster: circular/irregular dust-burst eraser, postponed.
- Builder: additive stair/plank brush that creates new solid terrain.

Brushes should be authored/generated as small alpha masks.

## Collision Philosophy

Prefer deterministic sampled collision over full physics.

For each minion:

- Sample pixels below feet for support.
- If unsupported, fall.
- If solid pixels ahead at foot/body height, turn around or stop depending on job.
- Snap minion to terrain surface while walking over small unevenness.
- Track fall distance and mark lost/removed if above safe threshold.
- Enter exit if overlapping an exit zone while grounded or near floor.

This better matches classic Lemmings than Godot rigid-body physics.

## Scene Structure Draft

```text
GameRoot
├── LevelController
├── TerrainRoot
│   ├── TerrainChunk...
├── MinionRoot
│   ├── SkeletonMinion...
├── ObjectRoot
│   ├── SpawnEntrance
│   ├── ExitDoor
│   ├── Hazard...
├── Camera2D
└── UI
    ├── JobBar
    ├── RescueCounter
    └── LevelControls
```

## Level Data

Use data-driven level definitions once core behavior exists.

Possible early format:

- Godot scene for hand-authored level layout
- Exported resources for level metadata
- Later: JSON or `.tres` custom resources

Early recommendation:

- Use a Godot scene for Level 1 while prototyping.
- Keep level constants centralized in a `LevelConfig` resource/script.
- Move to reusable level data after mechanics stabilize.

## Asset Strategy

Godot supports either generated or hand-authored assets.

For this project:

- Use procedural/vector/SVG-style art where possible.
- Import SVGs as textures or generate shapes in Godot.
- Keep skeleton minions readable at tiny scale.
- Use simple animated sprites or AnimatedSprite2D once needed.

Early placeholder art:

- Little lanky skeleton minion shapes with skull/limb silhouettes
- Rectangle/painted terrain chunks: cracked stone, crumbly dirt, crypt blocks
- SVG-like spawn arch and glowing crypt portal icons
- Clear job icons

## Testing Plan for Godot

### Automated / Semi-Automated

Godot tests are optional early, but core logic should be separable enough to test.

Useful tests later:

- Brush edit removes/adds expected terrain pixels.
- Collision sampling returns expected solid/empty values.
- Minion movement state transitions: walking, falling, blocked, building, lost, rescued.
- Level config validation catches missing spawn/exit/jobs.

### Manual Test Gates

For Level 1:

- Level loads cleanly.
- Skeleton minions spawn at expected interval.
- Skeleton minions walk and turn predictably.
- Falling/loss threshold feels fair.
- Blocker redirects/stops crowd.
- Builder creates reliable walkable stairs/bridge.
- Level can be won with intended solution.
- Level can be failed without soft-lock weirdness.
- Restart fully resets terrain and skeleton minion state.

## Earlier Considered Option: pygame-ce

pygame-ce remains the best Python-first option for raw bitmap terrain, but Godot is now preferred because:

- Will already knows and likes Godot.
- Godot is better for a polished game workflow.
- Editor tooling, animation, audio, UI, and exports matter for this project.
- GDScript is acceptable if the engine choice improves the final game.


## Export Target: Web

Likely target: **Godot Web export**.

Design implications:

- Prefer Godot features that work reliably in Web builds.
- Keep shaders modest and optional.
- Avoid native plugins or platform-specific APIs.
- Keep save data simple, likely using Godot's user data APIs with browser storage behavior in mind.
- Be careful with large assets; web download size matters.
- Audio should be compressed and tested in browser early because web audio policies can differ from desktop.
- Test Web export regularly, not only at the end.

Technical cautions:

- Godot 4 Web export uses WebAssembly/WebGL and browser compatibility can vary.
- Multi-threading/SAB requirements have historically made web deployment fussier depending on Godot version and hosting headers.
- GitHub Pages can work if the chosen Godot version/export settings do not require special cross-origin isolation headers; otherwise another static host with header control may be needed.
- Terrain performance should be profiled in browser, especially image updates and texture uploads.

Recommendation:

Once Level 1 runs on desktop, create an early Web export smoke test before expanding content. Do not wait until the game is large.

## Early Vertical Slice Web Trial

Plan an early vertical slice trial that proves the full loop in-browser, not just desktop.

Minimum slice:

- One tiny playable level
- Spawn entrance and exit
- Walking/falling skeleton minions
- At least one assignable job, preferably Builder
- Basic UI/job selection
- Restart
- Win/loss state
- Web export deployed somewhere Will can open by LAN/public URL

Success criteria:

- Loads in a browser without manual setup
- Plays at acceptable framerate
- Input works correctly
- Audio, if present, starts/behaves acceptably under browser rules
- Restart fully resets terrain/skeleton minions
- No export-only crashes or broken assets

This trial should happen before adding many levels, jobs, or polished art. The goal is to prove Godot Web export, project structure, input, asset import, and runtime performance while the game is still small enough to fix cheaply.

## Current Recommendation

Build the first prototype in **Godot 4**.

Start with **Level 1: Bridge School** and implement only:

- Spawn entrance
- Walking skeleton minions
- Terrain support/collision sampling
- Falling/loss
- Exit rescue
- Blocker
- Builder
- Restart

Do not implement full destructible terrain until Level 1 movement and builder feel good, unless we discover builder depends on the same terrain-editing system.
