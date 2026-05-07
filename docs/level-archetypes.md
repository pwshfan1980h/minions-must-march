# Minions Must March - Level Archetypes

This file normalizes early puzzle design around reusable challenge atoms. The goal is to make level creation feel like combining clear ingredients instead of inventing every puzzle from scratch.

## Design Targets

- **Readable first:** the player should understand spawn, direction, hazard, exit, and likely tool within a few seconds.
- **One primary lesson per early level:** add complexity by remixing known atoms, not by hiding the point.
- **Forgiving rescue thresholds:** early levels should allow mistimed clicks and a few soggy skeletons.
- **Underworld identity:** each level should sit in a biome palette, not a generic platformer void.
- **Tool icon economy:** HUD can stay compact if the board and level intro communicate goals clearly.

## Biome Palette Lanes

| Biome | Mood | Main colors | Gameplay fit |
| --- | --- | --- | --- |
| Styx Marsh | wet, haunted, rotten | black-brown, sickly green, bone white | first hazards, soup gaps, portals |
| Crypt Forge | hot, industrial, infernal | ember orange, soot black, iron blue | builder-heavy levels, moving/metal future bits |
| Soul Cavern | spectral, vertical, airy | teal, violet, ghost pale | uplifts, shafts, falling routes |
| Ash Catacombs | dusty, brittle, tomb-like | ash gray, dried blood red, candle gold | dig/tunnel teaching, crumble floors |
| Bone Gardens | weird, organic, ossuary | ivory, moss green, muted purple | blockers, path pruning, creature-ish terrain |

## Challenge Atoms

### Portal Start

- **Purpose:** let the player study the board before pressure begins.
- **Signal:** pulsing spawn portal waits for click.
- **Combines with:** everything.

### Reverse Flow

- **Purpose:** teach blocker as traffic control, not just a wall.
- **Shape:** skeletons enter a lower lane facing danger; blocker reverses them toward exit or builder setup.
- **Failure:** no blocker means the crowd walks into Styx/dead end.

### Builder Gap - Flat

- **Purpose:** simplest Builder read.
- **Shape:** same-height gap, clear landing platform.
- **Tuning:** one builder should cross with generous overlap.

### Builder Gap - Up

- **Purpose:** teaches rib bridge as staircase.
- **Shape:** landing is slightly above source platform.
- **Tuning:** needs smooth vault/step-up behavior; gap should be short while animation is young.

### Builder Gap - Down

- **Purpose:** easier recovery / confidence builder.
- **Shape:** landing is slightly below source platform.
- **Tuning:** forgiving; useful after a harder level.

### Island Staging

- **Purpose:** teaches multiple builders and mid-gap planning.
- **Shape:** two short gaps split by safe island.
- **Failure:** spending both builders from the wrong side leaves crowd stranded.

### Delayed Release

- **Purpose:** blocker holds crowd while one worker prepares the path.
- **Shape:** builder skeleton passes/works while crowd is contained.
- **Needs:** blocker release must feel reliable.

### Safe Drop

- **Purpose:** teach falling without immediate punishment.
- **Shape:** short drop to lower platform.
- **Combines with:** Reverse Flow, Builder Up/Flat.

### Fatal Drop / Soup Panic

- **Purpose:** create urgency and make hazards legible.
- **Shape:** march path points directly toward Styx or lethal fall.
- **Tuning:** early levels should allow visible failure without instant restart.

### Crumbly Floor Dig

- **Purpose:** future Digger introduction.
- **Shape:** obvious patched floor over lower safe route.
- **Rule:** dig patch should be wide and visually loud.

### Crumbly Wall Tunnel

- **Purpose:** future Tunneler introduction.
- **Shape:** exit behind cracked side wall.
- **Rule:** direction matters, but placement should not be pixel-perfect.

## Recommended Early Campaign Arc

1. **Portal + Builder Flat** — one skeleton, no crowd pressure.
2. **Reverse Flow + Builder Up** — blocker sends crowd back; builder creates a rising stair.
3. **Builder Down Recovery** — easier bridge after a tougher puzzle.
4. **Island Staging** — two builders, two gaps, safe middle.
5. **Safe Drop + Reverse Flow** — fall down a flight, blocker reverses, builder crosses.
6. **Delayed Release** — crowd management while a worker builds.
7. **Crumbly Floor Dig** — introduce Digger in Ash Catacombs.
8. **Crumbly Wall Tunnel** — introduce Tunneler.

## Preview Export Workflow

Level preview data lives in `docs/level-preview-data.json`.

Run:

```bash
godot --headless --path . -s scripts/tools/export_level_previews.gd
```

The exporter writes board mockups to `docs/level-previews/*.png`. These are intentionally schematic: terrain blocks, Styx, spawn portal, exit light, arrows, and tool markers. They are for level discussion before full scene implementation.
