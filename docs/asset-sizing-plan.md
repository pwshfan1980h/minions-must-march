# Minions Must March - Asset & Sizing Plan

## Target Format

Assumption: Godot 4 project with likely Web export.

Recommended base viewport:

- 1280x720 logical pixels for widescreen
- 16:9 layout
- Scales down to 960x540 and up to 1920x1080

Recommended world grid:

- 40 columns x 22 or 23 rows at 32px tiles gives about 1280x704/736
- Alternative: 32 columns x 18 rows at 40px tiles gives 1280x720

Recommendation for prototype:

- Use **32px tiles** for easier level design and classic puzzle density.
- Keep UI as overlay/bottom bar, or reserve lower 96px and use a 1280x624 playfield.

## Candidate Layouts

### Layout A - Full Playfield with Overlay UI

- Viewport: 1280x720
- Grid: 40x22.5-ish using 32px tiles
- UI floats at bottom/top

Pros:

- More vertical room for puzzles
- Better classic Lemmings feel

Cons:

- UI may obscure playfield unless carefully handled

### Layout B - Reserved Bottom Job Bar

- Total viewport: 1280x720
- Playfield: 1280x608
- Bottom UI: 1280x112
- Grid: 40x19 playfield tiles

Pros:

- Clean UI
- Predictable click zones

Cons:

- Less vertical level space

Recommendation: **Layout B** for clarity.

## Prototype Sizing

- Tile: 32x32 px
- Skeleton minion body: roughly 14-18 px wide and 24-30 px tall
- Entrance: 64x64 px
- Exit/safe crypt door/portal: 64x64 px
- Job icon: 48x48 px
- Hazard tile: 32x32 px
- Builder step: 16x8 px or tile-aligned stair blocks

## Visual Direction

The game should read as **spooky-cute crumbling crypt puzzle chaos**.

Core feel:

- Little lanky skeleton minions
- Funny, rattly, slightly spooky but not grim
- Crumbling crypts, cracked stone, dusty catacombs, old tombs, collapsed masonry
- Bats, candles, cobwebs, loose bones, skull piles, broken coffins, rusty gates
- Blue-green ghost light, warm candle accents, deep purples/grays, black-to-grey crypt gradients, bone-white silhouettes
- Pitch brownish-black underworld water with pale souls/fog as the first bottom hazard, replacing generic spike floors for Level 1 tone
- Clear danger with a playful tone
- Tiny undead workers doing questionable civil engineering

Theme pillars:

- **Crumbling crypts:** cracked blocks, collapsing ledges, broken arches, dusty tomb passages.
- **Spooky critters:** bats as background motion, rats/spiders as optional ambience, not core mechanics at first.
- **Necromantic machinery:** portals, sigils, cursed switches, bone elevators/crushers later if useful.
- **Readable slapstick danger:** spikes, crushers, acid slime, holy wards, unstable floors.

## SVG / Procedural Asset Strategy

### Skeleton Minions

Start with simple SVG/procedural shapes:

- Round skull with readable eye holes
- Thin rib/body shape
- Long skinny arms and legs
- Slight hunch or bob while walking
- Two-frame walk animation via leg/arm offsets
- Optional jaw chatter/bone rattle effect
- Job state overlay: hardhat, sign, plank bundle, shovel/pick, dust trail, cloak glider

Potential job silhouettes:

- Blocker: wide braced stance, shield, or STOP bone sign
- Builder: plank/rib-bone stair piece
- Digger: shovel/pick + downward arrow/dirt spray
- Tunneler: side arrow + cracked wall/tunnel dust
- Floater: ragged cloak, spectral sheet, or bat-wing umbrella
- Boneburst: rattling bone cloud, if used later

### Terrain

Generate from rectangles/tiles first:

- Stone blocks with cracks and color variation
- Dirt/diggable tiles with speckles and bone fragments
- Crumbly crypt wall for tunnelable zones
- Indestructible black basalt, metal trim, or magic-warded stone
- Background parallax optional later: ruined crypt walls, bat silhouettes, moonlit catacombs, dangling chains, candles, cobwebs

### Hazards

SVG/procgen:

- Spikes: repeated triangles
- Lava/acid slime: bright pool with warning edge
- Crushers: block with teeth, animation later
- Holy wards/sunbeams: glowing danger strip
- Bottomless pits, cursed thorns, unstable crumbling floors if useful

Use shape/pattern strongly so hazards are readable even without color.

### UI

SVG icons can be generated from simple primitives.
Need strong silhouettes more than detailed art.

Suggested first UI icons:

- Blocker: braced skeleton / stop sign
- Builder: stair plank/bone
- Digger: down arrow + shovel
- Tunneler: side arrow + cracked wall
- Restart: circular arrow
- Rescue: crypt door/portal icon

## Readability Rules

- Spawn entrance and exit/safe crypt must be visually distinct.
- Hazards must be obvious at a glance; Styx water should read as a no-go bottom boundary through motion, darkness, and ghost/soul accents.
- Diggable vs indestructible terrain must differ clearly.
- Assigned job minions need clear visual state.
- Do not rely only on color; use shape/pattern too.
- Skeletons must stay readable at tiny scale: skull/limb silhouette first, details second.

## Open Questions

- Exact Godot 4 version to target for Web export.
- Pixel-art look, crisp vector look, or hybrid?
- Should terrain start tile-grid only, image-mask based, or static rectangles before destructible terrain?
- How spooky versus goofy should the skeleton tone be?

## Recommendation

For fastest proof:

- Godot 4 + GDScript
- 2D scenes with deterministic custom movement/collision
- Simple static terrain first
- SVG/procedural placeholder skeleton minions and terrain
- Level 1 with Blocker + Builder
- Early Web export trial before content expansion

Do not add full physics simulation until/unless needed. Tiny skeleton minions and terrain tools are easier to control with deterministic custom grid/mask collision rules.
