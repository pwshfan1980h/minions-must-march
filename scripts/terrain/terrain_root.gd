extends Node2D

const TILE_SIZE := 32
const WORLD_WIDTH := 2400
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
	# Wider prototype layout for testing camera scrolling. Minions spawn far right,
	# march left across a long crypt causeway, and exit near the left edge.
	_add_solid(Rect2(96, 448, 2144, 32), Color("3a3144"))
	_add_solid(Rect2(64, 480, 32, 96), Color("2a2432"))
	_add_solid(Rect2(2240, 480, 32, 96), Color("2a2432"))
	_add_solid(Rect2(1024, 480, 96, 32), Color("332b3b"))
	_add_solid(Rect2(1568, 480, 128, 32), Color("332b3b"))

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
	_draw_distant_underworld_background()
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

func _draw_distant_underworld_background() -> void:
	# Upper-screen mood pass: crimson sky, dead treetops, faint structures, and
	# sleepy portal glow. Kept low-contrast so it never competes with gameplay.
	for i in 16:
		var t := float(i) / 15.0
		var color := Color(0.105 + t * 0.055, 0.025 + t * 0.020, 0.035 + t * 0.028, 0.24 - t * 0.06)
		draw_rect(Rect2(0, i * 13.0, WORLD_WIDTH, 15.0), color)

	_draw_portal_ruin(Vector2(245, 185), 0.92, Color(0.54, 0.86, 0.42, 0.15))
	_draw_portal_ruin(Vector2(725, 156), 0.72, Color(0.95, 0.78, 0.29, 0.11))
	_draw_portal_ruin(Vector2(1038, 218), 1.08, Color(0.44, 0.98, 0.60, 0.12))
	_draw_portal_ruin(Vector2(1475, 178), 0.84, Color(0.87, 0.71, 0.25, 0.12))
	_draw_portal_ruin(Vector2(1975, 205), 1.02, Color(0.43, 0.92, 0.55, 0.13))
	_draw_skull_mountain(Vector2(1720, 258), 1.0)
	_draw_rib_arch(Vector2(1320, 336), 1.0)
	_draw_rib_arch(Vector2(2135, 354), 0.86)

	_draw_tower_silhouette(Vector2(378, 246), 0.78)
	_draw_tower_silhouette(Vector2(552, 224), 0.58)
	_draw_tower_silhouette(Vector2(895, 252), 0.66)
	_draw_tower_silhouette(Vector2(1245, 238), 0.74)
	_draw_tower_silhouette(Vector2(1840, 248), 0.62)
	draw_line(Vector2(430, 265), Vector2(615, 254), Color(0.025, 0.018, 0.026, 0.45), 5.0, true)
	draw_line(Vector2(620, 253), Vector2(828, 273), Color(0.025, 0.018, 0.026, 0.34), 3.0, true)
	draw_line(Vector2(1160, 270), Vector2(1395, 256), Color(0.025, 0.018, 0.026, 0.36), 4.0, true)
	draw_line(Vector2(1810, 272), Vector2(2040, 286), Color(0.025, 0.018, 0.026, 0.34), 3.0, true)

	var tree_color := Color(0.018, 0.014, 0.023, 0.52)
	draw_rect(Rect2(0, 318, WORLD_WIDTH, 42), tree_color)
	for i in range(0, WORLD_WIDTH + 48, 32):
		var peak := 248.0 + sin(i * 0.031) * 17.0 + sin(i * 0.009) * 28.0
		var base := 322.0 + sin(i * 0.017) * 9.0
		var crown := PackedVector2Array([
			Vector2(i - 7.0, base + 4.0),
			Vector2(i + 18.0, peak),
			Vector2(i + 43.0, base + 5.0),
		])
		draw_colored_polygon(crown, tree_color)

func _draw_skull_mountain(pos: Vector2, scale: float) -> void:
	var rock := Color(0.028, 0.022, 0.032, 0.36)
	var glow := Color(0.58, 0.87, 0.42, 0.055)
	draw_circle(pos + Vector2(-24, -18) * scale, 58.0 * scale, rock)
	draw_circle(pos + Vector2(28, -16) * scale, 52.0 * scale, rock)
	draw_rect(Rect2(pos + Vector2(-64, -28) * scale, Vector2(128, 82) * scale), rock)
	draw_circle(pos + Vector2(-28, -12) * scale, 12.0 * scale, Color(0.008, 0.007, 0.010, 0.34))
	draw_circle(pos + Vector2(30, -10) * scale, 12.0 * scale, Color(0.008, 0.007, 0.010, 0.34))
	draw_circle(pos + Vector2(-28, -12) * scale, 24.0 * scale, glow)
	draw_circle(pos + Vector2(30, -10) * scale, 24.0 * scale, glow)
	draw_rect(Rect2(pos + Vector2(-18, 18) * scale, Vector2(36, 7) * scale), Color(0.008, 0.007, 0.010, 0.28))

func _draw_rib_arch(pos: Vector2, scale: float) -> void:
	var color := Color(0.14, 0.12, 0.13, 0.28)
	for i in 5:
		var x := pos.x + (-70.0 + i * 35.0) * scale
		var top := pos.y - (92.0 - absf(i - 2) * 10.0) * scale
		draw_line(Vector2(x, pos.y), Vector2(x + (i - 2) * 9.0 * scale, top), color, 4.0 * scale, true)
	draw_arc(pos + Vector2(0, -8) * scale, 82.0 * scale, PI, TAU, 18, color, 4.0 * scale)

func _draw_portal_ruin(pos: Vector2, scale: float, glow: Color) -> void:
	var pulse := 0.76 + 0.24 * sin(_time * 0.75 + pos.x * 0.01)
	var stone := Color(0.038, 0.030, 0.045, 0.62)
	var lit := Color(glow.r, glow.g, glow.b, glow.a * pulse)
	draw_circle(pos + Vector2(0, 4) * scale, 46.0 * scale, Color(lit.r, lit.g, lit.b, lit.a * 0.33))
	draw_circle(pos + Vector2(0, 8) * scale, 22.0 * scale, Color(lit.r, lit.g, lit.b, lit.a * 0.45))
	draw_rect(Rect2(pos + Vector2(-24, -4) * scale, Vector2(8, 52) * scale), stone)
	draw_rect(Rect2(pos + Vector2(16, -4) * scale, Vector2(8, 52) * scale), stone)
	draw_line(pos + Vector2(-18, -4) * scale, pos + Vector2(0, -27) * scale, stone, 7.0 * scale, true)
	draw_line(pos + Vector2(18, -4) * scale, pos + Vector2(0, -27) * scale, stone, 7.0 * scale, true)
	draw_line(pos + Vector2(-11, 4) * scale, pos + Vector2(11, 4) * scale, lit, 3.0 * scale, true)
	draw_line(pos + Vector2(-7, 16) * scale, pos + Vector2(7, 16) * scale, Color(lit.r, lit.g, lit.b, lit.a * 0.75), 2.0 * scale, true)

func _draw_tower_silhouette(pos: Vector2, scale: float) -> void:
	var color := Color(0.020, 0.015, 0.026, 0.58)
	var w := 34.0 * scale
	var h := 92.0 * scale
	draw_rect(Rect2(pos + Vector2(-w / 2.0, -h), Vector2(w, h)), color)
	var roof := PackedVector2Array([
		pos + Vector2(-w * 0.65, -h),
		pos + Vector2(0, -h - 24.0 * scale),
		pos + Vector2(w * 0.65, -h),
	])
	draw_colored_polygon(roof, color)
	for i in 3:
		var y := pos.y - h + 18.0 * scale + i * 20.0 * scale
		draw_rect(Rect2(pos + Vector2(-3.0 * scale, y), Vector2(6.0, 9.0) * scale), Color(0.56, 0.90, 0.48, 0.055))

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
