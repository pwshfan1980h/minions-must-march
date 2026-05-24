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
@export var diggers_available := 0
@export var featherfalls_available := 0
@export var wait_for_start := false

var selected_job := "builder"
var spawned_count := 0
var active_count := 0
var rescued_count := 0
var lost_count := 0
var blockers_remaining := 0
var builders_remaining := 0
var diggers_remaining := 0
var featherfalls_remaining := 0
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
const BUILDER_CROSSFADE_SECONDS := 0.12
const BUILDER_PIECE_COLOR := Color(0.78, 0.66, 0.46, 0.96)
const BUILDER_THROW_COLOR := Color(1.00, 0.88, 0.56, 0.95)

func _ready() -> void:
	var cfg: Dictionary = LevelState.config()
	total_to_spawn = int(cfg.get("minions", total_to_spawn))
	spawn_interval = float(cfg.get("spawn_interval", spawn_interval))
	blockers_available = int(cfg.get("blockers", blockers_available))
	builders_available = int(cfg.get("builders", builders_available))
	diggers_available = int(cfg.get("diggers", diggers_available))
	featherfalls_available = int(cfg.get("featherfalls", featherfalls_available))
	spawn_position = cfg.get("spawn_position", spawn_position)
	spawn_direction = float(cfg.get("spawn_direction", spawn_direction))
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
	diggers_remaining = diggers_available
	featherfalls_remaining = featherfalls_available
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
	_refresh_target_affordances()

func _on_minion_exited(minion: Node) -> void:
	rescued_count += 1
	active_count = max(0, active_count - 1)
	sfx_requested.emit("exit_rescue")
	minion_rescued.emit(minion)
	_refresh_target_affordances()

func _on_minion_death_started(_minion: Node, death_kind: String) -> void:
	if _minion.has_method("death_voice_id"):
		sfx_requested.emit(_minion.death_voice_id())
	else:
		sfx_requested.emit("death_yelp_wiry")
	sfx_requested.emit("death_knell")
	if death_kind == "styx_water":
		sfx_requested.emit("styx_impact")
	sfx_requested.emit("bone_splash")

func _on_minion_died(minion: Node) -> void:
	lost_count += 1
	active_count = max(0, active_count - 1)
	minion_lost.emit(minion)
	_refresh_target_affordances()

func set_debug_click_areas(enabled: bool) -> void:
	debug_click_areas = enabled
	for minion in get_tree().get_nodes_in_group("minions"):
		if minion.has_method("set_debug_click_area"):
			minion.set_debug_click_area(enabled)

func set_selected_job(job_id: String) -> void:
	selected_job = job_id
	_refresh_target_affordances()

func _refresh_target_affordances() -> void:
	for minion in get_tree().get_nodes_in_group("minions"):
		if not minion.has_method("set_target_affordance"):
			continue
		var valid := _is_valid_target_for_selected_job(minion)
		minion.set_target_affordance(selected_job, valid)

func _is_valid_target_for_selected_job(minion: Node) -> bool:
	if selected_job == "builder":
		return builders_remaining > 0 and minion.has_method("can_become_builder") and minion.can_become_builder()
	if selected_job == "digger":
		if diggers_remaining <= 0 or not minion.has_method("can_become_digger") or not minion.can_become_digger():
			return false
		var terrain := get_node_or_null("../TerrainRoot")
		if terrain == null or not terrain.has_method("find_diggable_plug_at"):
			return false
		return not terrain.find_diggable_plug_at(minion.global_position).is_empty()
	if selected_job == "blocker":
		if minion.get("is_blocker") == true:
			return true
		return blockers_remaining > 0 and minion.has_method("become_blocker") and minion.get("alive") == true and minion.get("rescued") == false and minion.is_on_floor()
	if selected_job == "featherfall":
		return featherfalls_remaining > 0 and minion.has_method("can_receive_featherfall") and minion.can_receive_featherfall()
	return false

func _on_minion_clicked(minion: Node) -> void:
	if not _is_valid_target_for_selected_job(minion):
		if minion.has_method("flash_invalid_target"):
			minion.flash_invalid_target()
		return
	if selected_job == "builder":
		_try_assign_builder(minion)
		return

	if selected_job == "digger":
		_try_assign_digger(minion)
		return

	if selected_job == "featherfall":
		_try_assign_featherfall(minion)
		return

	if selected_job != "blocker":
		return

	if minion.get("is_blocker") == true and minion.has_method("resume_march"):
		if minion.resume_march():
			blockers_remaining = mini(blockers_remaining + 1, blockers_available)
			sfx_requested.emit("resume_march")
			minion_spawned.emit(minion)
			_refresh_target_affordances()
		return

	if blockers_remaining <= 0 or not minion.has_method("become_blocker"):
		return
	if minion.become_blocker():
		blockers_remaining -= 1
		sfx_requested.emit("command_clatter")
		sfx_requested.emit("bone_clack")
		sfx_requested.emit("blocker_brace")
		minion_spawned.emit(minion)
		_refresh_target_affordances()


func _try_assign_featherfall(minion: Node) -> void:
	if featherfalls_remaining <= 0 or not minion.has_method("can_receive_featherfall") or not minion.can_receive_featherfall():
		return
	if not minion.activate_featherfall():
		return
	featherfalls_remaining -= 1
	sfx_requested.emit("command_clatter")
	sfx_requested.emit("bone_clack")
	minion_spawned.emit(minion)
	_refresh_target_affordances()

func _try_assign_digger(minion: Node) -> void:
	if diggers_remaining <= 0 or not minion.has_method("can_become_digger") or not minion.can_become_digger():
		return
	var terrain := get_node_or_null("../TerrainRoot")
	if terrain == null or not terrain.has_method("find_diggable_plug_at") or not terrain.has_method("remove_diggable_plug"):
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
	_refresh_target_affordances()

func _try_assign_builder(minion: Node) -> void:
	if builders_remaining <= 0 or not minion.has_method("can_become_builder") or not minion.can_become_builder():
		return
	builders_remaining -= 1
	sfx_requested.emit("command_clatter")
	sfx_requested.emit("bone_clack")
	minion_spawned.emit(minion)
	_refresh_target_affordances()
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
		var throw_visual: Line2D = await _animate_builder_throw(minion, center, facing, i + 1)
		if not is_instance_valid(minion) or minion.get("alive") != true or minion.get("rescued") == true:
			if is_instance_valid(throw_visual):
				throw_visual.queue_free()
			return
		var piece := _add_builder_piece(center, facing, i + 1)
		_crossfade_to_piece(throw_visual, piece)
		sfx_requested.emit("bone_clack")
		await get_tree().create_timer(BUILDER_SETTLE_SECONDS).timeout
	if is_instance_valid(minion) and minion.has_method("set_builder_active"):
		minion.set_builder_active(false)
		minion_spawned.emit(minion)
		_refresh_target_affordances()

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

func _animate_builder_throw(minion: Node, target: Vector2, facing: float, index: int) -> Line2D:
	# The thrown rib is a rounded-cap bone shaft, same silhouette as the placed
	# piece's bone visual. Starts small at the builder's hand and grows to full
	# size mid-air; the placed piece then cross-fades in at the same position so
	# the silhouette never pops.
	var terrain := get_node_or_null("../TerrainRoot")
	var parent_node: Node = terrain if terrain != null else self
	var half := BUILDER_PIECE_SIZE * 0.5
	var throw_visual := Line2D.new()
	throw_visual.name = "BuilderThrownRib%d" % index
	throw_visual.points = PackedVector2Array([
		Vector2(-facing * half.x, half.y),
		Vector2(-facing * half.x + facing * BUILDER_PIECE_SPACING, -half.y),
	])
	throw_visual.width = 4.6
	throw_visual.default_color = BUILDER_THROW_COLOR
	throw_visual.begin_cap_mode = Line2D.LINE_CAP_ROUND
	throw_visual.end_cap_mode = Line2D.LINE_CAP_ROUND
	throw_visual.global_position = minion.global_position + Vector2(BUILDER_HAND_OFFSET.x * facing, BUILDER_HAND_OFFSET.y)
	throw_visual.rotation = -0.45 * facing
	throw_visual.scale = Vector2(0.45, 0.45)
	parent_node.add_child(throw_visual)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(throw_visual, "global_position", target, BUILDER_THROW_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(throw_visual, "rotation", 0.0, BUILDER_THROW_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(throw_visual, "scale", Vector2.ONE, BUILDER_THROW_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished
	return throw_visual

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

func _add_builder_piece(center: Vector2, facing: float, index: int) -> StaticBody2D:
	# Each piece is a parallelogram whose near-side edge slopes at the bridge's
	# overall pitch (BUILDER_STEP_RISE rise per BUILDER_PIECE_SPACING run). Stacked
	# end-to-end, the pieces' near-edges form one continuous slope, so a skeleton
	# walks up the bridge as if on a ramp instead of vaulting up each step.
	var half := BUILDER_PIECE_SIZE * 0.5
	var slope_run := BUILDER_PIECE_SPACING
	var poly_points := PackedVector2Array([
		Vector2(-facing * half.x, half.y),
		Vector2(-facing * half.x + facing * slope_run, -half.y),
		Vector2(facing * half.x, -half.y),
		Vector2(facing * half.x, half.y),
	])
	var terrain := get_node_or_null("../TerrainRoot")
	var parent_node: Node = terrain if terrain != null else self
	if terrain != null:
		var built_rect := Rect2(center - half, BUILDER_PIECE_SIZE)
		var rects: Array = terrain.get("collision_rects")
		rects.append(built_rect)
		terrain.set("collision_rects", rects)
	var body := StaticBody2D.new()
	body.name = "BuilderRibPiece%d" % index
	body.global_position = center
	body.collision_layer = 1
	body.collision_mask = 0
	body.modulate.a = 0.0
	parent_node.add_child(body)

	var shape := CollisionPolygon2D.new()
	shape.polygon = poly_points
	body.add_child(shape)

	# Each piece is drawn as a tapered bone: thin shaft, big knuckle balls at
	# each end. Adjacent pieces' knuckles overlap exactly at the slope junctions,
	# so the chain reads as discrete ribs meeting at joints rather than one long
	# stick.
	var bone_a := Vector2(-facing * half.x, half.y)
	var bone_b := Vector2(-facing * half.x + facing * slope_run, -half.y)
	var shadow_offset := Vector2(0.0, 1.4)

	var shadow := Line2D.new()
	shadow.name = "Shadow"
	shadow.points = PackedVector2Array([bone_a + shadow_offset, bone_b + shadow_offset])
	shadow.width = 4.0
	shadow.default_color = Color(0.30, 0.22, 0.14, 0.50)
	shadow.begin_cap_mode = Line2D.LINE_CAP_ROUND
	shadow.end_cap_mode = Line2D.LINE_CAP_ROUND
	body.add_child(shadow)

	var shaft := Line2D.new()
	shaft.name = "Shaft"
	shaft.points = PackedVector2Array([bone_a, bone_b])
	shaft.width = 3.4
	shaft.default_color = BUILDER_PIECE_COLOR
	shaft.begin_cap_mode = Line2D.LINE_CAP_NONE
	shaft.end_cap_mode = Line2D.LINE_CAP_NONE
	body.add_child(shaft)

	var knuckle_polygon := PackedVector2Array()
	var knuckle_radius := 3.2
	var knuckle_segments := 14
	for k in knuckle_segments:
		var angle := float(k) * TAU / float(knuckle_segments)
		knuckle_polygon.append(Vector2(cos(angle), sin(angle)) * knuckle_radius)
	var knuckle_color := BUILDER_PIECE_COLOR.lightened(0.08)
	for endpoint in [bone_a, bone_b]:
		var knuckle_shadow := Polygon2D.new()
		knuckle_shadow.name = "KnuckleShadow"
		knuckle_shadow.position = endpoint + shadow_offset
		knuckle_shadow.polygon = knuckle_polygon
		knuckle_shadow.color = Color(0.30, 0.22, 0.14, 0.50)
		body.add_child(knuckle_shadow)
		var knuckle := Polygon2D.new()
		knuckle.name = "Knuckle"
		knuckle.position = endpoint
		knuckle.polygon = knuckle_polygon
		knuckle.color = knuckle_color
		body.add_child(knuckle)
	return body

func _crossfade_to_piece(throw_visual: Line2D, piece: StaticBody2D) -> void:
	# Hand the airborne rib off to its placed counterpart by alpha-swapping in
	# place — same shape, same position, just a quick brightness settle from the
	# warm thrown color to the duller structural color. Avoids the silhouette
	# pop that happens when one node disappears and another appears in a frame.
	if not is_instance_valid(throw_visual) or not is_instance_valid(piece):
		return
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(throw_visual, "modulate:a", 0.0, BUILDER_CROSSFADE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(piece, "modulate:a", 1.0, BUILDER_CROSSFADE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(throw_visual.queue_free)


func all_done() -> bool:
	# A placed blocker can remain braced after the crowd is safe; don't let that
	# strand the tutorial level in a never-ending state.
	var blockers_alive := get_tree().get_nodes_in_group("blockers").size()
	return _spawn_started and _spawning_done and active_count <= blockers_alive
