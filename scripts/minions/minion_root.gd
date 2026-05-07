extends Node2D

signal minion_spawned(minion: Node)
signal minion_rescued(minion: Node)
signal minion_lost(minion: Node)
signal spawn_complete
signal sfx_requested(sound_id: String)

const SkeletonMinionScene := preload("res://scenes/minions/SkeletonMinion.tscn")

@export var total_to_spawn := 1
@export var spawn_interval := 1.0
@export var spawn_position := Vector2(220, 420)
@export var spawn_direction := 1.0
@export var blockers_available := 0
@export var builders_available := 1
@export var wait_for_start := true

var selected_job := "builder"
var spawned_count := 0
var active_count := 0
var rescued_count := 0
var lost_count := 0
var blockers_remaining := 0
var builders_remaining := 0
var _spawn_timer := 0.0
var _spawning_done := false
var _spawn_started := false
var debug_click_areas := false

const BUILDER_PIECE_COUNT := 6
const BUILDER_PIECE_SIZE := Vector2(28.0, 8.0)
const BUILDER_PIECE_SPACING := 24.0
const BUILDER_STEP_RISE := 8.0
const BUILDER_SUPPORT_Y_TOLERANCE := 28.0
const BUILDER_WINDUP_SECONDS := 0.22
const BUILDER_THROW_DURATION := 0.24
const BUILDER_SETTLE_SECONDS := 0.08
const BUILDER_HAND_OFFSET := Vector2(16.0, -12.0)

func _ready() -> void:
	reset_spawner()

func _process(delta: float) -> void:
	if not _spawn_started or _spawning_done:
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
	builders_remaining = builders_available
	_spawn_timer = 0.1
	_spawning_done = false
	_spawn_started = not wait_for_start

func start_spawning() -> void:
	if _spawn_started:
		return
	_spawn_started = true
	_spawn_timer = 0.0

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
	if selected_job == "builder":
		_try_assign_builder(minion)
		return

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


func _try_assign_builder(minion: Node) -> void:
	if builders_remaining <= 0 or not minion.has_method("can_become_builder") or not minion.can_become_builder():
		return
	builders_remaining -= 1
	sfx_requested.emit("bone_clack")
	minion_spawned.emit(minion)
	_run_builder_sequence(minion)

func _run_builder_sequence(minion: Node) -> void:
	if not is_instance_valid(minion) or not minion.has_method("set_builder_active"):
		return
	minion.set_builder_active(true)
	var facing := signf(float(minion.get("direction")))
	if facing == 0.0:
		facing = 1.0
	var start: Vector2 = minion.global_position
	var anchor := _get_builder_anchor(start, facing)
	for i in BUILDER_PIECE_COUNT:
		if not is_instance_valid(minion) or minion.get("alive") != true or minion.get("rescued") == true:
			return
		var center := anchor + Vector2(
			facing * BUILDER_PIECE_SPACING * float(i),
			-BUILDER_STEP_RISE * float(i)
		)
		if minion.has_method("play_builder_build_pulse"):
			minion.play_builder_build_pulse(BUILDER_WINDUP_SECONDS + BUILDER_THROW_DURATION)
		await get_tree().create_timer(BUILDER_WINDUP_SECONDS).timeout
		if not is_instance_valid(minion) or minion.get("alive") != true or minion.get("rescued") == true:
			return
		await _animate_builder_throw(minion, center, facing, i + 1)
		if not is_instance_valid(minion) or minion.get("alive") != true or minion.get("rescued") == true:
			return
		_add_builder_piece(center, facing, i + 1)
		sfx_requested.emit("bone_clack")
		await get_tree().create_timer(BUILDER_SETTLE_SECONDS).timeout
	if is_instance_valid(minion) and minion.has_method("set_builder_active"):
		minion.set_builder_active(false)
		minion_spawned.emit(minion)

func _get_builder_anchor(minion_position: Vector2, facing: float) -> Vector2:
	# Build from the skeleton that was clicked, not from the far platform lip. Keep
	# the vertical placement on the floor it is standing on so the first rib is
	# walkable instead of being centered on the skeleton's torso.
	var y := minion_position.y + BUILDER_PIECE_SIZE.y * 0.5
	var terrain := get_node_or_null("../TerrainRoot")
	if terrain != null:
		var support := _find_support_rect(terrain, minion_position)
		if support.size != Vector2.ZERO:
			y = support.position.y - (BUILDER_PIECE_SIZE.y * 0.5)
	return Vector2(minion_position.x + facing * BUILDER_PIECE_SPACING, y)

func _animate_builder_throw(minion: Node, target: Vector2, facing: float, index: int) -> void:
	var terrain := get_node_or_null("../TerrainRoot")
	var parent_node: Node = terrain if terrain != null else self
	var throw_visual := Line2D.new()
	throw_visual.name = "BuilderThrownRib%d" % index
	throw_visual.default_color = Color(1.0, 0.88, 0.56, 0.92)
	throw_visual.width = 3.0
	throw_visual.points = PackedVector2Array([Vector2(-10.0 * facing, 0.0), Vector2(10.0 * facing, -2.0)])
	throw_visual.global_position = minion.global_position + Vector2(BUILDER_HAND_OFFSET.x * facing, BUILDER_HAND_OFFSET.y)
	throw_visual.rotation = -0.25 * facing
	parent_node.add_child(throw_visual)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(throw_visual, "global_position", target, BUILDER_THROW_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(throw_visual, "rotation", throw_visual.rotation + facing * 2.4, BUILDER_THROW_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(throw_visual, "scale", Vector2(1.25, 1.25), BUILDER_THROW_DURATION * 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(throw_visual, "scale", Vector2(0.92, 0.92), BUILDER_THROW_DURATION * 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN).set_delay(BUILDER_THROW_DURATION * 0.45)
	tween.tween_property(throw_visual, "modulate", Color(1.0, 1.0, 1.0, 0.25), BUILDER_THROW_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished
	if is_instance_valid(throw_visual):
		throw_visual.queue_free()

func _find_support_rect(terrain: Node, minion_position: Vector2) -> Rect2:
	var rects: Array = terrain.get("collision_rects")
	var best := Rect2()
	var best_y_distance := INF
	for rect: Rect2 in rects:
		var within_x := minion_position.x >= rect.position.x - 4.0 and minion_position.x <= rect.end.x + 4.0
		if not within_x:
			continue
		var y_distance := absf(rect.position.y - minion_position.y)
		if y_distance <= BUILDER_SUPPORT_Y_TOLERANCE and y_distance < best_y_distance:
			best = rect
			best_y_distance = y_distance
	return best

func _add_builder_piece(center: Vector2, facing: float, index: int) -> void:
	var terrain := get_node_or_null("../TerrainRoot")
	var parent_node: Node = terrain if terrain != null else self
	if terrain != null:
		var built_rect := Rect2(center - BUILDER_PIECE_SIZE / 2.0, BUILDER_PIECE_SIZE)
		var rects: Array = terrain.get("collision_rects")
		rects.append(built_rect)
		terrain.set("collision_rects", rects)
	var body := StaticBody2D.new()
	body.name = "BuilderRibPiece%d" % index
	body.global_position = center
	body.collision_layer = 1
	body.collision_mask = 0
	parent_node.add_child(body)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = BUILDER_PIECE_SIZE
	shape.shape = rect
	body.add_child(shape)

	var visual := Polygon2D.new()
	visual.name = "Visual"
	visual.color = Color(0.78, 0.66, 0.46, 0.96)
	visual.polygon = PackedVector2Array([
		-BUILDER_PIECE_SIZE / 2.0,
		Vector2(BUILDER_PIECE_SIZE.x / 2.0, -BUILDER_PIECE_SIZE.y / 2.0),
		BUILDER_PIECE_SIZE / 2.0,
		Vector2(-BUILDER_PIECE_SIZE.x / 2.0, BUILDER_PIECE_SIZE.y / 2.0),
	])
	body.add_child(visual)

	var rib := Line2D.new()
	rib.default_color = Color(1.0, 0.90, 0.68, 0.86)
	rib.width = 2.0
	rib.points = PackedVector2Array([Vector2(-11.0 * facing, 0), Vector2(11.0 * facing, -1)])
	body.add_child(rib)

func all_done() -> bool:
	# A placed blocker can remain braced after the crowd is safe; don't let that
	# strand the tutorial level in a never-ending state.
	var blockers_alive := get_tree().get_nodes_in_group("blockers").size()
	return _spawn_started and _spawning_done and active_count <= blockers_alive
