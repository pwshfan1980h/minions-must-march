# Ash Catacombs Digger Gameplay Implementation Plan

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** Add a new non-Styx biome, Ash Catacombs, and ship one dedicated Digger teaching level where the core puzzle is digging through a marked floor into a lower tomb route.

**Implementation status:** ✅ Completed first pass on 2026-05-16 as L006 `Bone Basement Shortcut` / `level_006`. Digger v0 is implemented as a one-shot marked rectangular plug removal with valid-use-only charge consumption, plus source and Godot headless regression coverage.

**Architecture:** Keep the current Godot 4/GDScript scene tree and hardcoded level-builder style for the first pass, but make the new pieces intentionally shaped for the planned data-driven level catalog. Digger v0 should be a deterministic terrain-removal job: click a grounded skeleton standing on an obvious diggable floor plug, consume one Digger charge, remove the plug, and let the crowd drop into the lower corridor. The level should not be another platform-above-river-of-souls board; it should read as an enclosed dusty tomb/catacomb with ash floors, candle markers, cracked grave slabs, and a lower burial passage.

**Tech Stack:** Godot 4.6, GDScript, existing `GameRoot` / `LevelController` / `TerrainRoot` / `ObjectRoot` / `MinionRoot` / `GameUI` scenes, Python source-level checks in `scripts/tools/headless_feature_checks.py`, Godot headless checks via `godot --headless --path .`.

---

## Current Findings

Project path: `/Users/wm/projects/minions-must-march`.

Recent setup/status:

- Godot 4.6.2 is now installed via Homebrew cask and linked at `/opt/homebrew/bin/godot`.
- `/Users/wm/.zshrc` now prepends `/opt/homebrew/bin` so new shells can find `godot`.
- The previous multi-level map pass added `Drop Crypt Detour` as `LevelState` level 5 / `terrain` id `level_005`.
- Headless verification currently passes:
  - `python3 scripts/tools/headless_feature_checks.py`
  - `godot --headless --path . --quit --check-only`
  - `godot --headless --path . -s tests/builder_activation_check.gd`
- Running Godot import created untracked generated metadata/import files. Decide before committing whether to keep or ignore these:
  - `assets/audio/generated/*.wav.import`
  - `scripts/audio/beat_conductor.gd.uid`
  - `tests/beat_conductor_check.gd.uid`

Relevant implementation files:

- `scripts/core/level_state.gd` — live level registry, currently top-level `blockers` and `builders` keys only.
- `scripts/terrain/terrain_root.gd` — terrain builder functions `_build_level_001_terrain()` through `_build_level_005_terrain()` and `collision_rects` support used by Builder.
- `scripts/minions/minion_root.gd` — selected job routing, charge counts, Builder/Blocker implementations.
- `scripts/minions/skeleton_minion.gd` — movement, falling, click target, blocker/builder state.
- `scripts/ui/game_ui.gd` and `scenes/ui/GameUI.tscn` — two-button skill dock; needs a third Digger button/hotkey.
- `scripts/objects/object_root.gd` — spawn portal and exit light placement.
- `docs/level-archetypes.md` — already defines `Ash Catacombs` as the fit for dig/tunnel teaching.
- `docs/2026-05-13-feature-and-level-roadmap.md` — already names Digger v0 as terrain modification slice; this plan supersedes the idea that Digger must wait until after more Styx/river levels.

Doc/code mismatches to account for:

- `docs/level-cards.md` says early levels have 20 skeletons/save 16, but live `LevelState` uses 12/save 8–10. Do not rely on doc numbers for this Digger level until the campaign is normalized.
- The roadmap expected data-driven catalog work before new mechanics. For this focused feature, implement Digger in the existing hardcoded pattern first, then make it easy to migrate.
- The current biome presentation is mostly `Styx Marsh`/crypt blocks. Ash Catacombs needs new visual variants, not just purple platforms over water.

---

## Product Direction

### New biome: Ash Catacombs

**Do not make this another river level.** The board should feel like an enclosed tomb cutaway:

- Background/terrain mood: dry ash gray, charcoal, dusty brown, dried blood red, candle gold.
- No visible Styx river as the main bottom-of-screen design. Existing global Styx death area can remain as out-of-bounds safety, but the playable composition should be catacomb corridors and burial chambers.
- Terrain variants:
  - `ash_floor`: dusty stone slab floor.
  - `ash_wall`: vertical tomb masonry / side wall.
  - `dig_plug`: cracked grave slab/floor patch; visually loud and removable.
  - `lower_catacomb`: darker lower corridor blocks.
- Decorations: candles, ash motes, cracked coffin silhouettes, rib-bone signpost pointing down, skull dust puffs when digging.

### New skill: Digger v0

Digger should be the next skill after Builder/Blocker.

Rules for v0:

1. Player selects **DIG** from the skill dock or presses hotkey `3`.
2. Player clicks a grounded, living, non-blocker, non-builder skeleton.
3. The skeleton can become a digger only when standing on or directly above a marked diggable plug.
4. A Digger charge is consumed only if a valid plug is found and removed.
5. The dig action removes a pre-authored `dig_plug` body/shape from `TerrainRoot`.
6. The skeleton pauses briefly with a digging animation/readable dust burst, then resumes/falls naturally.
7. No freeform terrain deformation in v0. Use rectangular plugs only. This keeps the mechanic shippable.

What not to implement yet:

- Sideways tunneling.
- Arbitrary terrain carving.
- Dig direction choice.
- Multiple plug shapes beyond rectangles.
- Permanent Digger state that slowly mines over time. v0 should be a clean one-shot floor plug removal.

---

## Target Level: L006 or L009 “Bone Basement Shortcut”

Use the next slot after the newly added `Drop Crypt Detour` unless campaign order is renumbered later. The design name can stay **Bone Basement Shortcut**.

**Biome:** Ash Catacombs

**Primary lesson:** Some floors are doors. Use Digger on the cracked grave-slab plug to open a lower safe route.

**Jobs:** Blocker × 1, Builder × 0, Digger × 1

**Skeletons:** 12, save 9 or 10

**Core atoms:** Crumbly Floor Dig, Safe Drop, Reverse Flow light, enclosed lower route

### Layout sketch

Coordinate assumptions follow current 1280×720 viewport, y down.

```text
ASH CATACOMBS — no main Styx river composition

upper tomb corridor

  spawn >>>>>>>>>>>>>>>>>>>>>>>>> dead-end wall
  ################################################
                          [ cracked dig plug ]
                          [  remove with DIG  ]

lower burial passage

              v survivable drop
           ######################################## exit glow
           #                                      E
           ########################################
```

Suggested live coordinates:

- Spawn: `Vector2(220, 292)`, facing right.
- Upper corridor floor top: `y=320`, x `128→900`, height `32`.
- Right dead-end wall: x `900→932`, y `224→352` so the crowd turns back if the player misses the dig timing.
- Dig plug: `Rect2(584, 320, 96, 32)` replacing part of the upper floor.
- Lower corridor floor top: `y=448`, x `392→1250`, height `32`.
- Lower left stop wall: x `360→392`, y `384→576` to prevent back-walking offscreen.
- Exit: `Vector2(1180, 420)` or `Vector2(1180, 448)` depending on exit area tuning.
- Fall distance after plug opens: about `128px`, below fatal threshold and clearly survivable.

Intended solution:

1. Crowd spawns in an upper ash tomb corridor and walks right.
2. Player selects DIG (`3`) and clicks a skeleton as it crosses the cracked floor plug.
3. The plug breaks away in dust; the first skeleton and then the crowd drop into the lower burial passage.
4. If needed, player uses one Blocker on the lower left/right side to keep flow toward the exit.
5. Crowd walks through enclosed lower route to the exit.

Failure modes:

- Dig too late: lead skeletons hit the dead-end wall and turn around; still recoverable if they cross the plug again.
- Waste Digger away from the plug: no charge should be consumed, and hint text should imply “DIG only works on cracked floor.”
- Do not dig: crowd loops upper corridor until time/patience runs out; no immediate soup death.
- Bad Blocker placement: crowd turns away from exit but can be released.

Tuning target:

- First Digger level should be forgiving, not lethal. It teaches the mechanic by making the lower route obviously better, not by instantly killing the player.

---

## Implementation Tasks

### Task 1: Add a source-level failing test for Digger config/UI/terrain hooks

**Objective:** Define the new mechanic contract before production code.

**Files:**

- Modify: `scripts/tools/headless_feature_checks.py`

**Steps:**

1. Add `test_digger_biome_and_skill_contract_exists()` that checks:
   - `scripts/core/level_state.gd` contains `"biome": "ash_catacombs"` or equivalent for the new level.
   - `scripts/core/level_state.gd` contains a Digger charge key, preferably `"diggers": 1` for compatibility with current `blockers`/`builders` style.
   - `scripts/terrain/terrain_root.gd` contains `_build_level_006_terrain()` or whatever level id is chosen.
   - `scripts/terrain/terrain_root.gd` contains `diggable_plugs` and `_add_diggable_plug`.
   - `scripts/ui/game_ui.gd` contains `DiggerButton` and `KEY_3`.
   - `scripts/minions/minion_root.gd` contains selected job route for `"digger"`.

2. Run:

```bash
python3 scripts/tools/headless_feature_checks.py
```

Expected: FAIL because Digger does not exist yet.

3. Commit only after the test later passes.

---

### Task 2: Extend level config with Digger charge support

**Objective:** Let levels declare Digger charges without breaking existing levels.

**Files:**

- Modify: `scripts/core/level_state.gd`
- Modify: `scripts/minions/minion_root.gd`
- Modify: `scripts/core/level_controller.gd`

**Implementation notes:**

- Add `"diggers": 0` implicitly via fallback for old levels.
- Add exported/current vars in `MinionRoot`:
  - `@export var diggers_available := 0`
  - `var diggers_remaining := 0`
- In `_ready()`, read `diggers_available = int(cfg.get("diggers", diggers_available))`.
- In `reset_spawner()`, set `diggers_remaining = diggers_available`.
- In `LevelController.get_stats()`, include `"diggers": minion_root.diggers_remaining`.

Verification:

```bash
python3 scripts/tools/headless_feature_checks.py
```

Expected: still FAIL until UI/terrain/job route are implemented.

---

### Task 3: Add DIG to the skill dock

**Objective:** Expose the Digger skill to the player as a third skeleton skill.

**Files:**

- Modify: `scenes/ui/GameUI.tscn`
- Modify: `scripts/ui/game_ui.gd`

**Implementation notes:**

- Add `DiggerButton` under `SkillDock`, next to Blocker and Builder.
- Expand `SkillDock` width enough for three buttons without covering the main play area.
- Add `@onready var digger_button: Button = $SkillDock/DiggerButton`.
- Track `diggers_remaining` from stats.
- Add hotkey `KEY_3` to select Digger.
- Button text: `3\nDIG\n⛏ x%d`.
- Hint when selected: `DIG selected: click a skeleton standing on cracked ash floor.`
- Disable Digger button when `diggers_remaining <= 0`.

Verification:

```bash
godot --headless --path . --quit --check-only
```

Expected: no parse errors.

---

### Task 4: Add diggable plug terrain primitive

**Objective:** Create removable rectangular floor plugs in `TerrainRoot`.

**Files:**

- Modify: `scripts/terrain/terrain_root.gd`

**Implementation notes:**

Add state:

```gdscript
var diggable_plugs: Array[Dictionary] = []
```

Add helper:

```gdscript
func _add_diggable_plug(rect: Rect2, color: Color) -> StaticBody2D:
	var body := _add_solid(rect, color, "dig_plug")
	body.name = "DiggablePlug"
	diggable_plugs.append({"rect": rect, "body": body})
	return body
```

Add public methods:

```gdscript
func find_diggable_plug_at(world_position: Vector2) -> Dictionary:
	for plug in diggable_plugs:
		var rect: Rect2 = plug["rect"]
		if world_position.x >= rect.position.x - 12.0 and world_position.x <= rect.end.x + 12.0:
			if absf(world_position.y - rect.position.y) <= 40.0:
				return plug
	return {}

func remove_diggable_plug(plug: Dictionary) -> bool:
	if plug.is_empty():
		return false
	var rect: Rect2 = plug["rect"]
	var body: Node = plug["body"]
	collision_rects.erase(rect)
	diggable_plugs.erase(plug)
	if is_instance_valid(body):
		body.queue_free()
	queue_redraw()
	return true
```

Important: `collision_rects.erase(rect)` must remove the plug so Builder support detection and future source checks see terrain state accurately.

Verification:

```bash
godot --headless --path . --quit --check-only
```

Expected: no parse errors.

---

### Task 5: Implement Digger assignment route

**Objective:** Make clicking a skeleton with DIG selected remove a valid plug and consume a charge.

**Files:**

- Modify: `scripts/minions/minion_root.gd`
- Modify: `scripts/minions/skeleton_minion.gd`

**Implementation notes:**

In `MinionRoot._on_minion_clicked()`:

- Route `selected_job == "digger"` to `_try_assign_digger(minion)`.
- Only consume charge after terrain confirms plug removal.

Add in `MinionRoot`:

```gdscript
func _try_assign_digger(minion: Node) -> void:
	if diggers_remaining <= 0 or not minion.has_method("can_become_digger") or not minion.can_become_digger():
		return
	var terrain := get_node_or_null("../TerrainRoot")
	if terrain == null or not terrain.has_method("find_diggable_plug_at"):
		return
	var plug: Dictionary = terrain.find_diggable_plug_at(minion.global_position)
	if plug.is_empty():
		return
	if not terrain.remove_diggable_plug(plug):
		return
	diggers_remaining -= 1
	sfx_requested.emit("command_clatter")
	sfx_requested.emit("bone_clack")
	if minion.has_method("play_digger_dust"):
		minion.play_digger_dust()
	minion_spawned.emit(minion)
```

In `SkeletonMinion` add minimal methods:

```gdscript
func can_become_digger() -> bool:
	return alive and not rescued and not is_blocker and not is_builder and is_on_floor()

func play_digger_dust() -> void:
	# v0 can be visual-only/redraw request; no long state machine yet.
	_request_visual_redraw(true)
```

YAGNI note: Do not add a persistent `is_digger` state unless the animation absolutely needs it.

Verification:

```bash
godot --headless --path . --quit --check-only
python3 scripts/tools/headless_feature_checks.py
```

Expected: source-level checks should now pass if terrain/UI config are also done.

---

### Task 6: Build Ash Catacombs terrain variant and Digger level

**Objective:** Add the new biome and one playable Digger teaching level.

**Files:**

- Modify: `scripts/core/level_state.gd`
- Modify: `scripts/terrain/terrain_root.gd`

**Implementation notes:**

Add level entry after current level 5:

```gdscript
6: {
	"name": "Bone Basement Shortcut",
	"biome": "ash_catacombs",
	"terrain": "level_006",
	"beat": {"bpm": 88.0, "steps_per_beat": 2, "swing": 0.10, "walk_cycles_per_beat": 1.0},
	"rescue_required": 9,
	"minions": 12,
	"spawn_interval": 0.85,
	"blockers": 1,
	"builders": 0,
	"diggers": 1,
	"spawn_position": Vector2(220, 292),
	"spawn_direction": 1,
	"exit_position": Vector2(1180, 420),
	"hint": "Ash Catacombs: DIG the cracked floor plug, drop into the bone basement, then march to the exit.",
},
```

Add terrain dispatcher branch:

```gdscript
"level_006": _build_level_006_terrain()
```

Add `_build_level_006_terrain()` using the target coordinates above. Use `_add_diggable_plug(Rect2(584, 320, 96, 32), Color("6f625a"))` for the marked floor.

Add or extend visuals for `variant == "dig_plug"` inside `_add_block_underworld_detail()`:

- Cracked red/gold outline.
- Downward chevron or rib-bone marker.
- More visible than normal ash floor.

Verification:

```bash
godot --headless --path . --quit --check-only
python3 scripts/tools/headless_feature_checks.py
```

Expected: no parse errors; source-level feature checks pass.

---

### Task 7: Add a Godot Digger behavior test

**Objective:** Prove Digger consumes exactly one charge and removes a plug.

**Files:**

- Create: `tests/digger_activation_check.gd`

**Test shape:**

1. Load `res://scenes/GameRoot.tscn` or instantiate the needed roots.
2. Set `LevelState.goto(6)` before loading the scene.
3. Find `LevelController/MinionRoot` and `TerrainRoot`.
4. Assert `diggable_plugs.size() == 1`.
5. Spawn or use a skeleton positioned over the plug.
6. Select `digger` and call the click route or helper directly.
7. Assert:
   - `diggers_remaining == 0`
   - `diggable_plugs.size() == 0`
   - the plug rect no longer exists in `collision_rects`

Verification:

```bash
godot --headless --path . -s tests/digger_activation_check.gd
```

Expected: PASS with a clear message.

---

### Task 8: Smoke-test the new level render/load path

**Objective:** Verify Ash Catacombs loads in the full game without script errors.

**Files:**

- Modify if needed: `scripts/core/level_state.gd` or a temporary test script.

**Preferred command:**

```bash
godot --headless --path . -s tests/digger_activation_check.gd
```

Also run:

```bash
godot --headless --path . --quit --check-only
python3 scripts/tools/headless_feature_checks.py
```

Optional screenshot check if adding a level-select or env override later:

```bash
MMM_SCREENSHOT_PATH=/tmp/ash-catacombs.png MMM_EXIT_AFTER_SCREENSHOT=1 godot --headless --path .
```

Expected: a screenshot showing an enclosed ash/catacomb board, not platforms over river.

---

### Task 9: Update design docs and previews

**Objective:** Keep docs aligned with the live Digger level.

**Files:**

- Modify: `docs/level-archetypes.md`
- Modify: `docs/level-cards.md`
- Modify: `docs/2026-05-13-feature-and-level-roadmap.md`
- Modify: `docs/level-preview-data.json` if preview workflow supports this level.

**Changes:**

- Mark `Ash Catacombs` as the first Digger biome.
- Add/replace a concrete card for `Bone Basement Shortcut`.
- Explicitly note that this biome should avoid the river-of-souls platform composition.
- Regenerate previews if the exporter supports the new data.

Verification:

```bash
godot --headless --path . -s scripts/tools/export_level_previews.gd
```

Expected: updated preview assets for the new Digger level, if supported.

---

## Acceptance Criteria

- A new Ash Catacombs level exists and loads after the current campaign levels.
- The level’s composition is enclosed catacombs / tomb corridors, not platforms above the Styx river.
- The skill dock has three visible skills: Block, Build, Dig.
- Hotkeys are `1` Block, `2` Build, `3` Dig.
- Clicking a skeleton with DIG selected on cracked floor removes the plug and consumes one Digger charge.
- Clicking DIG away from cracked floor does not consume the charge.
- The crowd can fall through the opened floor into a survivable lower route.
- Headless checks pass:

```bash
python3 scripts/tools/headless_feature_checks.py
godot --headless --path . --quit --check-only
godot --headless --path . -s tests/builder_activation_check.gd
godot --headless --path . -s tests/digger_activation_check.gd
```

---

## Recommendation

Implement this before adding more river/platform levels. The game already has enough Builder/Blocker/Styx material to prove the loop; the next value is a new verb and a new visual lane. Digger v0 plus Ash Catacombs gives the campaign a second identity and makes later Tunneler gameplay feel natural instead of abrupt.
