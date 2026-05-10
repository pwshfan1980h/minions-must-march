# Minions Must March — Level Plans v1

These are concrete, implementable plans for the first batch of levels. They assume the v0 mechanics now in `main`:

- Walking + falling + Styx soup-line death
- Blocker (clickable, can resume-march)
- Builder (six-piece sloped rib bridge, ~18° rise, anti-skate ramp)
- Crumbling terrain (Area2D-triggered, 15–30s fuse with intensifying warning cracks)
- Three skeleton body archetypes (Tall / Stocky / Wiry) with matching gaits

Implementation status legend: ✅ shipped · 🟡 designed, ready to build · ⚪ paper-only

The first three levels stay easy on purpose — each one introduces exactly one new mechanic and lets the player learn it without time pressure. From L004 onward we start chaining mechanics into actual logic puzzles.

---

## L001 — Bone Bridge ✅

**Status:** Implemented (current `main`).

- **Biome:** Styx Marsh
- **Primary lesson:** assign Builder to bridge a small Styx gap; place Blocker to dam the crowd until the bridge is ready.
- **Jobs:** Blocker × 2, Builder × 2
- **Skeletons:** 20, save 16
- **Core atoms:** Portal Start, Builder Gap — Up, Delayed Release, Slow Crumbler

**Layout (world coords, y down):**
- Spawn portal at `(220, 420)` facing right.
- Left platform `[160→800] × [448→480]`, leftmost slice `[160→216]` is a crumbler (lip).
- Two skull-pillar supports at `(128, 480)` and `(800, 480)`.
- Styx gap at `[800 → 912]`, 112px wide.
- Right platform `[912→1392] × [400→432]`, with a crumbler chunk at `[1072→1168]` (96px) just before the exit.
- Two skull-pillar supports under the right platform at `(912, 432)` and `(1360, 432)`.
- Exit light pillar at `(1210, 400)`.

**Intended solution:**
1. Click portal → crowd starts walking right.
2. Place blocker just before the gap (left platform, x ≈ 760).
3. Click a right-facing skeleton between the blocker and the spawn → Builder, throws six rib bones into a sloped bridge across the gap.
4. Click the blocker again → Resume March, refunds the charge.
5. Crowd flows over the bridge, across the right platform, into the exit. Crumbler near the exit fuses on first weight; if the player dawdles, the section drops into Styx.

**Failure modes:**
- Skip blocker → 1–3 skeletons fall into Styx before bridge is built.
- Builder placed too late → bridge starts past the gap, skeletons fall in.
- Crowd lingers on the right-platform crumbler → it fuses, drops some skeletons.
- Place blocker on the left lip → crumbler activates, can lose redirected skeletons.

**Tuning notes:** rescue threshold 16/20 leaves room for 4 losses; the right-platform crumbler typically eats 0–2.

---

## L002 — The Crumblepath 🟡

**Status:** Designed.

- **Biome:** Styx Marsh
- **Primary lesson:** crumbling sections are time pressure — once the first skeleton steps on, you have ~20s before that chunk falls. Move the crowd through quickly.
- **Jobs:** Blocker × 1, Builder × 1
- **Skeletons:** 20, save 14
- **Core atoms:** Portal Start, Builder Gap — Flat, Multi-Crumbler Path

**Layout (sketch):**
```
.S>>>>>>>>>....>>>>>>>>>>>>>>>>>>>>>>>>...........
##########____##########..############..########E#
                  ↑      ↑              ↑
              crumbler  Styx gap     crumbler
```
- Single long platform broken by **one Styx gap** roughly 96px wide.
- Three crumbling segments staggered along the path: one *before* the gap (close to spawn), one immediately after the gap on the landing platform, and one in the final stretch before the exit.
- The crumbler closest to the spawn has the shortest natural fuse (player triggers it earliest — they’ll see it activate first).
- Exit on the far right, same elevation as spawn (no climb).

**Intended solution:**
1. Click portal. Crowd marches right onto the first crumbler — fuse starts almost immediately.
2. Place blocker just before the gap to dam the crowd while the bridge goes up.
3. Promote a builder facing right to lay the bridge.
4. Resume the blocker the **moment** the bridge lands — every second on the first crumbler is a second closer to losing the lip.
5. Crowd flows fast across the bridge, onto the second crumbler (its fuse just started), then across the third before any of them go.

**Failure modes:**
- Slow build → first crumbler drops part of the queued crowd.
- Late resume → crowd crosses too slowly, post-bridge crumbler eats stragglers.
- Resume too early (before bridge complete) → skeletons walk off into Styx.

**Tuning targets:**
- First crumbler fuse: 12–16s (force urgency).
- Other two crumblers: 18–28s (forgiving once you’re already moving).
- Rescue 14/20 — accepts ~6 losses, since timing-based puzzles need slack.

---

## L003 — Turn, You Fools 🟡

**Status:** Designed.

- **Biome:** Styx Marsh
- **Primary lesson:** Blocker reverses crowd direction. Spawn intentionally faces them at a hazard; the player has to redirect.
- **Jobs:** Blocker × 1, Builder × 0
- **Skeletons:** 18, save 15
- **Core atoms:** Portal Start (Reversed), Reverse Flow

**Layout:**
```
~~Styx~~                          ___________E
              S<<<<<<<<<<<<<<<<<<<##########
                                  ↑
                              spawn here, walking left toward soup
```
- Spawn portal in the middle, facing **left**. The left edge of the platform drops directly into Styx — a death trap if untouched.
- Exit is to the right, on the same platform, no gap.
- No builder needed (no gaps) — just one blocker.
- One small crumbler on the right approach to the exit, as a soft surprise (won’t kill anyone if the crowd moves normally).

**Intended solution:**
1. Click portal — the first skeleton walks left toward the cliff.
2. Place a blocker on the left side of the spawn (between spawn and the cliff). Skeletons hit the blocker, turn around, walk right.
3. Crowd reaches the exit. Done.

**Failure modes:**
- Wait too long to place blocker → first 1–3 skeletons fall.
- Misread direction and place blocker on the right side → crowd marches off the left cliff.
- Place blocker too far left (past the cliff!) → invalid placement, no save.

---

## L004 — Two-Bridge Bypass 🟡

**Status:** Designed.

- **Biome:** Crypt Forge
- **Primary lesson:** sometimes you need *two* builders. Plan ahead and pace your charges.
- **Jobs:** Blocker × 1, Builder × 2
- **Skeletons:** 20, save 16
- **Core atoms:** Builder Gap — Up, Builder Gap — Up, Delayed Release

**Layout:**
```
.S>>>>....>>>>>>....>>>>>E.
######__######__#########.
      ↑       ↑
   gap 1   gap 2 (slightly wider)
```
- Spawn left platform, two Styx gaps in series, exit on far right platform.
- Gap 1 is ~80px (just inside builder bridge length).
- Gap 2 is ~120px (also bridgeable but less margin).
- Mid-platform between gaps is short (~96px) so the player has to time the second build precisely.

**Intended solution:**
1. Blocker between spawn and gap 1.
2. Builder #1 facing right → bridges gap 1.
3. Resume the blocker briefly so a few skeletons cross to mid-platform.
4. Block again on the mid-platform (skeletons accumulate).
5. Builder #2 from the mid-platform crowd → bridges gap 2.
6. Final resume → all flow over.

**Alternate solution (savvy):** skip the second blocker; use the natural pacing from the first bridge build to time the second builder click on the leading skeleton just before the second gap. Same outcome, fewer charges used.

**Failure modes:**
- Builder #2 used before mid-platform reached → wasted charge, builder builds in mid-air over gap 1.
- No mid-platform pause → the leader walks into gap 2 before second bridge ready.

---

## L005 — Hold the Line 🟡

**Status:** Designed (more advanced).

- **Biome:** Bone Gardens
- **Primary lesson:** combine Blocker, Builder, and Crumbler awareness. The first level that punishes sloppy timing.
- **Jobs:** Blocker × 2, Builder × 2
- **Skeletons:** 20, save 14
- **Core atoms:** Delayed Release, Builder Gap — Up, Crumbler Pinch, Reverse Flow recovery

**Layout:**
```
       _________
      /         \         ___________E
.S>>>/           \>>>>>>>/
####/             \__####
   ↑    Styx gap  ↑    ↑
crumbler        crumbler
(spawn          (mid-
 lip)            crumbler)
```
- Spawn platform with a crumbler at its right lip.
- Wide Styx gap (needs a builder).
- Mid-landing platform with another crumbler.
- Final platform with exit.

**Intended solution:**
1. Block immediately near the spawn lip (before the first crumbler triggers).
2. Builder facing right → bridges to mid-platform.
3. Brief release → crowd crosses to mid-platform. The mid-platform crumbler fuses on first weight.
4. Block on the mid-platform (now-clear of the first crumbler) before the next crumbler drops.
5. Builder #2 → bridges from mid-platform to exit platform.
6. Final release.

**Alternate solution (charge-saver):** skip the first blocker, use the natural lead time of the first builder’s windup. Higher risk: 2–4 lost skeletons.

**Failure modes:**
- Linger on either crumbler → lose the lip and any standing skeletons.
- Build first bridge from too far back → bridge falls short.

---

## L006+ — Future levels

Concept seeds for later sessions, in rough order of difficulty:

- **L006 — Drop and Roll:** introduces a safe-fall onto a lower path; tests fall tolerance with the new gait.
- **L007 — Crowded Crumbler:** narrow single-row platform where 20 skeletons must cross a long crumbling section in single file. Pure pacing puzzle, no jobs needed.
- **L008 — Reverse Engineering:** spawn faces right (default), exit is to the *left*; player must blocker-reverse without falling off the right cliff first.
- **L009 — Broken Teeth:** stair-stepped platforms where the rib bridge’s natural slope chains into the next step.
- **L010 — Three Ways Across:** sandbox board comparing flat / up / down builder bridges; tuning level, not necessarily a shipped puzzle.

Mechanics not yet in scope: Digger (downward terrain mod), Tunneler (sideways terrain mod), Floater/Climber. These are reserved for after the L001–L005 batch ships.

---

## Implementation order

For the next implementation session: build a tiny level-loader that swaps `terrain_root.gd`’s hardcoded layout for one of a small set of named scenes/scripts. Then port L002 and L003 (simplest, fewest moving parts) to actual playable levels and add a level-select on the title screen. L004–L005 follow once the loader is in shape.

The campaign progression should mirror the difficulty curve here — give players the wins on L001–L003, ramp on L004, gate-keep on L005.
