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
- Enters exit if overlapping/standing at the exit light pillar/safe ascent zone.

Recommended prototype numbers:

- Speed: 32-48 px/sec
- Spawn interval: 0.75-1.25 sec
- Safe fall: 3-4 tiles
- Skeleton body: about 0.45-0.55 tile wide, 0.8-0.95 tile tall

Design note:

Lanky skeleton minions support the job fantasy well: they can brace as blockers, carry bone/plank bridge pieces, scrape downward as diggers, tunnel sideways through crumbly soil, and comically fall apart when lost.



## Exit / Rescue Fantasy

The level exit should be a vertical pillar of soft light leading upward. Motes of light drift slowly upward through and slightly beyond the pillar, then fade out. Skeletons that reach it walk into the light, float upward, glow, and dissolve/disintegrate out of the level.

Design intent:

- The feel is loosely inspired by familiar pop-culture afterlife/underworld imagery, but the game should avoid explicit specific doctrine or real-world belief labels in docs, UI, and level text.
- The exit should contrast the River Styx: water pulls down and fades skeletons into the underworld; the exit lifts them up and fades them into safety.
- The pillar must remain readable as the goal at tiny scale. Use motion, light, and motes rather than complex symbols.

## Death and Hazard Feedback

Deaths should carry a reason so visuals, scoring, audio, and future tutorial text can react correctly. Current implemented/expected death kinds:

- `fall`: generic lethal fall or off-world loss. Spawn bone splash, count lost, remove the skeleton.
- `styx_water`: bottom River Styx hazard. Trigger death feedback immediately, snap/settle the skeleton to the water surface, spawn bone splash, then squash slightly and fade/sink the skeleton before counting it lost. This should feel like thick underworld soup reclaiming the minion, not like a sharp trap.

Design intent:

- Keep bone splash as the common comedic failure language.
- Death audio should start when the death begins, not when cleanup finishes.
- Let death-specific treatments layer on top: water impact/fade/sink now; crusher flattening, glimmer ash, acid bubbles, etc. later if needed.
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

Creates a deterministic short bridge/stair in the minion's current facing direction.

Theme:

- Places planks, rib-bone steps, tombstone slabs, or scrap dungeon boards.

Purpose:

- Cross gaps
- Reach slightly higher platforms
- Teach controlled route repair without introducing destructible terrain yet

#### Builder v0 Locked Behavior

Assignment constraints:

- Can be assigned only to an alive, unrescued, non-blocker skeleton that is currently standing on solid ground.
- Cannot be assigned while the skeleton is falling, sinking, already building, or already rescued/lost.
- Assignment consumes one Builder charge immediately. If the assignment is invalid, no charge is consumed.
- Builder v0 does **not** cancel/replace Blocker; if a skeleton is already a Blocker, clicking it keeps the current Resume March behavior rather than converting it to Builder.

Build output:

- Builds **6 simple scene collision pieces** in the skeleton's facing direction.
- Each piece is a `StaticBody2D` rectangle, **28 px wide x 8 px tall**.
- Pieces are offset by **24 px horizontally** and **8 px upward** from the previous piece, forming a short rib-bone stair/bridge.
- Total reach is roughly **144 px horizontally** and **48 px upward**, enough to prove the mechanic but not enough to solve every future gap.
- Pieces use placeholder bone/crypt-scrap visuals and should live in a dedicated build-piece parent/root so they can be cleared on restart.

Builder timing/state:

- On assignment, the skeleton stops horizontal walking and enters `builder` state.
- It places one piece every **0.18 seconds**.
- After placing the final piece, it resumes normal walking in the same direction.
- The builder itself should not teleport onto the new stair; normal gravity/collision decides whether it steps onto the pieces.

Failure/stop rules:

- Before placing each piece, v0 checks a simple overlap region for existing solid geometry or level bounds.
- If the next piece would overlap existing solid geometry, leave the already-placed pieces, stop building, and resume walking. This keeps the first implementation forgiving and deterministic.
- If the piece would be outside the playable width, stop building and resume walking.
- Builder v0 does not interact with River Styx water, erase hazards, or modify bitmap terrain. It only adds scene collision pieces above the water.

Implementation choice:

- Builder v0 should use scene collision pieces, **not** the future destructible-terrain API. This avoids blocking on Phase 6 terrain work and gives Session B a compact implementation target.

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
- Light pillars, cursed sigils, ghost light, cursed light traps
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
- Cursed light/sunbeam traps
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
- Skeleton theme should support the mechanic feel: marching, bracing, building, digging, tunneling, rattling apart, and reaching a safe light pillar.
