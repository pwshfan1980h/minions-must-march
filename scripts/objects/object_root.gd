extends Node2D

signal minion_entered_exit(minion: Node)

const EXIT_LIGHT_HEIGHT := 210.0
const EXIT_LIGHT_WIDTH := 68.0
const EXIT_REDRAW_FPS := 30.0

var exit_area: Area2D
var exit_position := Vector2.ZERO
var _time := 0.0
var _redraw_elapsed := 0.0
var _mote_specs: Array[Dictionary] = []

func _ready() -> void:
	_build_motes()
	_build_placeholder_objects()
	queue_redraw()

func _process(delta: float) -> void:
	_time += delta
	_redraw_elapsed += delta
	if _redraw_elapsed >= 1.0 / EXIT_REDRAW_FPS:
		_redraw_elapsed = 0.0
		queue_redraw()

func _build_placeholder_objects() -> void:
	_add_spawn_marker(Vector2(520, 420))
	_add_exit(Vector2(584, 448))

func _add_spawn_marker(pos: Vector2) -> void:
	var marker := Label.new()
	marker.position = pos + Vector2(-18, -66)
	marker.text = "S"
	marker.add_theme_color_override("font_color", Color("4a8be8"))
	marker.add_theme_font_size_override("font_size", 32)
	add_child(marker)

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
	if exit_position == Vector2.ZERO:
		return
	_draw_exit_light(exit_position)

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
		_draw_soft_ellipse(Rect2(pos.x - width / 2.0, y - 5.0, width, 10.0), Color(0.95, 0.95, 0.72, alpha))

	_draw_soft_ellipse(Rect2(pos.x - 34.0, base.y - 8.0, 68.0, 18.0), Color(0.78, 0.95, 0.70, 0.17))

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
