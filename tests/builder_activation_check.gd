extends SceneTree

const GAME_ROOT_SCENE := preload("res://scenes/GameRoot.tscn")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_root := GAME_ROOT_SCENE.instantiate()
	root.add_child(game_root)

	await process_frame
	await process_frame

	var level := game_root.get_node("LevelController")
	var minion_root := level.get_node("MinionRoot")
	var minion: Node = null

	for _i in 180:
		await process_frame
		if minion_root.spawned_count > 0:
			minion = minion_root.get_child(0)
			if minion != null and minion.has_method("is_on_floor") and minion.is_on_floor():
				break

	if minion == null:
		_fail("No minion spawned for Builder activation check")
		return
	if not minion.is_on_floor():
		_fail("Spawned minion never reached floor for Builder activation check")
		return

	minion_root.set_selected_job("builder")
	minion_root._on_minion_clicked(minion)

	await create_timer(1.35).timeout

	if minion_root.builders_remaining != 0:
		_fail("Builder charge was not consumed")
		return

	var terrain := level.get_node("TerrainRoot")
	var built_pieces := 0
	for child in terrain.get_children():
		if String(child.name).begins_with("BuilderRibPiece"):
			built_pieces += 1

	if built_pieces != 6:
		_fail("Expected 6 BuilderRibPiece nodes, got %d" % built_pieces)
		return

	var first_piece := terrain.get_node_or_null("BuilderRibPiece1")
	var last_piece := terrain.get_node_or_null("BuilderRibPiece6")
	if first_piece == null or last_piece == null:
		_fail("Could not find first/last Builder rib pieces")
		return
	if first_piece.global_position.distance_to(Vector2(814, 444)) > 0.5:
		_fail("First Builder rib did not snap to source platform lip: %s" % first_piece.global_position)
		return
	if last_piece.global_position.distance_to(Vector2(934, 404)) > 0.5:
		_fail("Last Builder rib did not climb toward landing platform: %s" % last_piece.global_position)
		return

	print("PASS: Builder activation consumed one charge and created six snapped rib pieces")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
