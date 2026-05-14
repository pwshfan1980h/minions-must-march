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
    require("offset_bottom = 74.0" in scene, "HUD job bar should be compact")
    require("Click the portal" not in scene + ui, "HUD should not tell player to click the portal")
    require("Pick a tool, then click an eligible skeleton" in scene + ui, "HUD should use direct play instruction")


def test_river_has_bubbles_hands_and_pop_animation() -> None:
    terrain = read("scripts/terrain/terrain_root.gd")
    for token in ["_bubble_specs", "_bubble_pops", "_build_bubbles", "_draw_styx_bubbles", "_draw_bubble_pop", "_draw_styx_hands", "_draw_soul"]:
        require(token in terrain, f"terrain river polish missing {token}")


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


def main() -> None:
    tests = [
        test_startup_skips_title_and_portal_gate,
        test_hud_is_compact_and_no_long_startup_copy,
        test_river_has_bubbles_hands_and_pop_animation,
        test_audio_feedback_assets_and_hooks_exist,
    ]
    for test in tests:
        test()
        print(f"PASS {test.__name__}")
    print(f"All {len(tests)} headless feature checks passed.")


if __name__ == "__main__":
    main()
