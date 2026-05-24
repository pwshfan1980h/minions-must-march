extends SceneTree

const GAME_ROOT_SCENE := preload("res://scenes/GameRoot.tscn")
const DIG_PLUG_RECT := Rect2(584, 320, 96, 32)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	LevelState.goto(6)
	if LevelState.current_level != 6:
		_fail("Expected LevelState.goto(6) to select the Ash Catacombs Digger level")
		return

	var game_root := GAME_ROOT_SCENE.instantiate()
	root.add_child(game_root)

	await process_frame
	await process_frame

	var level := game_root.get_node("LevelController")
	var minion_root := level.get_node("MinionRoot")
	var terrain := level.get_node("TerrainRoot")

	if not terrain.has_method("find_diggable_plug_at") or not terrain.has_method("remove_diggable_plug"):
		_fail("TerrainRoot does not expose diggable plug lookup/removal")
		return
	if terrain.diggable_plugs.size() != 1:
		_fail("Expected exactly one diggable plug in L006, got %d" % terrain.diggable_plugs.size())
		return
	if not terrain.collision_rects.has(DIG_PLUG_RECT):
		_fail("Dig plug collision rect missing before DIG activation")
		return
	if int(minion_root.diggers_remaining) != 1:
		_fail("Expected one Digger charge before activation, got %d" % int(minion_root.diggers_remaining))
		return

	var invalid_probe: Dictionary = terrain.find_diggable_plug_at(Vector2(220, 292))
	if not invalid_probe.is_empty():
		_fail("Digger plug lookup should not match away from cracked ash floor")
		return

	var plug_probe: Dictionary = terrain.find_diggable_plug_at(Vector2(632, 320))
	if plug_probe.is_empty():
		_fail("Digger plug lookup should match a skeleton standing over the cracked ash floor")
		return

	minion_root.start_spawning()
	var minion: Node = null
	for _i in 180:
		await process_frame
		if minion_root.spawned_count > 0:
			minion = minion_root.get_child(0)
			break
	if minion == null:
		_fail("No minion spawned for Digger activation check")
		return

	var reached_plug := false
	for _walk in 1000:
		await physics_frame
		if minion.global_position.x >= 620.0 and minion.global_position.x <= 644.0 and minion.is_on_floor():
			reached_plug = true
			break
	if not reached_plug:
		_fail("Spawned minion did not reach the cracked ash floor while grounded; pos=%s on_floor=%s" % [minion.global_position, minion.is_on_floor()])
		return
	minion_root.set_selected_job("digger")
	minion_root._try_assign_digger(minion)

	await process_frame
	if int(minion_root.diggers_remaining) != 0:
		_fail("Digger charge was not consumed after valid DIG activation")
		return
	if terrain.diggable_plugs.size() != 0:
		_fail("Diggable plug was not removed after valid DIG activation")
		return
	if terrain.collision_rects.has(DIG_PLUG_RECT):
		_fail("Dig plug collision rect still exists after valid DIG activation")
		return

	minion_root._try_assign_digger(minion)
	if int(minion_root.diggers_remaining) != 0:
		_fail("Invalid second DIG changed Digger charge count")
		return

	print("PASS: Digger consumed one charge and removed the Ash Catacombs cracked floor plug")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
