extends Node2D

signal minion_spawned(minion: Node)
signal minion_rescued(minion: Node)
signal minion_lost(minion: Node)
signal spawn_complete

const SkeletonMinionScene := preload("res://scenes/minions/SkeletonMinion.tscn")

@export var total_to_spawn := 20
@export var spawn_interval := 0.65
@export var spawn_position := Vector2(520, 420)
@export var spawn_direction := -1.0
@export var blockers_available := 2

var selected_job := "blocker"
var spawned_count := 0
var active_count := 0
var rescued_count := 0
var lost_count := 0
var blockers_remaining := 0
var _spawn_timer := 0.0
var _spawning_done := false

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
	minion.died.connect(_on_minion_died)
	minion.clicked.connect(_on_minion_clicked)
	add_child(minion)

	spawned_count += 1
	active_count += 1
	minion_spawned.emit(minion)

func _on_minion_exited(minion: Node) -> void:
	rescued_count += 1
	active_count = max(0, active_count - 1)
	minion_rescued.emit(minion)

func _on_minion_died(minion: Node) -> void:
	lost_count += 1
	active_count = max(0, active_count - 1)
	minion_lost.emit(minion)

func set_selected_job(job_id: String) -> void:
	selected_job = job_id

func _on_minion_clicked(minion: Node) -> void:
	if selected_job != "blocker":
		return
	if blockers_remaining <= 0 or not minion.has_method("become_blocker"):
		return
	if minion.become_blocker():
		blockers_remaining -= 1
		minion_spawned.emit(minion)

func all_done() -> bool:
	return _spawning_done and active_count == 0
