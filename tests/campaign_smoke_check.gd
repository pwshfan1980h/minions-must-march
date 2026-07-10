extends SceneTree

const LevelState := preload("res://scripts/core/level_state.gd")
const LEVEL_SCENE := preload("res://scenes/LevelController.tscn")
const WORLD_BOUNDS := Rect2(0, 0, 2400, 720)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var levels := LevelState.all_levels()
	if levels.size() != 12:
		_fail("Expected 12 campaign levels, found %d" % levels.size())
		return

	for cfg in levels:
		var number := int(cfg["number"])
		LevelState.goto(number)
		var level := LEVEL_SCENE.instantiate()
		root.add_child(level)
		await process_frame

		var minions: Node = level.get_node("MinionRoot")
		var terrain: Node = level.get_node("TerrainRoot")
		var objects: Node = level.get_node("ObjectRoot")
		if terrain.collision_rects.size() < 3:
			_fail("L%03d has too little collision geometry" % number)
			return
		if minions.total_to_spawn != int(cfg["minions"]):
			_fail("L%03d minion count did not load from campaign config" % number)
			return
		if int(cfg["rescue_required"]) > minions.total_to_spawn:
			_fail("L%03d asks for more rescues than it spawns" % number)
			return
		if not WORLD_BOUNDS.has_point(cfg["spawn_position"]) or not WORLD_BOUNDS.has_point(cfg["exit_position"]):
			_fail("L%03d spawn or exit lies outside the world" % number)
			return
		if not _has_nearby_platform(terrain.collision_rects, cfg["spawn_position"], 52.0):
			_fail("L%03d spawn has no nearby landing platform" % number)
			return
		if not _has_nearby_platform(terrain.collision_rects, cfg["exit_position"], 52.0):
			_fail("L%03d exit has no supporting platform" % number)
			return
		if objects.exit_area == null:
			_fail("L%03d did not create an exit trigger" % number)
			return
		if int(cfg.get("diggers", 0)) > 0 and terrain.diggable_plugs.is_empty():
			_fail("L%03d provides DIG but has no diggable floor" % number)
			return

		level.queue_free()
		await process_frame
		print("PASS L%03d %s" % [number, cfg["name"]])

	print("PASS: all 12 campaign chambers boot with valid objectives, tools, spawn landings, and exits")
	quit(0)

func _has_nearby_platform(rects: Array, point: Vector2, vertical_tolerance: float) -> bool:
	for rect: Rect2 in rects:
		var x_near := point.x >= rect.position.x - 36.0 and point.x <= rect.end.x + 36.0
		var y_near := absf(point.y - rect.position.y) <= vertical_tolerance
		if x_near and y_near:
			return true
	return false

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
