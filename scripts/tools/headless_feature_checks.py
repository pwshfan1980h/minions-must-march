#!/usr/bin/env python3
"""Fast headless regression checks for Minions Must March polish slices.

These are intentionally source-level checks so they run without opening the Godot
editor/window. They guard the UI/startup/audio/river behavior requested in the
May polish pass.
"""
from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def read(rel: str) -> str:
    return (ROOT / rel).read_text(encoding="utf-8")


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def test_startup_skips_title_and_portal_gate() -> None:
    project = read("project.godot")
    minions = read("scripts/minions/minion_root.gd")
    objects = read("scripts/objects/object_root.gd")
    require('run/main_scene="res://scenes/GameRoot.tscn"' in project, "main scene should launch directly into GameRoot")
    require("@export var wait_for_start := false" in minions, "minion spawning should begin immediately")
    require("var _spawn_portal_waiting := false" in objects, "spawn portal should be decorative, not a required click gate")
    require("input_pickable = _spawn_portal_waiting" in objects, "decorative portal should not steal clicks")


def test_hud_is_compact_and_no_long_startup_copy() -> None:
    scene = read("scenes/ui/GameUI.tscn")
    ui = read("scripts/ui/game_ui.gd")
    require("offset_bottom = 58.0" in scene, "status panel should be very compact")
    require("[node name=\"SkillDock\" type=\"Panel\" parent=\".\"]" in scene, "skeleton skills should live in their own level dock")
    require("parent=\"SkillDock\"" in scene, "action buttons should be parented to the in-level skill dock")
    require("Click the portal" not in scene + ui, "HUD should not tell player to click the portal")
    require("Pick a skeleton skill" in scene + ui, "HUD should name the skeleton skill dock")
    require("offset_top = 70.0" in scene and "offset_bottom = 162.0" in scene, "skill dock should sit in the upper playfield, away from marching skeletons")


def test_multilevel_drop_crypt_level_exists() -> None:
    state = read("scripts/core/level_state.gd")
    terrain = read("scripts/terrain/terrain_root.gd")
    require('"name": "Drop Crypt Detour"' in state, "level 5 should be the new multi-level drop map")
    require('"terrain": "level_005"' in state, "level 5 should use level_005 terrain")
    require('"blockers": 2' in state and '"builders": 1' in state, "level 5 should ask for lower-tier blocker decisions plus one builder bridge")
    require('"level_005": _build_level_005_terrain()' in terrain, "terrain dispatcher should load level_005")
    require("func _build_level_005_terrain()" in terrain, "level_005 terrain builder should exist")
    require("survivable" in terrain and "96px fall" in terrain, "level_005 should document the non-fatal multi-level fall")


def test_river_has_bubbles_hands_and_pop_animation() -> None:
    terrain = read("scripts/terrain/terrain_root.gd")
    for token in ["_bubble_specs", "_bubble_pops", "_build_bubbles", "_draw_styx_bubbles", "_draw_bubble_pop", "_draw_styx_hands", "_draw_soul"]:
        require(token in terrain, f"terrain river polish missing {token}")


def test_platforms_are_jagged_and_emit_motes() -> None:
    terrain = read("scripts/terrain/terrain_root.gd")
    for token in ["_build_chipped_silhouette", "ragged underside", "HangingJaggedShard", "_platform_ash_specs", "_add_platform_ash_emitter", "_draw_platform_ash_motes"]:
        require(token in terrain, f"terrain platform polish missing {token}")
    require("collision stays a clean rect" in terrain, "platform visual cleanup should not change puzzle collision rectangles")


def test_audio_feedback_assets_and_hooks_exist() -> None:
    sfx = read("scripts/audio/sfx_player.gd")
    minions = read("scripts/minions/minion_root.gd")
    skeleton = read("scripts/minions/skeleton_minion.gd")
    for sound_id in ["command_clatter", "death_yelp_tall", "death_yelp_wiry", "death_yelp_stocky", "death_knell"]:
        require(sound_id in sfx, f"SfxPlayer missing stream {sound_id}")
        require((ROOT / f"assets/audio/generated/{sound_id}.wav").exists(), f"missing generated wav for {sound_id}")
    require("death_voice_id" in skeleton, "skeleton should expose body-height voice variant")
    require("death_voice_id()" in minions and "death_knell" in minions, "minion root should emit death yelp + knell")
    require(minions.count('sfx_requested.emit("command_clatter")') >= 2, "builder/blocker commands should both clatter")


def test_async_gait_no_beat_conductor() -> None:
    skeleton = read("scripts/minions/skeleton_minion.gd")
    sfx = read("scripts/audio/sfx_player.gd")
    game_root = read("scripts/core/game_root.gd")
    require("BeatConductor" not in skeleton and "_beat_conductor" not in skeleton, "skeleton should no longer reference the beat conductor")
    require("BeatConductor" not in game_root and "beat_conductor" not in game_root, "GameRoot should no longer wire up a beat conductor")
    require("start_music" not in sfx and "play_march_step" not in sfx and "MUSIC_PATH" not in sfx, "SfxPlayer should no longer play the march loop or aggregate march steps")
    require("_walk_time = rng.randf_range(0.0, TAU)" in skeleton, "each skeleton should seed its own gait phase for async marching")
    require('rng.randf_range(0.82, 1.18)' in skeleton, "each skeleton should get an obvious per-instance stride-speed drift")
    require("delta * 8.8 * _stride_variant" in skeleton, "gait time should advance per-skeleton from delta")


def test_digger_biome_and_skill_contract_exists() -> None:
    state = read("scripts/core/level_state.gd")
    terrain = read("scripts/terrain/terrain_root.gd")
    ui = read("scripts/ui/game_ui.gd")
    scene = read("scenes/ui/GameUI.tscn")
    minions = read("scripts/minions/minion_root.gd")
    skeleton = read("scripts/minions/skeleton_minion.gd")
    controller = read("scripts/core/level_controller.gd")

    require('"name": "Bone Basement Shortcut"' in state, "level 6 should be Bone Basement Shortcut")
    require('"biome": "ash_catacombs"' in state, "new Digger level should declare the Ash Catacombs biome")
    require('"terrain": "level_006"' in state, "new Ash Catacombs level should use level_006 terrain")
    require('"diggers": 1' in state and '"builders": 0' in state, "Digger teaching level should provide one Digger and no Builder")
    require('"level_006": _build_level_006_terrain()' in terrain, "terrain dispatcher should load level_006")
    require("func _build_level_006_terrain()" in terrain, "level_006 terrain builder should exist")
    require("diggable_plugs" in terrain and "_add_diggable_plug" in terrain, "TerrainRoot should expose removable diggable plugs")
    require("find_diggable_plug_at" in terrain and "remove_diggable_plug" in terrain, "TerrainRoot should support Digger lookup and removal")
    require("DiggerButton" in scene and "digger_button" in ui and "KEY_3" in ui, "HUD should expose DIG as hotkey 3 in the skill dock")
    require("diggers_remaining" in minions and 'selected_job == "digger"' in minions, "MinionRoot should route selected DIG jobs")
    require("can_become_digger" in skeleton and "play_digger_dust" in skeleton, "SkeletonMinion should expose Digger eligibility/feedback hooks")
    require('"diggers": minion_root.diggers_remaining' in controller, "LevelController stats should include Digger charges")


def main() -> None:
    tests = [
        test_startup_skips_title_and_portal_gate,
        test_hud_is_compact_and_no_long_startup_copy,
        test_multilevel_drop_crypt_level_exists,
        test_river_has_bubbles_hands_and_pop_animation,
        test_platforms_are_jagged_and_emit_motes,
        test_audio_feedback_assets_and_hooks_exist,
        test_async_gait_no_beat_conductor,
        test_digger_biome_and_skill_contract_exists,
    ]
    for test in tests:
        test()
        print(f"PASS {test.__name__}")
    print(f"All {len(tests)} headless feature checks passed.")


if __name__ == "__main__":
    main()
