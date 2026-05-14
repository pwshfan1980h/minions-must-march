# Feature and Level Swath Implementation Plan

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** Grow Minions Must March from the current Builder/Blocker prototype into a small, playable 12-level campaign arc with reusable level data, level selection, and three new mechanic families: uplight drafts, Digger v0, and Tunneler v0.

**Architecture:** Keep the current Godot 4/GDScript custom-simulation approach. First make levels more data-driven by replacing hardcoded `LevelState.LEVELS` + `TerrainRoot` `match` branches with reusable level definitions and terrain/object builders. Then add mechanics as small deterministic primitives that levels can compose: rectangle terrain, crumblers, build markers, rescue drafts, diggable plugs, and tunnel plugs.

**Tech Stack:** Godot 4, GDScript, existing scene tree (`GameRoot`, `LevelController`, `TerrainRoot`, `ObjectRoot`, `MinionRoot`, `GameUI`), existing headless Godot test script pattern under `tests/`.

**New rhythm direction:** The game remains a normal Lemmings-style puzzle game mechanically, but the skeleton crowd should *look* like it is marching to spooky puzzle music. Beat sync must drive gait phase and audio feel, not horizontal movement speed, so existing timing/puzzle solutions do not drift when music changes.

---

## Current Findings

Project found at: `/Users/wm/projects/minions-must-march`.

Useful source files:

- `scripts/core/level_state.gd` currently stores 4 levels directly in a static dictionary.
- `scripts/terrain/terrain_root.gd` currently builds levels via `_build_level_001_terrain()` through `_build_level_004_terrain()`.
- `scripts/minions/minion_root.gd` already supports `blocker` and `builder` charges, builder pieces, and selected-job routing.
- `scripts/minions/skeleton_minion.gd` already exposes `is_blocker`, `is_builder`, `can_become_builder()`, `become_blocker()`, `resume_march()`, and death/rescue hooks.
- `scripts/ui/game_ui.gd` has only Blocker and Builder buttons/hotkeys.
- `scripts/objects/object_root.gd` owns spawn portals and exit light.
- `docs/level-cards.md`, `docs/level-archetypes.md`, and `docs/level-preview-data.json` already contain a partial first-batch level design vocabulary.

Key mismatch to fix early:

- `docs/level-cards.md` says L001 has 20 skeletons/save 16, but `LevelState` currently has 12/save 10.
- `levels/level_001_bridge_school.json` is still a one-skeleton Builder demo while the current hardcoded L001 is closer to `Bone Bridge`.
- `GameUI.update_stats()` hardcodes `mission_label.text = "BONE BRIDGE"` instead of using `level_name`.

---

## Recommended Campaign Arc

### Slice 1 — Ship the current toolset well

These levels use only Portal Start, Blocker, Builder, Styx, and Crumbler.

1. **L001 Bone Bridge** — Blocker dams crowd while one Builder bridges a small upward Styx gap.
2. **L002 Turn, You Fools** — Spawn faces danger; one Blocker reverses flow toward exit.
3. **L003 Rib Ramp** — Builder Up: bridge as a stair, not just a flat plank.
4. **L004 Grave Slide** — Builder Down / safe descent recovery level after Rib Ramp.
5. **L005 Two-Scoop Soup** — Two builders over two Styx gaps with a safe island.
6. **L006 Crumblepath** — Crumblers become the primary time pressure.

### Slice 2 — Add friendly vertical motion

7. **L007 Holy Uplight Draft** — Introduce warm rescue draft as a safe, readable lift zone.
8. **L008 Drop Choir** — Safe drop into a lower route, then an uplight rescue. Teaches falling is not always death.

### Slice 3 — Add terrain modification v0

9. **L009 Bone Basement Shortcut** — Digger v0: dig through a marked floor plug into a lower safe corridor.
10. **L010 Side Crypt** — Tunneler v0: tunnel through an obvious cracked side wall to exit chamber.
11. **L011 Plug and Pray** — Combine Digger + Builder: dig down, then build out of a bad pocket.
12. **L012 Three Ways Across** — Builder sandbox/tuning level comparing down, flat, and up bridge lines; can be hidden under debug/bonus until polished.

---

## Feature Roadmap

### Feature 0: Spooky beat conductor and synced skeleton march ✅ first pass

**Objective:** Add a deterministic beat clock so skeletons visually step in time with a spooky underworld loop while retaining normal puzzle movement.

**Files:**

- Create: `scripts/audio/beat_conductor.gd`
- Create: `tests/beat_conductor_check.gd`
- Modify: `scripts/core/game_root.gd`
- Modify: `scripts/minions/skeleton_minion.gd`
- Modify: `scripts/audio/sfx_player.gd`
- Replace/generated: `assets/audio/generated/crypt_march_loop.wav`

**Implemented first-pass behavior:**

- `BeatConductor` exposes BPM, beat phase, swung step index, and walk-cycle radians.
- `GameRoot` creates a conductor, configures it from `LevelState.config()["beat"]`, adds it to group `beat_conductor`, then starts the music loop.
- Walking skeletons keep their deterministic `WALK_SPEED`; only `_walk_time` for drawing is snapped to the conductor's walk-cycle phase.
- The new loop is a 92 BPM spooky march: low crypt thumps, swung bone clicks, ghost pad, bell accents, and Styx risers.

**Next rhythm refinements:**

1. Add per-biome loop variants once level biomes are catalog-driven.
2. Add tiny footstep/bone-click particles on `step_crossed` for nearby skeletons, but cap it so the crowd does not spam draw calls or SFX.
3. Add UI/music settings: music volume, rhythm sync on/off, and maybe “strict metronome” debug display.
4. If puzzle timing ever depends on audio, use the conductor clock as source of truth; never derive mechanics from audio playback position.

### Feature A: Level registry and data-driven terrain rectangles

**Objective:** Stop adding new levels by editing several hardcoded functions. A level should be one dictionary/resource that defines stats, terrain rectangles, crumblers, spawn, exit, hazards, and tutorial text.

**Files:**

- Modify: `scripts/core/level_state.gd`
- Modify: `scripts/terrain/terrain_root.gd`
- Modify: `scripts/objects/object_root.gd`
- Modify: `scripts/ui/game_ui.gd`
- Create: `levels/campaign_levels.gd` or `scripts/core/level_catalog.gd`
- Create/modify tests under `tests/`

**Implementation notes:**

Use a first-pass dictionary shape like:

```gdscript
{
	"name": "Bone Bridge",
	"biome": "styx",
	"rescue_required": 16,
	"minions": 20,
	"spawn_interval": 0.9,
	"jobs": {"blocker": 2, "builder": 2},
	"spawn": {"position": Vector2(220, 420), "direction": 1},
	"exit": {"position": Vector2(1210, 400)},
	"terrain": [
		{"rect": Rect2(160, 448, 56, 32), "kind": "crumbling", "variant": "crypt"},
		{"rect": Rect2(216, 448, 584, 32), "kind": "solid", "variant": "crypt"}
	],
	"markers": [
		{"kind": "builder_start", "position": Vector2(760, 440), "direction": 1}
	],
	"hint": "Block the crowd, build the rib bridge, then release."
}
```

**Tasks:**

1. Create `scripts/core/level_catalog.gd` with the current four hardcoded levels transcribed into one `const LEVELS` dictionary.
2. Update `LevelState.config()` to return `LevelCatalog.LEVELS[current_level]` and keep `current_level`, `has_next_level()`, `advance()`, `reset()`, and `goto()` in `LevelState`.
3. Update `MinionRoot._ready()` to read `jobs.blocker` and `jobs.builder` while keeping compatibility with old top-level `blockers`/`builders` keys during migration.
4. Update `ObjectRoot._build_placeholder_objects()` to read `spawn.position`, `spawn.direction`, and `exit.position` with compatibility fallback.
5. Add `TerrainRoot._build_from_config(cfg)` that loops over `cfg["terrain"]` and calls `_add_solid()` or `_add_crumbling_solid()`.
6. Keep old `_build_level_00x_terrain()` functions temporarily as reference, but switch `_ready()` to use `_build_from_config()` when `terrain` is an Array or `terrain_rects` exists.
7. Update `GameUI.update_stats()` to set `mission_label.text = String(stats.get("level_name", "CRYPT DUTY")).to_upper()`.
8. Add a headless smoke test `tests/level_catalog_check.gd` that verifies every level has name, minions, rescue_required, jobs, spawn, exit, and at least one terrain rectangle.
9. Run: `godot --headless --path . -s tests/level_catalog_check.gd`.
10. Run: `godot --headless --path . -s tests/builder_activation_check.gd`.

**Gate:** Existing L001-L004 still load, Builder still creates six rib pieces, and the UI mission label changes per level.

---

### Feature B: Level select and progression control

**Objective:** Make the growing campaign testable without waiting for auto-advance.

**Files:**

- Modify: `scripts/ui/title_screen.gd`
- Modify: `scenes/TitleScreen.tscn`
- Modify: `scripts/core/level_state.gd`
- Modify: `scripts/ui/game_ui.gd`

**Tasks:**

1. Add `LevelState.get_level_numbers()`, `LevelState.get_level_name(n)`, and `LevelState.goto(n)` that works with the new catalog.
2. Add simple title-screen level buttons for levels 1-12, initially created procedurally in `title_screen.gd` to avoid scene churn.
3. Button click: `LevelState.goto(level_number)`, then `change_scene_to_file(GAME_ROOT_PATH)`.
4. Keep existing "any click/key starts L001" behavior only when clicking outside buttons.
5. Add in-level debug hotkeys: `[` previous level and `]` next level, only in dev builds or clearly marked debug.
6. Add `N` hotkey on success/failure screen to go next if available.
7. Update title prompt text to mention level select.

**Gate:** From the title screen, the user can launch L001-L004 directly; `]` and `[` can smoke-test level traversal during development.

---

### Feature C: Level batch L001-L006 with existing mechanics

**Objective:** Build six complete, playable levels before adding new jobs.

**Files:**

- Modify: `scripts/core/level_catalog.gd`
- Modify: `docs/level-cards.md`
- Modify: `docs/level-preview-data.json`
- Generated/updated: `docs/level-previews/*.png`

**Tasks:**

1. Normalize L001 `Bone Bridge` to the level-card numbers: 20 minions, save 16, Blocker ×2, Builder ×2.
2. Implement L002 `Turn, You Fools`: spawn mid-platform facing left; one blocker; no builder required.
3. Implement L003 `Rib Ramp`: one builder up-gap, one blocker safety charge.
4. Implement L004 `Grave Slide`: top route descends into a lower exit platform; use Builder Down as recovery.
5. Implement L005 `Two-Scoop Soup`: two gaps, safe island, Builder ×2, Blocker ×1.
6. Implement L006 `Crumblepath`: three crumbling sections with tuned fuse values; one bridge gap.
7. Update `docs/level-preview-data.json` to match actual catalog values.
8. Run preview export: `godot --headless --path . -s scripts/tools/export_level_previews.gd`.
9. Add a `tests/level_sequence_smoke.gd` that loads each L001-L006 for 120 frames after start portal click and fails on script errors or missing nodes.
10. Run: `godot --headless --path . -s tests/level_sequence_smoke.gd`.

**Gate:** L001-L006 launch from the title screen and match the written level cards closely enough for manual playtesting.

---

### Feature D: Holy Uplight Draft object

**Objective:** Add a friendly vertical rescue/current zone for vertical layouts without requiring ladders or player-controlled jumping.

**Files:**

- Modify: `scripts/objects/object_root.gd`
- Modify: `scripts/minions/skeleton_minion.gd`
- Modify: `scripts/core/level_controller.gd`
- Modify: `scripts/audio/sfx_player.gd` if a new SFX id is added
- Modify: `scripts/core/level_catalog.gd`

**Rules:**

- A draft is an `Area2D` configured by `objects: [{"kind": "uplight_draft", "rect": Rect2(...)}]`.
- When a live minion enters it, horizontal walking is suppressed, gravity is reduced or overridden, and it floats upward at a deterministic speed.
- If the draft overlaps/reaches an exit light, rescue is counted when the skeleton reaches the exit volume or draft top.
- It is safe, warm, wide, and forgiving. Do not style it as a trap.

**Tasks:**

1. Add `objects` array support in `ObjectRoot._build_placeholder_objects()`.
2. Create `_add_uplight_draft(rect: Rect2)` with an `Area2D` and simple motes/beam drawing.
3. Add `SkeletonMinion.enter_uplight_draft(draft_rect_or_center)` and `exit_uplight_draft()` methods, or a simpler `set_uplight_active(active, center_x)` state.
4. In `_physics_process`, when uplight active: set `velocity.x = 0`, `velocity.y = -90`, avoid fatal-fall checks, and keep the skeleton readable.
5. Add a headless test `tests/uplight_draft_check.gd` that places a minion inside a draft and verifies y decreases over frames and no death is emitted.
6. Create L007 `Holy Uplight Draft` and L008 `Drop Choir` in the catalog.

**Gate:** A skeleton entering a draft visibly floats upward and can be rescued without being marked lost from a prior fall.

---

### Feature E: Digger v0 with marked floor plugs

**Objective:** Add the first downward terrain-modification job without building full bitmap destructible terrain.

**Files:**

- Modify: `scripts/minions/minion_root.gd`
- Modify: `scripts/minions/skeleton_minion.gd`
- Modify: `scripts/terrain/terrain_root.gd`
- Modify: `scripts/ui/game_ui.gd`
- Modify: `scenes/ui/GameUI.tscn`
- Modify: `scripts/core/level_controller.gd`
- Modify: `scripts/core/level_catalog.gd`

**Rules:**

- Digger can only be assigned to alive, grounded, non-blocker, non-builder skeletons standing on a marked `diggable_floor` plug.
- Assignment consumes one Digger charge only when valid.
- Digger removes a vertical stack of small plug segments, one chunk every ~0.18s.
- Digger stops at air, indestructible terrain, hazard/water, or a max depth.
- After the plug opens, normal gravity/walking resumes.

**Tasks:**

1. Add `diggers_available` / `diggers_remaining` fields to `MinionRoot`.
2. Add UI button/hotkey `3` for Digger in `GameUI` and `GameUI.tscn`.
3. Add `selected_job == "digger"` routing in `_on_minion_clicked()`.
4. Add terrain plug registration in `TerrainRoot`, e.g. `var diggable_plugs: Array[Dictionary]`.
5. Implement `TerrainRoot.get_floor_plug_under(position: Vector2)` and `TerrainRoot.remove_plug_chunk(plug_id)`.
6. Add `SkeletonMinion.can_become_digger()` and `set_digger_active()` similar to Builder state.
7. Add `MinionRoot._run_digger_sequence(minion, plug)` that removes chunks over time.
8. Add `tests/digger_plug_check.gd`: assign Digger on valid plug, assert charge consumed and collision chunk count decreases.
9. Build L009 `Bone Basement Shortcut`.

**Gate:** Digger opens a marked floor plug into a lower safe corridor; invalid assignments do not spend charges.

---

### Feature F: Tunneler v0 with marked wall plugs

**Objective:** Add sideways terrain modification as a sibling of Digger v0, still based on marked plugs.

**Files:** Same families as Digger v0.

**Rules:**

- Tunneler can only be assigned to alive, grounded, non-blocker skeletons facing a marked `diggable_wall` plug.
- Assignment consumes one Tunneler charge only when valid.
- Removes horizontal chunks in facing direction.
- Stops at air, indestructible terrain, hazard, or max tunnel length.
- Skeleton resumes walking through the opened passage.

**Tasks:**

1. Add `tunnelers_available` / `tunnelers_remaining` fields to `MinionRoot`.
2. Add UI button/hotkey `4`.
3. Add `TerrainRoot.get_wall_plug_ahead(position, direction)`.
4. Implement chunk removal for wall plugs, reusing as much Digger plug code as possible.
5. Add `SkeletonMinion.can_become_tunneler()` and `set_tunneler_active()`.
6. Add `MinionRoot._run_tunneler_sequence(minion, plug)`.
7. Add `tests/tunneler_plug_check.gd`.
8. Build L010 `Side Crypt`.

**Gate:** Tunneler opens an obvious cracked side wall and routes the crowd into an exit chamber without precision placement.

---

### Feature G: Polish and release loop

**Objective:** Keep the project showable as the level count grows.

**Files:**

- Modify: `docs/progress-log.md`
- Modify: `docs/performance-tuning.md`
- Modify: `README.md`
- Potentially modify SFX scripts/resources

**Tasks:**

1. Add per-level intro/hint strings to the catalog and display them in the HUD.
2. Add invalid-assignment feedback: text flash + dull clack SFX.
3. Add a small end-of-level panel with next/retry/title options.
4. Re-export web after L001-L006: `godot --headless --path . --export-release Web builds/web/index.html`.
5. Serve locally: `cd builds/web && python3 -m http.server 8088`.
6. Browser smoke test: start from title, complete/lose/restart at least one level, confirm audio unlock after input.
7. Update `README.md` with level-select and control list.

**Gate:** The six-level existing-mechanic slice is playable locally and via web export before Digger/Tunneler work begins.

---

## Priority Recommendation

Do **not** jump straight to Digger/Tunneler. The next best swath is:

1. Feature A — data-driven level catalog.
2. Feature B — title level select.
3. Feature C — build/polish L001-L006 with current mechanics.
4. Feature D — uplight drafts for vertical variety.
5. Feature E/F — Digger and Tunneler only after the existing campaign slice feels solid.

This sequence gives you more playable content quickly while keeping technical risk bounded. It also avoids expanding the UI/job surface before the level pipeline is stable.
