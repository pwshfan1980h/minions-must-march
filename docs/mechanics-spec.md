# Minions Must March - Mechanics Spec

## Core Loop

1. Skeleton minions spawn from an entrance at a fixed rate.
2. They walk forward automatically with very limited self-preservation.
3. They obey gravity and terrain collision.
4. The player assigns limited jobs to individual minions.
5. Jobs alter movement, terrain, or survival.
6. The level ends when all minions are rescued, lost, shattered, or no longer able to satisfy the rescue goal.

## Win/Loss

Each level defines:

- Total minions
- Required rescued count or percentage
- Available job counts
- Spawn rate
- Optional time limit, likely postponed
- Optional bone/charm/relic bonus goals

Recommended early thresholds:

- Tutorial: save 50-60%
- Easy: save 60-70%
- Medium: save 70-80%
- Challenge: save 80%+ and optional collectibles

## Minion Rules

### Baseline Skeleton Minion

- Little, lanky skeleton body; readable silhouette matters more than anatomy.
- Walks horizontally at constant speed.
- Turns around when hitting solid wall or blocker.
- Does **not** detect ledges or self-preserve; if terrain ends, it walks off.
- Falls under gravity.
- Is lost/shattered if fall distance exceeds safe threshold.
- Is lost to the River Styx if it falls into the bottom underworld-water layer; this uses the same bone-splash feedback plus a short fade/sink treatment.
- Enters exit if overlapping/standing at the exit portal/safe crypt door.

Recommended prototype numbers:

- Speed: 32-48 px/sec
- Spawn interval: 0.75-1.25 sec
- Safe fall: 3-4 tiles
- Skeleton body: about 0.45-0.55 tile wide, 0.8-0.95 tile tall

Design note:

Lanky skeleton minions support the job fantasy well: they can brace as blockers, carry bone/plank bridge pieces, scrape downward as diggers, tunnel sideways through crumbly soil, and comically fall apart when lost.


## Death and Hazard Feedback

Deaths should carry a reason so visuals, scoring, audio, and future tutorial text can react correctly. Current implemented/expected death kinds:

- `fall`: generic lethal fall or off-world loss. Spawn bone splash, count lost, remove the skeleton.
- `styx_water`: bottom River Styx hazard. Trigger death feedback immediately, snap/settle the skeleton to the water surface, spawn bone splash, then squash slightly and fade/sink the skeleton before counting it lost. This should feel like thick underworld soup reclaiming the minion, not like a sharp trap.

Design intent:

- Keep bone splash as the common comedic failure language.
- Death audio should start when the death begins, not when cleanup finishes.
- Let death-specific treatments layer on top: water impact/fade/sink now; crusher flattening, holy ash, acid bubbles, etc. later if needed.
- Avoid creating many hazards early. The River Styx bottom boundary should carry most first-wave “you failed to bridge/control the crowd” feedback.

## Job Set

### Blocker

Stops walking and blocks/redirects other minions.

Theme:

- Plants feet wide, braces with a shield/bone sign, or holds arms out in a bony “nope” pose.

Purpose:

- Control flow
- Prevent the crowd from walking into danger
- Create timing windows

Early rule:

- Permanent until level ends or removed/released by player.
- Occupies approximately one minion width.

### Builder

Creates a fixed upward stair/bridge segment in the facing direction.

Theme:

- Places planks, rib-bone steps, tombstone slabs, or scrap dungeon boards.

Purpose:

- Cross gaps
- Reach higher platforms

Early rule:

- Builds N stair pieces, then resumes walking.
- Can fail/stop if head hits ceiling or no valid placement exists.

Prototype builder output:

- 8-12 steps
- Each step roughly half-tile wide and quarter-tile high, or simplified to tile-aligned diagonal ramp segments.

### Digger

Digs vertically downward through diggable terrain.

Theme:

- Scrapes downward with a shovel, pick, or frantic bony hands.

Purpose:

- Create vertical shafts
- Access lower routes

Early rule:

- Only affects marked diggable terrain at first.
- Stops when reaching air, indestructible terrain, dangerous terrain, or player cancel if cancellation exists.

### Tunneler

Tunnels horizontally through diggable terrain.

Theme:

- Scrapes/chisels sideways through dirt, cracked stone, or crumbly crypt wall.

Purpose:

- Open side passages
- Create shortcuts
- Redirect the marching crowd into hidden routes

Early rule:

- Only affects marked diggable terrain at first.
- Moves/works horizontally in the facing direction.
- Stops at air, indestructible terrain, dangerous terrain, or after max tunnel length.

### Floater / Cloak Glider

Survives long falls.

Theme:

- Uses a ragged cloak, spectral sheet, bat-wing umbrella, or parachute charm.

Purpose:

- Let selected scouts survive routes others cannot.

Postponed until after first polished level unless needed.

### Boneburst / Sacrifice Tool

Sacrifices self to remove nearby terrain.

Theme options:

- Cartoon bone-rattle burst
- Necromantic pop
- Spinning skeleton drill gag

Purpose:

- Emergency terrain clearing
- Optional late-game puzzle tool

Postponed. Use carefully because sacrifice mechanics can make puzzles feel mean or timing-heavy.

## Theme Palette

Primary setting ingredients:

- Crumbling crypts and catacombs
- Bats, cobwebs, candles, skull piles, bones, broken coffins
- Cracked stone, crumbly dirt, collapsed masonry, rusty gates
- Portals, cursed sigils, ghost light, holy wards
- River Styx / underworld water as the first bottom-boundary hazard: brownish-black water, pale souls, faint fog, and sink/fade deaths

Use these as flavor and visual cues first. Do not turn ambient bats/spiders into gameplay hazards until the core jobs are proven.

## Terrain Types

### Solid

Blocks movement and supports minions.

### Diggable

Can be modified by digger/tunneler/boneburst.

### Indestructible

Blocks movement and cannot be modified.

### Hazard

Shatters/loses minions on contact. The first visual hazard direction is **River Styx / underworld water** at the bottom of the level: pitch brownish-black animated water with pale souls drifting in it. When skeletons fall in, they spawn the bone-splash effect, then fade/sink away.

Other later examples:

- Spikes, if a sharper trap read is needed later
- Lava or acid slime
- Crusher blocks
- Holy wards/sunbeams
- Bottomless pits
- Crypt traps
- Crumbling floors
- Cursed thorns, if visually useful

Prefer hazards that read clearly at small size and match the underworld crypt tone.

## Level Data Needs

A level should eventually define:

```json
{
  "id": "level-001",
  "name": "Bridge School",
  "size": { "width": 40, "height": 23 },
  "spawn": { "x": 3, "y": 4, "direction": "right", "count": 20, "interval": 1.0 },
  "exit": { "x": 35, "y": 18 },
  "rescueRequired": 12,
  "jobs": { "blocker": 2, "builder": 4 },
  "terrain": [],
  "hazards": {
    "bottom": "styx_water"
  }
}
```

Current prototype has already started representing bottom hazards as `{"bottom": "styx_water"}` in Level 1 data. Actual schema can change once level loading becomes more formal, but keep death kinds explicit rather than hardcoding every loss as a generic fall.

## Design Philosophy

- Early puzzles should teach one idea at a time.
- The intended solution should be visible after experimentation.
- Failure should be funny, fast, and restartable, not cruel.
- Timing precision should be low in early levels.
- Rescue thresholds should allow a few mistakes.
- Skeleton theme should support the mechanic feel: marching, bracing, building, digging, tunneling, rattling apart, and reaching a safe crypt/portal.
