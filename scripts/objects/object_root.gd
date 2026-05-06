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
	_add_spawn_chute(Vector2(220, 420))
	_add_builder_demo_label(Vector2(760, 360))
	_add_exit(Vector2(1210, 400))

func _add_spawn_chute(pos: Vector2) -> void:
	var chute := Node2D.new()
	chute.name = "CryptChuteSpawn"
	chute.position = pos + Vector2(12, -38)
	add_child(chute)

	var mouth := Polygon2D.new()
	mouth.color = Color(0.10, 0.075, 0.12, 0.95)
	mouth.polygon = PackedVector2Array([Vector2(-42,-30), Vector2(30,-24), Vector2(38,26), Vector2(-34,34)])
	chute.add_child(mouth)

	var rim := Line2D.new()
	rim.default_color = Color(0.42, 0.35, 0.45, 0.95)
	rim.width = 4.0
	rim.closed = true
	rim.points = PackedVector2Array([Vector2(-42,-30), Vector2(30,-24), Vector2(38,26), Vector2(-34,34)])
	chute.add_child(rim)

	var glow := Polygon2D.new()
	glow.color = Color(0.55, 0.90, 0.42, 0.16)
	glow.polygon = PackedVector2Array([Vector2(-24,-16), Vector2(18,-12), Vector2(24,18), Vector2(-20,22)])
	chute.add_child(glow)

	for i in 5:
		var bone := Line2D.new()
		bone.default_color = Color(0.80, 0.72, 0.56, 0.42)
		bone.width = 2.0
		var y := -16.0 + i * 10.0
		bone.points = PackedVector2Array([Vector2(-24.0 + i * 2.0, y), Vector2(14.0 + i * 3.0, y + 5.0)])
		chute.add_child(bone)


func _add_builder_demo_label(pos: Vector2) -> void:
	var label := Label.new()
	label.name = "BuilderDemoHint"
	label.position = pos
	label.text = "BUILDER DEMO #1\nStand near the gold line, select Builder, then click a right-facing skeleton.\nExpected: 6 rib pieces bridge this Styx gap."
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
	_draw_spawn_chute_dust(Vector2(220, 420))
	if exit_position == Vector2.ZERO:
		return
	_draw_exit_light(exit_position)

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
