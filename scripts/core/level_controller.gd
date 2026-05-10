extends Node2D

signal stats_changed(stats: Dictionary)
signal level_finished(success: bool, stats: Dictionary)
signal sfx_requested(sound_id: String)

const LEVEL_WIDTH := 2400
const PLAYFIELD_HEIGHT := 608
const TILE_SIZE := 32
const RESCUE_REQUIRED := 16

var finished := false
var debug_click_areas := false

@onready var minion_root: Node = $MinionRoot
@onready var object_root: Node = $ObjectRoot

func _ready() -> void:
	print("LevelController ready: Builder Demo 1")
	minion_root.minion_spawned.connect(_on_minion_event)
	minion_root.minion_rescued.connect(_on_minion_event)
	minion_root.minion_lost.connect(_on_minion_event)
	minion_root.spawn_complete.connect(_on_spawn_complete)
	minion_root.sfx_requested.connect(_on_sfx_requested)
	object_root.minion_entered_exit.connect(_on_exit_entered)
	if object_root.has_signal("spawn_portal_clicked"):
		object_root.spawn_portal_clicked.connect(_on_spawn_portal_clicked)
	_emit_stats()

func _process(_delta: float) -> void:
	if not finished and minion_root.all_done():
		_finish_level(minion_root.rescued_count >= RESCUE_REQUIRED)

func restart_level() -> void:
	get_tree().reload_current_scene()

func set_selected_job(job_id: String) -> void:
	minion_root.set_selected_job(job_id)
	_emit_stats()

func toggle_debug_click_areas() -> bool:
	debug_click_areas = not debug_click_areas
	if minion_root.has_method("set_debug_click_areas"):
		minion_root.set_debug_click_areas(debug_click_areas)
	_emit_stats()
	return debug_click_areas

func get_stats() -> Dictionary:
	var score := _calculate_score()
	return {
		"spawned": minion_root.spawned_count,
		"total": minion_root.total_to_spawn,
		"active": minion_root.active_count,
		"rescued": minion_root.rescued_count,
		"lost": minion_root.lost_count,
		"blockers": minion_root.blockers_remaining,
		"builders": minion_root.builders_remaining,
		"selected_job": minion_root.selected_job,
		"required": RESCUE_REQUIRED,
		"score": score,
		"goal_text": "Save %d skeleton%s" % [RESCUE_REQUIRED, "" if RESCUE_REQUIRED == 1 else "s"],
		"bonus_text": "Bonus: +100 saved, +50 unused bone, -25 lost",
		"finished": finished,
		"debug_click_areas": debug_click_areas,
	}

func _calculate_score() -> int:
	var score: int = minion_root.rescued_count * 100 - minion_root.lost_count * 25
	if finished:
		score += minion_root.builders_remaining * 50 + minion_root.blockers_remaining * 25
	return max(0, score)

func _on_minion_event(_minion: Node = null) -> void:
	_emit_stats()

func _on_spawn_complete() -> void:
	_emit_stats()

func _on_sfx_requested(sound_id: String) -> void:
	sfx_requested.emit(sound_id)

func _on_spawn_portal_clicked() -> void:
	if minion_root.has_method("start_spawning"):
		minion_root.start_spawning()
	sfx_requested.emit("resume_march")
	_emit_stats()

func _on_exit_entered(_minion: Node) -> void:
	# Signal exists for future scoring/particles/sound. The minion handles rescue.
	pass

func _emit_stats() -> void:
	stats_changed.emit(get_stats())

func _finish_level(success: bool) -> void:
	finished = true
	var stats := get_stats()
	stats["finished"] = true
	sfx_requested.emit("level_success" if success else "level_fail")
	level_finished.emit(success, stats)
	_emit_stats()
