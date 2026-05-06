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
var _hand_specs: Array[Dictionary] = []

func _ready() -> void:
	_build_souls()
	_build_hands()
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
	# Level 1: "Don't March Into the Soup". Skeletons spill from a crypt
	# chute on the right, march left toward a Styx drop, and must be turned back
	# toward the exit beam with one blocker.
	_add_solid(Rect2(1760, 448, 512, 32), Color("3a3144"), "crypt")
	_add_solid(Rect2(1728, 480, 32, 96), Color("2a2432"), "skull_end")
	_add_solid(Rect2(2240, 480, 32, 96), Color("2a2432"), "skull_end")
	_add_solid(Rect2(1296, 500, 288, 24), Color("4a3d37"), "bone_bridge")
	_add_solid(Rect2(896, 416, 320, 32), Color("241d2f"), "obsidian")
	_add_solid(Rect2(360, 472, 352, 32), Color("342b3e"), "chain")

func _add_solid(rect: Rect2, color: Color, variant := "crypt") -> void:
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

	_add_block_underworld_detail(rect, body, variant)

func _add_block_underworld_detail(rect: Rect2, body: Node2D, variant: String) -> void:
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

	if variant == "bone_bridge":
		for i in range(12, int(rect.size.x), 30):
			var rib := Line2D.new()
			rib.default_color = Color(0.76, 0.68, 0.54, 0.42)
			rib.width = 2.1
			rib.points = PackedVector2Array([
				Vector2(-rect.size.x / 2.0 + i, -rect.size.y / 2.0 + 4.0),
				Vector2(-rect.size.x / 2.0 + i + 12.0, rect.size.y / 2.0 - 5.0),
			])
			body.add_child(rib)
	elif variant == "obsidian":
		var gleam := Line2D.new()
		gleam.default_color = Color(0.46, 0.34, 0.72, 0.22)
		gleam.width = 1.6
		gleam.points = PackedVector2Array([Vector2(-rect.size.x / 2.0 + 18.0, -8.0), Vector2(rect.size.x / 2.0 - 18.0, -13.0)])
		body.add_child(gleam)
	elif variant == "chain":
		for x in [-rect.size.x / 2.0 + 38.0, rect.size.x / 2.0 - 38.0]:
			var chain := Line2D.new()
			chain.default_color = Color(0.12, 0.10, 0.13, 0.78)
			chain.width = 2.0
			chain.points = PackedVector2Array([Vector2(x, -rect.size.y / 2.0), Vector2(x, -rect.size.y / 2.0 - 138.0)])
			body.add_child(chain)
	elif variant == "skull_end":
		for y in range(-34, 35, 24):
			var skull := Polygon2D.new()
			skull.color = Color(0.72, 0.65, 0.52, 0.18)
			skull.position = Vector2(0, y)
			skull.polygon = PackedVector2Array([Vector2(-8,-7), Vector2(8,-7), Vector2(10,3), Vector2(4,10), Vector2(-4,10), Vector2(-10,3)])
			body.add_child(skull)

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
		{"x": 1375.0, "y": 612.0, "phase": 1.45, "scale": 0.82, "angle": -0.18, "speed": 3.2},
		{"x": 1660.0, "y": 632.0, "phase": 3.10, "scale": 1.08, "angle": 0.16, "speed": 4.0},
		{"x": 2035.0, "y": 606.0, "phase": 4.95, "scale": 0.76, "angle": -0.46, "speed": 3.6},
	]
	for spec in soul_data:
		_soul_specs.append(spec)

func _build_hands() -> void:
	_hand_specs.clear()
	var hand_data := [
		{"x": 260.0, "phase": 0.10, "scale": 0.88, "cycle": 4.7, "lean": -0.22},
		{"x": 620.0, "phase": 1.90, "scale": 1.06, "cycle": 5.6, "lean": 0.18},
		{"x": 980.0, "phase": 3.20, "scale": 0.74, "cycle": 4.9, "lean": -0.12},
		{"x": 1325.0, "phase": 2.45, "scale": 0.96, "cycle": 6.2, "lean": 0.28},
		{"x": 1745.0, "phase": 4.30, "scale": 1.12, "cycle": 5.2, "lean": -0.18},
		{"x": 2160.0, "phase": 5.40, "scale": 0.82, "cycle": 4.6, "lean": 0.14},
	]
	for spec in hand_data:
		_hand_specs.append(spec)

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
	draw_circle(Vector2(1540, 500), 360, Color(0.36, 0.19, 0.25, 0.045))
	draw_circle(Vector2(2050, 510), 300, Color(0.19, 0.30, 0.18, 0.042))
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
	_draw_background_light_pool(Vector2(520, 378), 0.9, Color(0.94, 0.66, 0.25, 0.075))
	_draw_background_light_pool(Vector2(1080, 360), 0.78, Color(0.48, 0.92, 0.55, 0.070))
	_draw_background_light_pool(Vector2(1900, 392), 1.0, Color(0.93, 0.72, 0.30, 0.080))
	_draw_underworld_street_light(Vector2(500, 472), 0.9, Color(0.98, 0.73, 0.32, 0.58))
	_draw_underworld_street_light(Vector2(1130, 416), 0.75, Color(0.52, 0.98, 0.58, 0.48))
	_draw_underworld_street_light(Vector2(1510, 500), 0.82, Color(0.93, 0.70, 0.25, 0.50))
	_draw_underworld_street_light(Vector2(2050, 448), 0.95, Color(0.46, 0.90, 0.54, 0.48))

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

func _draw_background_light_pool(pos: Vector2, scale: float, color: Color) -> void:
	var pulse := 0.82 + 0.18 * sin(_time * 0.45 + pos.x * 0.005)
	var c := Color(color.r, color.g, color.b, color.a * pulse)
	_draw_light_shards(pos, 168.0 * scale, 54.0 * scale, Color(c.r, c.g, c.b, c.a * 0.42), 0.0)
	_draw_light_shards(pos + Vector2(7, -9) * scale, 76.0 * scale, 28.0 * scale, c, 1.7)

func _draw_underworld_street_light(pos: Vector2, scale: float, flame: Color) -> void:
	var pole := Color(0.030, 0.024, 0.034, 0.78)
	var pulse := 0.72 + 0.28 * sin(_time * 1.25 + pos.x * 0.013)
	var lit := Color(flame.r, flame.g, flame.b, flame.a * pulse)
	draw_line(pos, pos + Vector2(0, -86) * scale, pole, 4.0 * scale, true)
	draw_line(pos + Vector2(-12, -64) * scale, pos + Vector2(0, -78) * scale, pole, 3.0 * scale, true)
	draw_line(pos + Vector2(12, -64) * scale, pos + Vector2(0, -78) * scale, pole, 3.0 * scale, true)
	var aura := PackedVector2Array([
		pos + Vector2(0, -125) * scale,
		pos + Vector2(24, -103) * scale,
		pos + Vector2(19, -78) * scale,
		pos + Vector2(-3, -64) * scale,
		pos + Vector2(-25, -82) * scale,
		pos + Vector2(-20, -109) * scale,
	])
	draw_colored_polygon(aura, Color(lit.r, lit.g, lit.b, lit.a * 0.16))
	var flame_shape := PackedVector2Array([
		pos + Vector2(0, -111) * scale,
		pos + Vector2(10, -95) * scale,
		pos + Vector2(5, -83) * scale,
		pos + Vector2(-2, -88) * scale,
		pos + Vector2(-9, -94) * scale,
	])
	draw_colored_polygon(flame_shape, Color(lit.r, lit.g, lit.b, lit.a * 0.72))
	_draw_light_shards(pos + Vector2(0, -1) * scale, 54.0 * scale, 12.0 * scale, Color(lit.r, lit.g, lit.b, lit.a * 0.10), pos.x * 0.01)

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
	# Rising off-gas, now drawn as wispy vertical strands and torn smoke veils
	# instead of repeated oval stamps. Less potato-cloud, more Styx exhaust.
	for i in 18:
		var seed := float(i)
		var base_x := 90.0 + fposmod(seed * 173.0, WORLD_WIDTH - 140.0)
		var cycle := fposmod(_time * (0.045 + float(i % 4) * 0.009) + seed * 0.137, 1.0)
		var rise := cycle * (118.0 + float(i % 5) * 20.0)
		var x := base_x + sin(_time * 0.32 + seed) * (18.0 + float(i % 3) * 9.0)
		var y := STYX_WATERLINE_Y - 10.0 - rise
		var alpha := sin(cycle * PI) * (0.050 + float(i % 3) * 0.012)
		var color := Color(0.50, 0.62, 0.54, alpha) if i % 3 != 1 else Color(0.72, 0.60, 0.38, alpha * 0.72)
		_draw_mist_wisp(Vector2(x, y), 58.0 + float(i % 4) * 16.0, 14.0 + float(i % 5) * 4.0, color, seed)
		if i % 5 == 0:
			_draw_torn_smoke_veil(Vector2(x - 12.0, y + 18.0), 42.0, 70.0, Color(color.r, color.g, color.b, alpha * 0.28), seed + 9.0)

	for i in 8:
		var phase := _time * 0.22 + i * 1.12
		var x := fposmod(i * 307.0 - _time * 5.0, WORLD_WIDTH + 160.0) - 80.0
		var y := STYX_WATERLINE_Y - 8.0 + sin(phase) * 5.0
		var points := PackedVector2Array()
		for j in 7:
			var t := float(j) / 6.0
			points.append(Vector2(x + t * 116.0, y + sin(phase + t * 4.2) * 3.8))
		draw_polyline(points, Color(0.47, 0.55, 0.50, 0.028), 2.0, true)

func _draw_mist_wisp(pos: Vector2, height: float, sway: float, color: Color, seed: float) -> void:
	for strand in 3:
		var points := PackedVector2Array()
		var offset := -8.0 + strand * 8.0
		for j in 6:
			var t := float(j) / 5.0
			var curl := sin(_time * 0.55 + seed + strand * 1.7 + t * 5.4) * sway * (0.35 + t * 0.65)
			points.append(pos + Vector2(offset + curl, -height * t))
		var a := color.a * lerpf(0.95, 0.34, float(strand) / 2.0)
		draw_polyline(points, Color(color.r, color.g, color.b, a), 1.4 + strand * 0.35, true)

func _draw_torn_smoke_veil(pos: Vector2, width: float, height: float, color: Color, seed: float) -> void:
	# Use layered strokes instead of filled polygons; Godot's polygon triangulator
	# hates self-crossing smoky shapes, and strokes read better for wispy vapor.
	for strand in 4:
		var points := PackedVector2Array()
		var x_base := pos.x + width * (float(strand) / 3.0)
		for j in 6:
			var t := float(j) / 5.0
			var curl := sin(seed + float(strand) * 1.4 + t * 4.6 + _time * 0.28) * (5.0 + t * 9.0)
			points.append(Vector2(x_base + curl, pos.y - height * t))
		var a := color.a * lerpf(0.78, 0.22, float(strand) / 3.0)
		draw_polyline(points, Color(color.r, color.g, color.b, a), 1.2, true)

func _draw_light_shards(pos: Vector2, width: float, height: float, color: Color, seed: float) -> void:
	var half_w := width / 2.0
	var points := PackedVector2Array([
		pos + Vector2(-half_w, -height * 0.16 + sin(seed) * 3.0),
		pos + Vector2(-half_w * 0.42, -height * 0.50 + cos(seed * 1.7) * 4.0),
		pos + Vector2(half_w * 0.18, -height * 0.38 + sin(seed + 1.2) * 5.0),
		pos + Vector2(half_w, -height * 0.06 + cos(seed + 0.8) * 4.0),
		pos + Vector2(half_w * 0.62, height * 0.34 + sin(seed + 2.1) * 4.0),
		pos + Vector2(-half_w * 0.22, height * 0.50 + cos(seed + 3.4) * 4.0),
		pos + Vector2(-half_w * 0.74, height * 0.24 + sin(seed + 4.2) * 4.0),
	])
	draw_colored_polygon(points, color)

func _draw_styx_water() -> void:
	var rect := Rect2(0, STYX_WATERLINE_Y, WORLD_WIDTH, STYX_DEPTH)
	draw_rect(rect, Color(0.030, 0.018, 0.014, 1.0))
	_draw_styx_surface_skin()
	_draw_styx_currents()
	_draw_styx_hands()

	for soul in _soul_specs:
		var phase := _time * 0.44 + float(soul["phase"])
		var drift := Vector2(cos(float(soul["angle"])), sin(float(soul["angle"]))) * sin(phase * 0.7) * float(soul["speed"])
		var pos := Vector2(float(soul["x"]), float(soul["y"])) + drift + Vector2(sin(phase) * 10.0, cos(phase * 0.6) * 5.0)
		_draw_soul(pos, float(soul["scale"]), phase, float(soul["angle"]))

func _draw_styx_surface_skin() -> void:
	var top := PackedVector2Array()
	var bottom := PackedVector2Array()
	for x in range(-24, WORLD_WIDTH + 49, 24):
		var wave := sin(float(x) * 0.023 + _time * 0.72) * 3.0 + sin(float(x) * 0.011 - _time * 0.38) * 2.1
		top.append(Vector2(x, STYX_WATERLINE_Y + wave))
		bottom.append(Vector2(x, STYX_WATERLINE_Y + 24.0 + wave * 0.34))
	var skin := PackedVector2Array()
	for point in top:
		skin.append(point)
	for i in range(bottom.size() - 1, -1, -1):
		skin.append(bottom[i])
	draw_colored_polygon(skin, Color(0.112, 0.078, 0.046, 0.82))
	draw_rect(Rect2(0, STYX_WATERLINE_Y + 24, WORLD_WIDTH, 32), Color(0.024, 0.015, 0.012, 0.62))
	draw_rect(Rect2(0, STYX_WATERLINE_Y + 56, WORLD_WIDTH, STYX_DEPTH - 56), Color(0.018, 0.011, 0.010, 0.68))

func _draw_styx_currents() -> void:
	for band in 7:
		var y := STYX_WATERLINE_Y + 7.0 + band * 13.0
		var points := PackedVector2Array()
		var direction := -1.0 if band % 2 == 0 else 1.0
		for x in range(-32, WORLD_WIDTH + 65, 16):
			var fx := float(x)
			var wave := sin(fx * (0.019 + band * 0.002) + _time * direction * (0.72 + band * 0.08) + band) * (2.2 + band * 0.42)
			var undertow := sin(fx * 0.006 - _time * 0.36 + band * 1.7) * 1.8
			points.append(Vector2(fx, y + wave + undertow))
		var color := Color(0.30, 0.22, 0.12, 0.23 - band * 0.018) if band < 3 else Color(0.10, 0.20, 0.16, 0.12)
		draw_polyline(points, color, 1.7 + float(band % 3) * 0.35, true)

	# Slow eddies: angular current marks, not oval bubbles.
	for i in 11:
		var x := fposmod(float(i) * 229.0 + _time * (18.0 + float(i % 3) * 7.0), WORLD_WIDTH + 120.0) - 60.0
		var y := STYX_WATERLINE_Y + 18.0 + float((i * 17) % 68)
		var phase := _time * 0.8 + float(i)
		var eddy := PackedVector2Array([
			Vector2(x - 18.0, y + sin(phase) * 2.0),
			Vector2(x - 4.0, y - 5.0),
			Vector2(x + 14.0, y - 2.0),
			Vector2(x + 2.0, y + 6.0),
		])
		draw_polyline(eddy, Color(0.53, 0.43, 0.22, 0.070), 1.4, true)

func _draw_styx_hands() -> void:
	for hand in _hand_specs:
		var cycle_seconds := float(hand["cycle"])
		var t := fposmod(_time + float(hand["phase"]), cycle_seconds) / cycle_seconds
		var emerge := smoothstep(0.04, 0.22, t) * (1.0 - smoothstep(0.58, 0.86, t))
		if emerge <= 0.01:
			continue
		var bob := sin(t * TAU * 1.8) * 2.0
		var x := float(hand["x"]) + sin(_time * 0.23 + float(hand["phase"])) * 8.0
		var y := STYX_WATERLINE_Y + 10.0 - emerge * (34.0 * float(hand["scale"])) + bob
		_draw_grasping_hand(Vector2(x, y), float(hand["scale"]), float(hand["lean"]), emerge)

func _draw_grasping_hand(pos: Vector2, scale: float, lean: float, alpha: float) -> void:
	var skin := Color(0.50, 0.58, 0.45, 0.34 * alpha)
	var shadow := Color(0.035, 0.027, 0.020, 0.42 * alpha)
	var wrist := pos + Vector2(lean * 16.0, 26.0 * scale)
	var palm := pos + Vector2(lean * 8.0, 5.0 * scale)
	draw_line(wrist + Vector2(2, 1), palm + Vector2(2, 1), shadow, 8.0 * scale, true)
	draw_line(wrist, palm, skin, 6.0 * scale, true)
	for i in 5:
		var spread := -13.0 + float(i) * 6.5
		var length := (18.0 + float(i % 2) * 5.0) * scale
		var curl := sin(_time * 1.1 + pos.x * 0.01 + float(i)) * 4.0 * scale
		var knuckle := palm + Vector2(spread * scale, -8.0 * scale)
		var tip := knuckle + Vector2(spread * 0.20 + lean * 7.0, -length + curl)
		draw_line(knuckle + Vector2(1, 1), tip + Vector2(1, 1), shadow, 3.0 * scale, true)
		draw_line(knuckle, tip, skin, 2.0 * scale, true)
	_draw_torn_smoke_veil(pos + Vector2(-16.0 * scale, 23.0 * scale), 34.0 * scale, 28.0 * scale, Color(0.10, 0.08, 0.04, 0.15 * alpha), pos.x * 0.01)

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
