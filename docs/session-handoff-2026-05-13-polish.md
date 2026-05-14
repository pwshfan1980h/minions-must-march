# Session Handoff — 2026-05-13 Polish Pass

This document captures the current state so the chat can be compacted safely.

## Project

- Repo: `/Users/wm/projects/minions-must-march`
- Branch: `main`
- Current work is uncommitted as of this handoff doc unless a later commit in this session says otherwise.

## User intent for this pass

Plan and implement a broad polish/content slice for **Minions Must March**, especially:

1. Remove the extra startup friction before play.
2. Make the HUD/title/info area smaller.
3. Improve the River of Souls visuals: visible souls, muck hands, bubbles, and bubble pop animation.
4. Add height/body-varied death yelp/knell audio and command bone-clatter feedback.
5. Add focused headless checks, validate, then commit/push if possible.

## Changes implemented in this pass

### Startup flow

- `project.godot`
  - Main scene now launches directly to `res://scenes/GameRoot.tscn` instead of `TitleScreen.tscn`.
- `scripts/minions/minion_root.gd`
  - `wait_for_start` default changed to `false`, so minions begin spawning immediately.
- `scripts/objects/object_root.gd`
  - Spawn portal is now decorative only:
    - `_spawn_portal_waiting := false`
    - portal click area uses `_spawn_portal_waiting` for `input_pickable`
    - collision shape disabled when not waiting
    - portal still draws as a green decorative gate so the spawn point remains readable.

### Compact HUD

- `scenes/ui/GameUI.tscn`
  - Job bar height reduced from `104` to `74` pixels.
  - Mission, goal, stats, score, hint, and buttons repositioned into the compact bar.
  - Perf label moved upward to sit below the compact HUD.
- `scripts/ui/game_ui.gd`
  - Hint copy shortened.
  - Removed “Click the portal…” startup instruction.

### River of Souls visual polish

- `scripts/terrain/terrain_root.gd`
  - Added `_bubble_specs` and `_bubble_pops` state.
  - Added `_build_bubbles()` to seed deterministic bubble paths.
  - Added `_tick_bubble_pops()` to create short-lived surface pop rings.
  - Added `_draw_styx_bubbles()` and `_draw_bubble_pop()`.
  - River draw order now includes bubbles between currents and hands.
  - Existing souls and muck hands remain in place and are part of the visual stack.

### Audio feedback

Generated new WAV assets in `assets/audio/generated/`:

- `command_clatter.wav`
- `death_yelp_tall.wav`
- `death_yelp_wiry.wav`
- `death_yelp_stocky.wav`
- `death_knell.wav`

Updated:

- `scripts/audio/sfx_player.gd`
  - Preloads the new sound IDs.
  - Adds volume offsets for them.
- `scripts/tools/sfx_resource_check.gd`
  - Includes the new generated audio files.
- `scripts/minions/skeleton_minion.gd`
  - Adds `death_voice_id()` based on the minion body archetype (`tall`, `stocky`, default `wiry`).
- `scripts/minions/minion_root.gd`
  - On death start, emits the body-varied death yelp plus `death_knell`, then existing impact/splash sounds.
  - On blocker/builder assignment, emits `command_clatter` in addition to existing bone feedback.

### Headless feature checks

- Added `scripts/tools/headless_feature_checks.py`.
- It verifies, without launching Godot:
  - startup skips title and portal gate
  - HUD is compact and no longer mentions clicking the portal
  - river bubble/pop/soul/hand hooks exist
  - new audio assets and SFX hooks exist

## Validation run

Passed:

```bash
python3 scripts/tools/headless_feature_checks.py
```

Output:

```text
PASS test_startup_skips_title_and_portal_gate
PASS test_hud_is_compact_and_no_long_startup_copy
PASS test_river_has_bubbles_hands_and_pop_animation
PASS test_audio_feedback_assets_and_hooks_exist
All 4 headless feature checks passed.
```

Could not run Godot validation because `godot` is not currently on PATH and Homebrew does not list a Godot install:

```bash
godot --headless --path . --quit
# /bin/bash: godot: command not found
```

Also attempted:

```bash
command -v godot || command -v godot4 || command -v /Applications/Godot.app/Contents/MacOS/Godot
brew list --cask | grep -i godot
brew list | grep -i godot
```

No Godot binary/install was found from the shell.

## Current active task state

- Completed in source:
  - Inspect relevant UI/river/audio code.
  - Add focused headless checks.
  - Remove title/portal startup friction.
  - Compact HUD.
  - Add river bubbles and pop animation.
  - Add body-varied death yelp/knell and command clatter.
  - Generate audio assets.
- Blocked/remaining:
  - Run real Godot headless smoke/resource checks once Godot CLI is available.
  - Visually inspect in Godot/editor because HUD compactness and river bubbles are visual changes.
  - Commit and push after validation, or commit with a note that Godot CLI validation was unavailable.

## Files touched/new

Modified:

- `project.godot`
- `scenes/ui/GameUI.tscn`
- `scripts/audio/sfx_player.gd`
- `scripts/minions/minion_root.gd`
- `scripts/minions/skeleton_minion.gd`
- `scripts/objects/object_root.gd`
- `scripts/terrain/terrain_root.gd`
- `scripts/tools/sfx_resource_check.gd`
- `scripts/ui/game_ui.gd`

New:

- `assets/audio/generated/command_clatter.wav`
- `assets/audio/generated/death_knell.wav`
- `assets/audio/generated/death_yelp_stocky.wav`
- `assets/audio/generated/death_yelp_tall.wav`
- `assets/audio/generated/death_yelp_wiry.wav`
- `scripts/tools/headless_feature_checks.py`
- `docs/session-handoff-2026-05-13-polish.md`

## Recommended next steps

1. Make Godot CLI available again, e.g. install/restore Godot 4 and ensure `godot` is on PATH.
2. Run:

   ```bash
   godot --headless --path . --quit
   godot --headless --path . --script res://scripts/tools/sfx_resource_check.gd
   python3 scripts/tools/headless_feature_checks.py
   ```

3. Open the project visually and check:
   - game starts directly in level
   - minions spawn without title/portal click
   - decorative portal does not intercept clicks
   - compact HUD is legible and not overlapping buttons
   - river bubbles/pops read as subtle Styx muck, not clutter
   - death yelps/knell and command clatter levels are not too loud
4. Commit and push.
