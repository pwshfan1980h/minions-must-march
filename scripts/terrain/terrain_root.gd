extends Node2D

const TILE_SIZE := 32
const WORLD_WIDTH := 1280
const PLAYFIELD_HEIGHT := 608
const STYX_WATERLINE_Y := 560.0
const STYX_DEPTH := 112.0

var collision_rects: Array[Rect2] = []
var _time := 0.0
var _soul_specs: Array[Dictionary] = []

func _ready() -> void:
	_build_souls()
	_build_level_001_terrain()
	_add_styx_death_area()
	queue_redraw()

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _build_level_001_terrain() -> void:
	# Current prototype layout: minions spawn on the right platform, can be redirected
	# by a blocker, and the bottom of the world is now River Styx-style death water.
	_add_solid(Rect2(96, 448, 544, 32), Color("605871"))
	_add_solid(Rect2(64, 480, 32, 96), Color("4b4359"))
	_add_solid(Rect2(608, 480, 32, 96), Color("4b4359"))

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

	_add_block_trim(rect, body)

func _add_block_trim(rect: Rect2, body: Node2D) -> void:
	var top_line := Line2D.new()
	top_line.default_color = Color("8c819d")
	top_line.width = 2.0
	top_line.points = PackedVector2Array([
		Vector2(-rect.size.x / 2.0, -rect.size.y / 2.0 + 2.0),
		Vector2(rect.size.x / 2.0, -rect.size.y / 2.0 + 2.0),
	])
	body.add_child(top_line)

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
	for i in 14:
		_soul_specs.append({
			"x": 40.0 + i * 92.0,
			"y": STYX_WATERLINE_Y + 18.0 + float((i * 17) % 42),
			"phase": float(i) * 0.73,
			"scale": 0.75 + float((i * 11) % 7) * 0.07,
		})

func _draw() -> void:
	_draw_crypt_gradient()
	_draw_ground_dust()
	_draw_styx_water()

func _draw_crypt_gradient() -> void:
	var bands := 36
	for i in bands:
		var t := float(i) / float(bands - 1)
		var color := Color(0.015 + t * 0.13, 0.014 + t * 0.13, 0.019 + t * 0.16, 1.0)
		var y := t * PLAYFIELD_HEIGHT
		draw_rect(Rect2(0, y, WORLD_WIDTH, PLAYFIELD_HEIGHT / bands + 2.0), color)

	# Faint underworld glow near the horizon behind the play space.
	draw_circle(Vector2(880, 500), 310, Color(0.42, 0.36, 0.48, 0.055))
	draw_circle(Vector2(220, 530), 260, Color(0.30, 0.32, 0.38, 0.045))

func _draw_ground_dust() -> void:
	for i in 9:
		var phase := _time * 0.34 + i * 0.81
		var x := fposmod(i * 151.0 + sin(phase) * 22.0, WORLD_WIDTH)
		var y := 438.0 + sin(phase * 0.7) * 8.0
		var width := 115.0 + float(i % 3) * 34.0
		var alpha := 0.035 + 0.025 * sin(phase + 1.2)
		_draw_soft_ellipse(Rect2(x - width / 2.0, y - 10.0, width, 20.0), Color(0.72, 0.72, 0.66, alpha))

	for i in 7:
		var phase := _time * 0.25 + i * 1.12
		var x := fposmod(i * 193.0 - _time * 11.0, WORLD_WIDTH + 140.0) - 70.0
		var y := STYX_WATERLINE_Y - 18.0 + sin(phase) * 7.0
		_draw_soft_ellipse(Rect2(x - 70.0, y - 8.0, 140.0, 16.0), Color(0.62, 0.65, 0.61, 0.045))

func _draw_styx_water() -> void:
	var rect := Rect2(0, STYX_WATERLINE_Y, WORLD_WIDTH, STYX_DEPTH)
	draw_rect(rect, Color(0.045, 0.027, 0.018, 1.0))
	draw_rect(Rect2(0, STYX_WATERLINE_Y, WORLD_WIDTH, 16), Color(0.13, 0.095, 0.060, 0.68))

	for band in 4:
		var y := STYX_WATERLINE_Y + 9.0 + band * 18.0
		var points := PackedVector2Array()
		for x in range(-16, WORLD_WIDTH + 33, 16):
			var wave := sin(float(x) * 0.030 + _time * (1.1 + band * 0.23) + band) * (3.0 + band)
			points.append(Vector2(x, y + wave))
		var color := Color(0.29, 0.22, 0.14, 0.26 - band * 0.035)
		draw_polyline(points, color, 2.0, true)

	for soul in _soul_specs:
		var phase := _time * 0.75 + float(soul["phase"])
		var pos := Vector2(float(soul["x"]) + sin(phase * 0.8) * 16.0, float(soul["y"]) + sin(phase) * 6.0)
		_draw_soul(pos, float(soul["scale"]), phase)

func _draw_soul(pos: Vector2, scale: float, phase: float) -> void:
	var alpha := 0.18 + 0.08 * sin(phase * 1.7)
	var glow := Color(0.68, 0.86, 0.82, alpha * 0.30)
	var core := Color(0.78, 0.95, 0.91, alpha)
	draw_circle(pos, 13.0 * scale, glow)
	draw_circle(pos + Vector2(0, -4.0 * scale), 5.0 * scale, core)
	var tail := PackedVector2Array([
		pos + Vector2(-5.0, 1.0) * scale,
		pos + Vector2(0.0, 18.0 + sin(phase) * 5.0) * scale,
		pos + Vector2(5.0, 1.0) * scale,
	])
	draw_colored_polygon(tail, Color(core.r, core.g, core.b, alpha * 0.72))
	draw_circle(pos + Vector2(-2.0, -5.0) * scale, 1.2 * scale, Color(0.06, 0.05, 0.07, alpha))
	draw_circle(pos + Vector2(2.0, -5.0) * scale, 1.2 * scale, Color(0.06, 0.05, 0.07, alpha))

func _draw_soft_ellipse(rect: Rect2, color: Color) -> void:
	var points := PackedVector2Array()
	var center := rect.get_center()
	var radius := rect.size / 2.0
	for i in 28:
		var angle := TAU * float(i) / 28.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)
