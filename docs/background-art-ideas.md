# Background Art Ideas

## Direction

The upper screen should feel like a deep underworld space, not empty UI padding. Keep details faint, atmospheric, and behind gameplay readability.

## Ideas

- Layered cavern ceiling with jagged stalactites.
- Huge rib/bone arches embedded in dark rock.
- Distant underworld structures: obsidian towers, necropolis silhouettes, broken bridges.
- Faint structures with portals and spooky green/yellow light leaking out.
- Silhouettes of twisted treetops or dead cypress against a crimson sky.
- Soul motes and ghost wisps drifting upward from the Styx.
- Far-off ferryman silhouette or tiny boat shape crossing mist.
- Giant skull-shaped mountain face or carved judgment arch in the distance.
- Chained bureaucratic underworld signs: PROCESSING, PIT 7, NO REFUNDS.
- Spawn-side crypt chute / bone pipe visual in the background.
- Exit beam reaching upward toward a cracked heavenly opening.

## First Implementation Slice

Start with atmospheric parallax elements that add mood without gameplay clutter:

1. Crimson upper-sky gradient behind everything.
2. Faint black/deep-purple treetop silhouettes along the upper horizon.
3. Distant underworld tower/crypt silhouettes.
4. Two or three portal structures with dim green/yellow glow.
5. A few slow soul motes/wisps, subtle and low contrast.
6. Wider first-level span with manual camera pan to test scrolling/action readability.
7. Larger background set pieces across the scroll: skull mountain, rib arches, more portals, and broken bridges.

## Prototype Navigation

- Current test controls: `A/D`, `Left/Right`, or `Z/X` pan the camera horizontally.
- Start camera near the spawn side so the player sees skeletons enter, then can pan left toward the exit.
- This is intentionally simple manual camera control; later options include auto-following the skeleton crowd, edge scrolling, drag-to-pan, or snapping between points of interest.

Avoid interactive-looking detail for now. The player should instantly know these are background flavor, not tools or hazards.
