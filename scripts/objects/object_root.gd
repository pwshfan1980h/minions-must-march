extends Node2D

signal minion_entered_exit(minion: Node)
signal spawn_portal_clicked

const EXIT_LIGHT_HEIGHT := 210.0
const EXIT_LIGHT_WIDTH := 68.0
const EXIT_REDRAW_FPS := 30.0

var spawn_portal_pos := Vector2(232, 382)
var exit_area: Area2D
var exit_position := Vector2.ZERO
var _time := 0.0
var _redraw_elapsed := 0.0
var _mote_specs: Array[Dictionary] = []
var _spawn_portal_waiting := false
var _spawn_portal_voom := 0.0
var _spawn_portal_area: Area2D

func _ready() -> void:
	_build_motes()
	_build_placeholder_objects()
	queue_redraw()

func _process(delta: float) -> void:
	_time += delta
	_redraw_elapsed += delta
	if _spawn_portal_voom > 0.0:
		_spawn_portal_voom = maxf(0.0, _spawn_portal_voom - delta * 1.9)
	if _redraw_elapsed >= 1.0 / EXIT_REDRAW_FPS:
		_redraw_elapsed = 0.0
		queue_redraw()

func _build_placeholder_objects() -> void:
	var cfg: Dictionary = LevelState.config()
	# Portal sits slightly above and behind the minion spawn point so skeletons
	# tumble out of it onto the platform below.
	var spawn_pos: Vector2 = cfg.get("spawn_position", Vector2(220, 420))
	var spawn_dir: float = float(cfg.get("spawn_direction", 1))
	spawn_portal_pos = spawn_pos + Vector2(-spawn_dir * 12.0, -38.0)
	_add_spawn_portal()
	_add_exit(cfg.get("exit_position", Vector2(1210, 400)))

func _add_spawn_portal() -> void:
	_spawn_portal_area = Area2D.new()
	_spawn_portal_area.name = "SpawnPortalClickArea"
	_spawn_portal_area.position = spawn_portal_pos
	_spawn_portal_area.collision_layer = 4
	_spawn_portal_area.collision_mask = 0
	_spawn_portal_area.input_pickable = _spawn_portal_waiting
	_spawn_portal_area.monitoring = false
	_spawn_portal_area.monitorable = false
	_spawn_portal_area.input_event.connect(_on_spawn_portal_input_event)
	add_child(_spawn_portal_area)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(96, 112)
	shape.shape = rect
	shape.disabled = not _spawn_portal_waiting
	_spawn_portal_area.add_child(shape)

func _on_spawn_portal_input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if not _spawn_portal_waiting:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_spawn_portal_waiting = false
		_spawn_portal_voom = 1.0
		if _spawn_portal_area != null:
			_spawn_portal_area.set_deferred("input_pickable", false)
			var shape := _spawn_portal_area.get_node_or_null("CollisionShape2D")
			if shape != null:
				shape.set_deferred("disabled", true)
		spawn_portal_clicked.emit()
		queue_redraw()

func _add_builder_demo_label(_pos: Vector2) -> void:
	# Keep tutorial text out of the playable gap. The level itself should show
	# the empty Styx gap and gold build marker without labels covering them.
	var label := Label.new()
	label.name = "BuilderDemoHint"
	label.position = Vector2(150, 118)
	label.size = Vector2(520, 52)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = "BUILDER DEMO #1 — Press 2, then click a skeleton near the gold line to build the rib bridge."
	label.add_theme_color_override("font_color", Color(0.94, 0.84, 0.58, 0.88))
	label.add_theme_font_size_override("font_size", 16)
	add_child(label)

func _add_exit(pos: Vector2) -> void:
	exit_position = pos
	exit_area = Area2D.new()
	exit_area.name = "ExitLightArea"
	exit_area.position = pos
	exit_area.collision_layer = 0
	exit_area.collision_mask = 2
	exit_area.body_entered.connect(_on_exit_body_entered)
	add_child(exit_area)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(62, 96)
	shape.shape = rect
	shape.position = Vector2(0, -42)
	exit_area.add_child(shape)

func _build_motes() -> void:
	_mote_specs.clear()
	for i in 18:
		_mote_specs.append({
			"x": -34.0 + float((i * 19) % 69),
			"phase": float(i) * 0.57,
			"speed": 0.55 + float((i * 7) % 9) * 0.055,
			"size": 1.2 + float((i * 5) % 8) * 0.18,
			"drift": -7.0 + float((i * 13) % 15),
		})

func _draw() -> void:
	_draw_spawn_portal()
	if exit_position == Vector2.ZERO:
		return
	_draw_exit_light(exit_position)

func _draw_spawn_portal() -> void:
	# The portal is now decorative only: minions march immediately when the level
	# loads, but keeping the green crypt gate grounds the spawn point visually.
	var pulse := 0.5 + sin(_time * 3.6) * 0.5
	var voom := _spawn_portal_voom
	var alpha := clampf(1.0 if _spawn_portal_waiting else 0.72 + pulse * 0.10 + voom * 0.18, 0.0, 1.0)
	var squash := Vector2(1.0 + voom * 0.85, 1.0 - voom * 0.55)
	var pos := spawn_portal_pos + Vector2(voom * 34.0, -voom * 8.0)
	draw_set_transform(pos, voom * 0.45, squash)

	draw_circle(Vector2.ZERO, 60.0 + pulse * 5.0, Color(0.40, 0.90, 0.38, (0.09 + pulse * 0.06) * alpha))
	draw_circle(Vector2(0, 4), 42.0 + pulse * 3.0, Color(0.78, 0.95, 0.45, (0.12 + pulse * 0.07) * alpha))
	_draw_soft_ellipse(Rect2(Vector2(-31, -42), Vector2(62, 84)), Color(0.08, 0.055, 0.11, 0.94 * alpha))
	_draw_soft_ellipse(Rect2(Vector2(-22, -31), Vector2(44, 62)), Color(0.28, 0.78, 0.34, (0.22 + pulse * 0.09) * alpha))
	for i in 5:
		var a := _time * (1.8 + i * 0.18) + float(i) * 1.21
		var r := 13.0 + float(i) * 5.2 + pulse * 2.0
		draw_arc(Vector2.ZERO, r, a, a + PI * 0.82, 18, Color(0.78, 1.0, 0.45, (0.26 - i * 0.027) * alpha), 2.0)

	var stones := [Vector2(-35,-38), Vector2(-12,-52), Vector2(16,-50), Vector2(38,-28), Vector2(43,3), Vector2(31,35), Vector2(2,49), Vector2(-29,40), Vector2(-44,8)]
	for i in stones.size():
		var stone: Vector2 = stones[i]
		draw_circle(stone, 7.0 + float(i % 3), Color(0.40, 0.34, 0.44, 0.96 * alpha))
		draw_circle(stone + Vector2(-1, -1), 4.0 + float(i % 2), Color(0.62, 0.53, 0.56, 0.56 * alpha))
	for i in 6:
		var y := -25.0 + i * 10.0
		draw_line(Vector2(-22.0 + i * 1.4, y), Vector2(20.0 + i * 2.5, y + 5.0), Color(0.86, 0.77, 0.58, 0.42 * alpha), 2.0, true)
	if _spawn_portal_waiting:
		var chevron_y := 67.0 + sin(_time * 4.0) * 3.0
		draw_line(Vector2(-16, chevron_y), Vector2(0, chevron_y + 9), Color(0.95, 0.83, 0.34, 0.62), 2.0)
		draw_line(Vector2(16, chevron_y), Vector2(0, chevron_y + 9), Color(0.95, 0.83, 0.34, 0.62), 2.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_spawn_chute_dust(spawn_portal_pos + Vector2(0, 38))

func _draw_spawn_chute_dust(pos: Vector2) -> void:
	for i in 7:
		var phase := _time * (0.42 + i * 0.035) + i * 0.71
		var origin := pos + Vector2(8.0 + sin(phase) * 24.0, -22.0 + cos(phase * 0.8) * 12.0)
		var points := PackedVector2Array()
		for j in 5:
			var t := float(j) / 4.0
			points.append(origin + Vector2(sin(phase + t * 4.0) * (5.0 + t * 12.0), -t * (18.0 + float(i % 3) * 5.0)))
		draw_polyline(points, Color(0.46, 0.42, 0.38, 0.06), 1.4, true)

func _draw_exit_light(pos: Vector2) -> void:
	var base := pos + Vector2(0, 12)
	var top := base + Vector2(0, -EXIT_LIGHT_HEIGHT)

	# A soft vertical pillar: loosely afterlife/pop-culture ascension, not an explicit symbol.
	var outer := PackedVector2Array([
		base + Vector2(-EXIT_LIGHT_WIDTH * 0.68, 0),
		base + Vector2(EXIT_LIGHT_WIDTH * 0.68, 0),
		top + Vector2(EXIT_LIGHT_WIDTH * 0.28, -20),
		top + Vector2(-EXIT_LIGHT_WIDTH * 0.28, -20),
	])
	draw_colored_polygon(outer, Color(0.54, 0.82, 0.78, 0.105))

	var core := PackedVector2Array([
		base + Vector2(-EXIT_LIGHT_WIDTH * 0.32, 0),
		base + Vector2(EXIT_LIGHT_WIDTH * 0.32, 0),
		top + Vector2(EXIT_LIGHT_WIDTH * 0.13, -28),
		top + Vector2(-EXIT_LIGHT_WIDTH * 0.13, -28),
	])
	draw_colored_polygon(core, Color(0.86, 0.95, 0.78, 0.19))

	for i in 5:
		var t := float(i) / 4.0
		var y := lerpf(base.y, top.y - 18.0, t)
		var width := lerpf(62.0, 18.0, t)
		var alpha := lerpf(0.12, 0.025, t)
		var shard := PackedVector2Array([
			Vector2(pos.x - width * 0.42, y),
			Vector2(pos.x - width * 0.14, y - 7.0),
			Vector2(pos.x + width * 0.38, y - 3.0),
			Vector2(pos.x + width * 0.18, y + 6.0),
		])
		draw_colored_polygon(shard, Color(0.95, 0.95, 0.72, alpha))

	var base_glow := PackedVector2Array([
		Vector2(pos.x - 42.0, base.y - 7.0),
		Vector2(pos.x - 10.0, base.y - 18.0),
		Vector2(pos.x + 36.0, base.y - 4.0),
		Vector2(pos.x + 18.0, base.y + 8.0),
		Vector2(pos.x - 30.0, base.y + 6.0),
	])
	draw_colored_polygon(base_glow, Color(0.78, 0.95, 0.70, 0.14))

	for spec in _mote_specs:
		var phase := _time * float(spec["speed"]) + float(spec["phase"])
		var cycle := fposmod(phase, 1.0)
		var y := lerpf(base.y + 8.0, top.y - 42.0, cycle)
		var x := pos.x + float(spec["x"]) + sin(phase * TAU) * float(spec["drift"])
		var alpha := sin(cycle * PI) * 0.58
		var size := float(spec["size"]) * (0.75 + sin(phase * TAU * 0.7) * 0.18)
		draw_circle(Vector2(x, y), size * 2.8, Color(0.55, 0.88, 0.76, alpha * 0.14))
		draw_circle(Vector2(x, y), size, Color(0.95, 0.96, 0.76, alpha * 0.42))

func _draw_soft_ellipse(rect: Rect2, color: Color) -> void:
	var points := PackedVector2Array()
	var center := rect.get_center()
	var radius := rect.size / 2.0
	for i in 28:
		var angle := TAU * float(i) / 28.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)

func _on_exit_body_entered(body: Node) -> void:
	if body.is_in_group("minions") and body.has_method("rescue"):
		minion_entered_exit.emit(body)
		body.rescue(exit_position)
