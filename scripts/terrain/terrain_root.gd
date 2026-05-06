extends Node2D

const TILE_SIZE := 32
const WORLD_WIDTH := 1280
const PLAYFIELD_HEIGHT := 608
const STYX_WATERLINE_Y := 560.0
const STYX_DEPTH := 112.0
const TERRAIN_REDRAW_FPS := 30.0

var collision_rects: Array[Rect2] = []
var _time := 0.0
var _redraw_elapsed := 0.0
var _soul_specs: Array[Dictionary] = []

func _ready() -> void:
	_build_souls()
	_build_level_001_terrain()
	_add_styx_death_area()
	queue_redraw()

func _process(delta: float) -> void:
	_time += delta
	_redraw_elapsed += delta
	if _redraw_elapsed >= 1.0 / TERRAIN_REDRAW_FPS:
		_redraw_elapsed = 0.0
		queue_redraw()

func _build_level_001_terrain() -> void:
	# Current prototype layout: minions spawn on the right platform, can be redirected
	# by a blocker, and the bottom of the world is now River Styx-style death water.
	_add_solid(Rect2(96, 448, 544, 32), Color("3a3144"))
	_add_solid(Rect2(64, 480, 32, 96), Color("2a2432"))
	_add_solid(Rect2(608, 480, 32, 96), Color("2a2432"))

func _add_solid(rect: Rect2, color: Color) -> void:
	collision_rects.append(rect)

	var body := StaticBody2D.new()
	body.name = "CryptStoneBlock"
	body.position = rect.position + rect.size / 2.0
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)

	var shape := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = rect.size
	shape.shape = rect_shape
	body.add_child(shape)

	var visual := Polygon2D.new()
	visual.name = "Visual"
	visual.color = color
	visual.polygon = PackedVector2Array([
		-rect.size / 2.0,
		Vector2(rect.size.x / 2.0, -rect.size.y / 2.0),
		rect.size / 2.0,
		Vector2(-rect.size.x / 2.0, rect.size.y / 2.0),
	])
	body.add_child(visual)

	_add_block_underworld_detail(rect, body)

func _add_block_underworld_detail(rect: Rect2, body: Node2D) -> void:
	var top_line := Line2D.new()
	top_line.default_color = Color("76637f")
	top_line.width = 2.0
	top_line.points = PackedVector2Array([
		Vector2(-rect.size.x / 2.0, -rect.size.y / 2.0 + 2.0),
		Vector2(rect.size.x / 2.0, -rect.size.y / 2.0 + 2.0),
	])
	body.add_child(top_line)

	var lower_line := Line2D.new()
	lower_line.default_color = Color(0.10, 0.07, 0.09, 0.72)
	lower_line.width = 2.0
	lower_line.points = PackedVector2Array([
		Vector2(-rect.size.x / 2.0, rect.size.y / 2.0 - 3.0),
		Vector2(rect.size.x / 2.0, rect.size.y / 2.0 - 3.0),
	])
	body.add_child(lower_line)

	var crack_count := clampi(int(rect.size.x / 96.0), 1, 6)
	for i in crack_count:
		var local_x := -rect.size.x / 2.0 + 42.0 + i * 87.0
		if local_x > rect.size.x / 2.0 - 14.0:
			continue
		var crack := Line2D.new()
		crack.default_color = Color(0.08, 0.055, 0.075, 0.72)
		crack.width = 1.4
		crack.points = PackedVector2Array([
			Vector2(local_x, -rect.size.y / 2.0 + 7.0),
			Vector2(local_x + 7.0, -rect.size.y / 2.0 + 16.0),
			Vector2(local_x - 2.0, -rect.size.y / 2.0 + 27.0),
		])
		body.add_child(crack)

	var sigil := Line2D.new()
	sigil.default_color = Color(0.30, 0.75, 0.65, 0.16)
	sigil.width = 1.2
	sigil.points = PackedVector2Array([
		Vector2(-rect.size.x / 2.0 + 10.0, rect.size.y / 2.0 - 8.0),
		Vector2(minf(rect.size.x / 2.0 - 10.0, -rect.size.x / 2.0 + 92.0), rect.size.y / 2.0 - 8.0),
	])
	body.add_child(sigil)

func _add_styx_death_area() -> void:
	var area := Area2D.new()
	area.name = "StyxDeathWater"
	area.collision_layer = 0
	area.collision_mask = 1
	area.position = Vector2(WORLD_WIDTH / 2.0, STYX_WATERLINE_Y + STYX_DEPTH / 2.0)
	area.body_entered.connect(_on_styx_body_entered)
	add_child(area)

	var shape := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = Vector2(WORLD_WIDTH, STYX_DEPTH)
	shape.shape = rect_shape
	area.add_child(shape)

func _on_styx_body_entered(body: Node) -> void:
	if body.has_method("die_to"):
		body.die_to("styx_water")

func _build_souls() -> void:
	_soul_specs.clear()
	var soul_data := [
		{"x": 138.0, "y": 591.0, "phase": 0.25, "scale": 0.92, "angle": -0.35, "speed": 4.5},
		{"x": 418.0, "y": 627.0, "phase": 2.30, "scale": 0.74, "angle": 0.28, "speed": 3.0},
		{"x": 725.0, "y": 604.0, "phase": 4.15, "scale": 1.02, "angle": -0.12, "speed": 3.8},
		{"x": 1055.0, "y": 638.0, "phase": 5.80, "scale": 0.68, "angle": 0.55, "speed": 2.5},
	]
	for spec in soul_data:
		_soul_specs.append(spec)

func _draw() -> void:
	_draw_crypt_gradient()
	_draw_ground_dust()
	_draw_styx_water()

func _draw_crypt_gradient() -> void:
	var bands := 36
	for i in bands:
		var t := float(i) / float(bands - 1)
		var color := Color(0.010 + t * 0.10, 0.010 + t * 0.09, 0.014 + t * 0.14, 1.0)
		var y := t * PLAYFIELD_HEIGHT
		draw_rect(Rect2(0, y, WORLD_WIDTH, PLAYFIELD_HEIGHT / bands + 2.0), color)

	# Faint underworld glow near the horizon behind the play space. This is a cheap
	# fake-lighting pass for now; real 2D lights can come after gameplay stabilizes.
	draw_circle(Vector2(880, 505), 330, Color(0.29, 0.22, 0.34, 0.065))
	draw_circle(Vector2(220, 530), 280, Color(0.18, 0.30, 0.28, 0.052))
	draw_circle(Vector2(640, STYX_WATERLINE_Y + 30.0), 420, Color(0.09, 0.19, 0.17, 0.045))

func _draw_ground_dust() -> void:
	for i in 9:
		var phase := _time * 0.34 + i * 0.81
		var x := fposmod(i * 151.0 + sin(phase) * 22.0, WORLD_WIDTH)
		var y := 438.0 + sin(phase * 0.7) * 8.0
		var width := 115.0 + float(i % 3) * 34.0
		var alpha := 0.030 + 0.020 * sin(phase + 1.2)
		_draw_soft_ellipse(Rect2(x - width / 2.0, y - 10.0, width, 20.0), Color(0.58, 0.58, 0.54, alpha))

	for i in 5:
		var phase := _time * 0.25 + i * 1.12
		var x := fposmod(i * 271.0 - _time * 9.0, WORLD_WIDTH + 160.0) - 80.0
		var y := STYX_WATERLINE_Y - 17.0 + sin(phase) * 7.0
		_draw_soft_ellipse(Rect2(x - 82.0, y - 8.0, 164.0, 16.0), Color(0.47, 0.55, 0.50, 0.037))

func _draw_styx_water() -> void:
	var rect := Rect2(0, STYX_WATERLINE_Y, WORLD_WIDTH, STYX_DEPTH)
	draw_rect(rect, Color(0.034, 0.020, 0.014, 1.0))
	draw_rect(Rect2(0, STYX_WATERLINE_Y, WORLD_WIDTH, 19), Color(0.105, 0.074, 0.044, 0.76))
	draw_rect(Rect2(0, STYX_WATERLINE_Y + 20, WORLD_WIDTH, 18), Color(0.025, 0.016, 0.012, 0.58))

	for band in 4:
		var y := STYX_WATERLINE_Y + 8.0 + band * 19.0
		var points := PackedVector2Array()
		for x in range(-16, WORLD_WIDTH + 33, 16):
			var wave := sin(float(x) * 0.026 + _time * (0.55 + band * 0.13) + band) * (2.0 + band * 0.8)
			points.append(Vector2(x, y + wave))
		var color := Color(0.22, 0.17, 0.10, 0.21 - band * 0.032)
		draw_polyline(points, color, 2.0, true)

	for soul in _soul_specs:
		var phase := _time * 0.44 + float(soul["phase"])
		var drift := Vector2(cos(float(soul["angle"])), sin(float(soul["angle"]))) * sin(phase * 0.7) * float(soul["speed"])
		var pos := Vector2(float(soul["x"]), float(soul["y"])) + drift + Vector2(sin(phase) * 10.0, cos(phase * 0.6) * 5.0)
		_draw_soul(pos, float(soul["scale"]), phase, float(soul["angle"]))

func _draw_soul(pos: Vector2, scale: float, phase: float, angle: float) -> void:
	var visible_pulse := 0.5 + 0.5 * sin(phase * 0.72)
	var alpha := 0.035 + visible_pulse * 0.105
	var dir := Vector2.RIGHT.rotated(angle)
	var side := dir.orthogonal()
	var head := pos + dir * sin(phase) * 2.0
	var garment_start := head - dir * 8.0 * scale

	# Sparse tadpole/soul: clearer head, then a fading cloth-like tail.
	draw_circle(head, 5.2 * scale, Color(0.76, 0.96, 0.88, alpha))
	draw_circle(head, 11.5 * scale, Color(0.50, 0.86, 0.76, alpha * 0.18))
	for i in 5:
		var t := float(i) / 4.0
		var center := garment_start - dir * (10.0 + t * 34.0) * scale + side * sin(phase + t * 3.0) * 3.2 * scale
		var half_width := lerpf(5.5, 1.2, t) * scale
		var a := alpha * lerpf(0.88, 0.03, t)
		var poly := PackedVector2Array([
			center + side * half_width,
			center - dir * 8.0 * scale + side * half_width * 0.38,
			center - dir * 10.0 * scale - side * half_width * 0.38,
			center - side * half_width,
		])
		draw_colored_polygon(poly, Color(0.72, 0.94, 0.86, a))

	var eye_color := Color(0.04, 0.035, 0.05, alpha * 0.8)
	draw_circle(head + dir * 1.5 * scale + side * 1.8 * scale, 0.9 * scale, eye_color)
	draw_circle(head + dir * 1.5 * scale - side * 1.8 * scale, 0.9 * scale, eye_color)

func _draw_soft_ellipse(rect: Rect2, color: Color) -> void:
	var points := PackedVector2Array()
	var center := rect.get_center()
	var radius := rect.size / 2.0
	for i in 28:
		var angle := TAU * float(i) / 28.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)
