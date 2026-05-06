# Minions Must March - Starter Levels

These are the first three paper-designed puzzle levels. Level 1 should be built and polished first before implementing Levels 2 and 3 deeply.

## Shared Early Assumptions

- Grid: 40 columns x 19 playfield rows, 32px tiles, with bottom UI bar.
- Skeleton minions walk automatically.
- Direction reverses on wall/blocker.
- Safe fall limit: about 3 tiles.
- Early levels avoid heavy timing precision.
- Rescue thresholds allow mistakes.
- Jobs lean into skeleton logic: brace/block, build with planks/bones, dig downward, tunnel sideways.

---

## Level 1 - Bridge School

### Purpose

Teach the basic flow-control pattern:

- Stop the crowd.
- Send/build a path over danger.
- Release or route the crowd to the exit.

### Difficulty

Easy tutorial. Intended as first polished vertical slice.

### Mechanics Required

- Walking
- Falling/loss from pit or hazard
- Blocker
- Builder
- Exit rescue
- Restart

### Level Concept

A cracked spawn arch sits on the upper-left crypt platform, with bats/cobwebs as background ambience. Skeleton minions march right toward a gap. The glowing exit crypt/portal is on a platform to the right, slightly lower or same height. The player must place a blocker before the pit, then assign builders to create a bridge across the gap.

### Suggested Parameters

- Minions: 20
- Rescue required: 12
- Spawn interval: 1.0 sec
- Jobs:
  - Blocker: 2
  - Builder: 4
- Hazards: pit, optional spikes at bottom for readability

### Rough Layout

```text
........................................
........................................
...S>>>>>>>>>>>>>>......................
##################....################..
......................#..............#..
......................#..............#..
......................#..............E..
......................################..
........................................
.................^^^^...................
########################################
```

Legend:

- `S` spawn arch
- `E` exit crypt / portal
- `#` solid terrain
- `.` air
- `^` spikes/loss pit
- `>` intended walking direction

### Intended Solution

1. Let the first few skeletons approach the gap.
2. Place a blocker before the pit to stop the crowd.
3. Assign one or more builders facing right to bridge the gap with planks/bone steps.
4. Once bridge reaches the far platform, release or route the remaining minions to the exit.

### Notes

If blocker removal is not implemented, design the blocker placement so it does not permanently trap everyone. Options:

- Allow the builder to be assigned before placing blocker, with blocker behind builder.
- Use two lanes where blocker redirects the crowd later.
- Add a simple “release blocker” command early.

Recommended MVP solution: allow clicking an existing blocker to release/cancel it. This makes early teaching much cleaner.

### Test Checklist

- Can win using only blocker + builder.
- Can lose by not blocking/building.
- Builder bridge is reliably walkable.
- Rescue threshold tolerates a few early losses.
- No precise frame-perfect assignment required.

---

## Level 2 - Basement Shortcut

### Purpose

Teach digging downward to reach a lower route safely.

### Difficulty

Easy-medium. Introduces vertical terrain modification.

### Mechanics Required

- Digger
- Blocker or flow control
- Safe/unsafe fall handling
- Possibly builder, but use sparingly

### Level Concept

The obvious top route leads to a dangerous drop or dead-end wall. The exit is in a lower crypt chamber lit by candles/ghost light. The player must stop the crowd, choose a safe dig spot, and create a vertical shaft into the lower tunnel.

### Suggested Parameters

- Minions: 25
- Rescue required: 16
- Jobs:
  - Blocker: 2
  - Digger: 2
  - Builder: 1 optional safety tool

### Rough Layout

```text
........................................
...S>>>>>>>>>>>>>>>>>>>>>>>.............
###############################.........
.................DDDDDD................
.................DDDDDD................
.................DDDDDD....############
.................DDDDDD....#..........E
.................DDDDDD....############
.................#######...............
.....................^^^^..............
########################################
```

Legend:

- `D` diggable dirt/crumbly floor zone
- `^` spikes/dangerous pit

### Intended Solution

1. Block the crowd before the bad end/drop.
2. Assign a digger at the marked crumbly floor section.
3. Skeleton minions drop into lower corridor safely.
4. They walk right to the exit.

### Design Notes

- Keep the dig spot visually obvious with crumbly dirt/stone texture.
- Shaft drop must be within safe fall threshold or include a small lower platform.
- Avoid requiring exact pixel-perfect dig placement.

### Test Checklist

- Digger removes terrain straight downward.
- Digger stops correctly on reaching air/lower chamber.
- Minions transition from shaft to floor cleanly.
- Bad route fails visibly.
- Correct route is discoverable from terrain cues.

---

## Level 3 - Side Tunnel

### Purpose

Teach sideways tunneling through diggable terrain.

### Difficulty

Medium-light. Distinct from Levels 1 and 2 by focusing on horizontal terrain modification.

### Mechanics Required

- Blocker
- Tunneler
- Direction reversal
- Maybe builder as a recovery/safety tool

### Level Concept

Skeleton minions spawn on a path that loops toward danger or a dead end. The exit is behind a crumbly crypt wall, with cracks/cobwebs telegraphing that it can be tunneled. The player must control the crowd, assign a tunneler facing the right direction, and open a horizontal side passage through the marked diggable terrain.

### Suggested Parameters

- Minions: 30
- Rescue required: 20
- Jobs:
  - Blocker: 3
  - Tunneler: 2
  - Builder: 1 optional recovery tool

### Rough Layout

```text
........................................
.........................E..............
.....................DDDDDDDD..........
.....................DDDDDDDD..........
...S>>>>>>>>>>>>.....DDDDDDDD.........#
################.....DDDDDDDD.........#
...............#......................#
...............#......................#
...............########################
........................................
########################################
```

Legend:

- `D` sideways diggable dirt/crumbly wall
- `E` exit crypt / portal

### Intended Solution

1. Skeleton minions spawn right and approach a far wall or danger route.
2. Player uses blocker placement to hold or reverse the crowd.
3. Assign a tunneler facing toward the marked crumbly wall.
4. Tunneler opens a side passage into the exit chamber.
5. Release/route the crowd into the shortcut.

### Alternate Builder Version

If Tunneler is not ready when this level is first tested:

- Use walls/blockers to reverse the crowd.
- Builders create a ramp/path up to the exit platform.
- Revisit the level after Tunneler exists.

### Design Notes

This level should feel like “aha, skeletons can open side passages,” not like a precision trap.

### Test Checklist

- Direction reversal is obvious and reliable.
- Tunneler moves horizontally in the facing direction.
- Tunneler stops at air/indestructible terrain correctly.
- Player has enough blockers to recover from one mistake.
- The intended route is not hidden behind unintuitive terrain.
- Level remains solvable without split-second timing.

---

## Recommended Build Order

1. Implement Level 1 only.
2. Polish Level 1 until controls, collision, and builder feel good.
3. Add Digger in a small mechanic sandbox, then Level 2.
4. Add Tunneler in a small mechanic sandbox, then Level 3.
5. Adjust docs before building Levels 2 and 3 in full.
