extends Node2D

signal minion_spawned(minion: Node)
signal minion_rescued(minion: Node)
signal minion_lost(minion: Node)
signal spawn_complete
signal sfx_requested(sound_id: String)

const SkeletonMinionScene := preload("res://scenes/minions/SkeletonMinion.tscn")

@export var total_to_spawn := 12
@export var spawn_interval := 0.75
@export var spawn_position := Vector2(2180, 420)
@export var spawn_direction := -1.0
@export var blockers_available := 1

var selected_job := "blocker"
var spawned_count := 0
var active_count := 0
var rescued_count := 0
var lost_count := 0
var blockers_remaining := 0
var _spawn_timer := 0.0
var _spawning_done := false
var debug_click_areas := false

func _ready() -> void:
	reset_spawner()

func _process(delta: float) -> void:
	if _spawning_done:
		return

	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_minion()
		_spawn_timer = spawn_interval

func reset_spawner() -> void:
	for child in get_children():
		child.queue_free()
	spawned_count = 0
	active_count = 0
	rescued_count = 0
	lost_count = 0
	blockers_remaining = blockers_available
	_spawn_timer = 0.1
	_spawning_done = false

func _spawn_minion() -> void:
	if spawned_count >= total_to_spawn:
		_spawning_done = true
		spawn_complete.emit()
		return

	var minion := SkeletonMinionScene.instantiate()
	minion.position = spawn_position
	minion.direction = spawn_direction
	minion.exited.connect(_on_minion_exited)
	minion.death_started.connect(_on_minion_death_started)
	minion.died.connect(_on_minion_died)
	minion.clicked.connect(_on_minion_clicked)
	if minion.has_method("set_debug_click_area"):
		minion.set_debug_click_area(debug_click_areas)
	add_child(minion)

	spawned_count += 1
	active_count += 1
	minion_spawned.emit(minion)

func _on_minion_exited(minion: Node) -> void:
	rescued_count += 1
	active_count = max(0, active_count - 1)
	sfx_requested.emit("exit_rescue")
	minion_rescued.emit(minion)

func _on_minion_death_started(_minion: Node, death_kind: String) -> void:
	if death_kind == "styx_water":
		sfx_requested.emit("styx_impact")
	sfx_requested.emit("bone_splash")

func _on_minion_died(minion: Node) -> void:
	lost_count += 1
	active_count = max(0, active_count - 1)
	minion_lost.emit(minion)

func set_debug_click_areas(enabled: bool) -> void:
	debug_click_areas = enabled
	for minion in get_tree().get_nodes_in_group("minions"):
		if minion.has_method("set_debug_click_area"):
			minion.set_debug_click_area(enabled)

func set_selected_job(job_id: String) -> void:
	selected_job = job_id

func _on_minion_clicked(minion: Node) -> void:
	if selected_job != "blocker":
		return

	if minion.get("is_blocker") == true and minion.has_method("resume_march"):
		if minion.resume_march():
			blockers_remaining = mini(blockers_remaining + 1, blockers_available)
			sfx_requested.emit("resume_march")
			minion_spawned.emit(minion)
		return

	if blockers_remaining <= 0 or not minion.has_method("become_blocker"):
		return
	if minion.become_blocker():
		blockers_remaining -= 1
		sfx_requested.emit("bone_clack")
		sfx_requested.emit("blocker_brace")
		minion_spawned.emit(minion)

func all_done() -> bool:
	# A placed blocker can remain braced after the crowd is safe; don't let that
	# strand the tutorial level in a never-ending state.
	var blockers_alive := get_tree().get_nodes_in_group("blockers").size()
	return _spawning_done and active_count <= blockers_alive
