class_name LevelState
extends Node

# Per-level configuration. Each entry is the source of truth for terrain,
# spawn parameters, charges, exit position, and rescue threshold. All gameplay
# nodes read from `LevelState.config()` on _ready instead of hardcoding values.
#
# Implemented as a class with static state so it works both as an autoload (in
# the normal game flow) and when scripts run via `godot -s` (smoke tests),
# where autoloads aren't applied.

const LEVELS := {
	1: {
		"name": "Bone Bridge",
		"terrain": "level_001",
		"rescue_required": 10,
		"minions": 12,
		"spawn_interval": 0.9,
		"blockers": 2,
		"builders": 2,
		"spawn_position": Vector2(220, 420),
		"spawn_direction": 1,
		"exit_position": Vector2(1210, 400),
		"hint": "Build over the gap. The crowd takes time to flow — don't loiter.",
	},
	2: {
		"name": "The Crumblepath",
		"terrain": "level_002",
		"rescue_required": 8,
		"minions": 12,
		"spawn_interval": 0.9,
		"blockers": 1,
		"builders": 1,
		"spawn_position": Vector2(220, 420),
		"spawn_direction": 1,
		"exit_position": Vector2(1340, 372),
		"hint": "Three crumbling chunks. Move fast or lose the lip.",
	},
	3: {
		"name": "Turn, You Fools",
		"terrain": "level_003",
		"rescue_required": 10,
		"minions": 12,
		"spawn_interval": 0.9,
		"blockers": 1,
		"builders": 0,
		"spawn_position": Vector2(640, 420),
		"spawn_direction": -1,
		"exit_position": Vector2(1300, 420),
		"hint": "They're walking the wrong way. Block the cliff before they reach it.",
	},
	4: {
		"name": "Two-Bridge Bypass",
		"terrain": "level_004",
		"rescue_required": 10,
		"minions": 12,
		"spawn_interval": 0.9,
		"blockers": 1,
		"builders": 2,
		"spawn_position": Vector2(220, 452),
		"spawn_direction": 1,
		"exit_position": Vector2(1180, 356),
		"hint": "Two gaps. Pace your builder charges.",
	},
}

static var current_level := 1

static func config() -> Dictionary:
	return LEVELS.get(current_level, LEVELS[1])

static func has_next_level() -> bool:
	return LEVELS.has(current_level + 1)

static func advance() -> bool:
	if has_next_level():
		current_level += 1
		return true
	return false

static func reset() -> void:
	current_level = 1

static func goto(n: int) -> void:
	if LEVELS.has(n):
		current_level = n
