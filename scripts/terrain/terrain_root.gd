extends Node2D

const TILE_SIZE := 32
const WORLD_WIDTH := 2400
const PLAYFIELD_HEIGHT := 720
const STYX_WATERLINE_Y := 560.0
const STYX_DEPTH := 176.0
const TERRAIN_REDRAW_FPS := 30.0
const CRUMBLE_FUSE_MIN := 15.0
const CRUMBLE_FUSE_MAX := 30.0

var collision_rects: Array[Rect2] = []
var diggable_plugs: Array[Dictionary] = []
var _time := 0.0
var _redraw_elapsed := 0.0
var _soul_specs: Array[Dictionary] = []
var _hand_specs: Array[Dictionary] = []
var _bubble_specs: Array[Dictionary] = []
var _bubble_pops: Array[Dictionary] = []
var _crumbling_sections: Array[Dictionary] = []
var _platform_ash_specs: Array[Dictionary] = []

func _ready() -> void:
	_build_souls()
	_build_hands()
	_build_bubbles()
	var terrain_id: String = LevelState.config().get("terrain", "level_001")
	match terrain_id:
		"level_001": _build_level_001_terrain()
		"level_002": _build_level_002_terrain()
		"level_003": _build_level_003_terrain()
		"level_004": _build_level_004_terrain()
		"level_005": _build_level_005_terrain()
		"level_006": _build_level_006_terrain()
		_: _build_level_001_terrain()
	_add_styx_death_area()
	queue_redraw()

func _process(delta: float) -> void:
	_time += delta
	_redraw_elapsed += delta
	if _redraw_elapsed >= 1.0 / TERRAIN_REDRAW_FPS:
		_redraw_elapsed = 0.0
		queue_redraw()
	_tick_bubble_pops()
	_tick_crumbling_sections()

func _build_level_001_terrain() -> void:
	# Bridge lab + crumbler: spawn on the left, build a bone bridge over the
	# Styx gap, then traverse the right platform — but a chunk of the right
	# platform crumbles after first weight, so don't dawdle.
	# Left platform + supports. The leftmost slice is a crumbler — sits just
	# left of the spawn portal at x=220, so a redirected/turned-around crowd
	# stepping back here will eventually take that chunk down with them.
	_add_crumbling_solid(Rect2(160, 448, 56, 32), Color("3a3144"))
	_add_solid(Rect2(216, 448, 584, 32), Color("3a3144"), "crypt")
	_add_solid(Rect2(128, 480, 32, 96), Color("2a2432"), "skull_end")
	_add_solid(Rect2(800, 480, 32, 96), Color("2a2432"), "skull_end")
	# Right platform: split into solid - crumbling - solid so one chunk falls
	# away after a skeleton walks on it.
	_add_solid(Rect2(912, 400, 160, 32), Color("342b3e"), "chain")
	_add_crumbling_solid(Rect2(1072, 400, 96, 32), Color("342b3e"))
	_add_solid(Rect2(1168, 400, 224, 32), Color("342b3e"), "chain")
	# Right platform supports (previously missing — platform was floating)
	_add_solid(Rect2(912, 432, 32, 144), Color("2a2432"), "skull_end")
	_add_solid(Rect2(1360, 432, 32, 144), Color("2a2432"), "skull_end")
	# Decorative & exit-side block
	_add_solid(Rect2(1392, 432, 96, 32), Color("241d2f"), "obsidian")
	_add_solid(Rect2(500, 500, 184, 24), Color("4a3d37"), "bone_bridge")
	_add_builder_demo_markers()


func _build_level_002_terrain() -> void:
	# Crumblepath: same overall shape as L001 (left platform + Styx gap + right
	# platform with exit), but the right platform is broken into three crumbling
	# chunks separated by short solid sections. Once the leader steps onto the
	# right side, three fuses start in cascade and the crowd has to keep moving.
	_add_solid(Rect2(160, 448, 640, 32), Color("3a3144"), "crypt")
	_add_solid(Rect2(128, 480, 32, 96), Color("2a2432"), "skull_end")
	_add_solid(Rect2(800, 480, 32, 96), Color("2a2432"), "skull_end")
	# Right side: solid landing, then crumbler-solid-crumbler-solid-crumbler-solid.
	_add_solid(Rect2(912, 400, 64, 32), Color("342b3e"), "chain")
	_add_crumbling_solid(Rect2(976, 400, 72, 32), Color("342b3e"))
	_add_solid(Rect2(1048, 400, 56, 32), Color("342b3e"), "chain")
	_add_crumbling_solid(Rect2(1104, 400, 72, 32), Color("342b3e"))
	_add_solid(Rect2(1160, 400, 56, 32), Color("342b3e"), "chain")
	_add_crumbling_solid(Rect2(1216, 400, 72, 32), Color("342b3e"))
	_add_solid(Rect2(1288, 400, 104, 32), Color("342b3e"), "chain")
	# Pillars under the right platform.
	_add_solid(Rect2(912, 432, 32, 144), Color("2a2432"), "skull_end")
	_add_solid(Rect2(1360, 432, 32, 144), Color("2a2432"), "skull_end")
	# Decorative bone bridge below for atmosphere.
	_add_solid(Rect2(500, 500, 184, 24), Color("4a3d37"), "bone_bridge")

func _build_level_003_terrain() -> void:
	# Turn, You Fools: a single long platform. Spawn faces LEFT toward an open
	# Styx drop. Player must place a blocker before the cliff, redirecting the
	# crowd to the exit on the far right. No bridges needed.
	_add_solid(Rect2(160, 448, 1232, 32), Color("3a3144"), "crypt")
	_add_solid(Rect2(128, 480, 32, 96), Color("2a2432"), "skull_end")
	_add_solid(Rect2(1392, 480, 32, 96), Color("2a2432"), "skull_end")
	# Mid-platform skull pillar for visual rhythm on the long span.
	_add_solid(Rect2(760, 480, 32, 96), Color("2a2432"), "skull_end")

func _build_level_004_terrain() -> void:
	# Two-Bridge Bypass: a three-tier staircase with two gaps. Each gap is 112px
	# wide with a 48px elevation step — the rib bridge's natural rise/run, so a
	# clean build from the lip of each lower platform lands flush on the next.
	# Left platform (lowest): top y=480
	_add_solid(Rect2(160, 480, 240, 32), Color("3a3144"), "crypt")
	_add_solid(Rect2(128, 512, 32, 64), Color("2a2432"), "skull_end")
	_add_solid(Rect2(400, 512, 32, 64), Color("2a2432"), "skull_end")
	# Mid platform (middle tier): top y=432
	_add_solid(Rect2(512, 432, 168, 32), Color("342b3e"), "chain")
	_add_solid(Rect2(512, 464, 32, 112), Color("2a2432"), "skull_end")
	_add_solid(Rect2(680, 464, 32, 112), Color("2a2432"), "skull_end")
	# Right platform (top tier, with exit): top y=384
	_add_solid(Rect2(792, 384, 448, 32), Color("241d2f"), "obsidian")
	_add_solid(Rect2(792, 416, 32, 160), Color("2a2432"), "skull_end")
	_add_solid(Rect2(1240, 416, 32, 160), Color("2a2432"), "skull_end")

func _build_level_005_terrain() -> void:
	# Drop Crypt Detour: the first true multi-level map. Skeletons start on a
	# high balcony, walk off a short 96px drop that stays below the fatal-fall
	# threshold, then need a blocker decision on the lower floor before spending
	# one builder charge to cross the final Styx cut to the exit shelf.
	# Upper balcony: top y=352. It deliberately has no right guard rail so the
	# crowd tumbles to the lower playable tier instead of simply marching across.
	_add_solid(Rect2(160, 352, 404, 32), Color("3a3144"), "crypt")
	_add_solid(Rect2(128, 384, 32, 192), Color("2a2432"), "skull_end")
	_add_solid(Rect2(532, 384, 32, 88), Color("2a2432"), "skull_end")

	# Lower tier landing: top y=448, so the 96px fall is survivable. A left wall
	# prevents the crowd from back-walking into the Styx after the player uses a
	# blocker to reorganize the flow on this level.
	_add_solid(Rect2(456, 448, 376, 32), Color("342b3e"), "chain")
	_add_solid(Rect2(424, 416, 32, 160), Color("2a2432"), "skull_end")
	_add_solid(Rect2(800, 480, 32, 96), Color("2a2432"), "skull_end")

	# Final exit shelf after a bridgeable 112px gap. The single Builder charge can
	# span this cut from the lower lip, making the level a lemmings-style sequence:
	# survive fall -> decide/turn -> build -> exit.
	_add_solid(Rect2(944, 448, 448, 32), Color("241d2f"), "obsidian")
	_add_solid(Rect2(944, 480, 32, 96), Color("2a2432"), "skull_end")
	_add_solid(Rect2(1360, 480, 32, 96), Color("2a2432"), "skull_end")

	# A faint upper ledge silhouette above the lower route helps the player read
	# that this is a stacked, multi-level space rather than a single flat bridge.
	_add_solid(Rect2(1030, 320, 168, 18), Color("2d2536"), "chain")

func _build_level_006_terrain() -> void:
	# Bone Basement Shortcut: first Ash Catacombs board and first Digger lesson.
	# Skeletons march on an upper tomb corridor directly over a cracked brown/black
	# diggable substrate. Removing that plug opens a survivable 128px drop into a
	# lower burial passage with the exit portal below the original floor.
	_add_solid(Rect2(128, 320, 456, 32), Color("665c54"), "ash_floor")
	_add_diggable_plug(Rect2(584, 320, 96, 32), Color("3c332f"))
	_add_solid(Rect2(680, 320, 220, 32), Color("5a514c"), "ash_floor")
	_add_solid(Rect2(96, 224, 32, 352), Color("2b2828"), "ash_wall")
	_add_solid(Rect2(900, 224, 32, 352), Color("2b2828"), "ash_wall")

	# Middle tomb shelf gives the level a 2-3 layer read without creating a safe
	# route; it is decorative/structural and teaches this is a taller catacomb.
	_add_solid(Rect2(1010, 252, 230, 24), Color("4a4442"), "lower_catacomb")
	_add_solid(Rect2(1210, 276, 30, 172), Color("2b2828"), "ash_wall")

	# Lower route: y=448 top means the DIG drop from y=320 is survivable while
	# still clearly vertical. The left wall prevents a back-walk into the out-of-
	# bounds Styx safety area and turns the crowd toward the exit glow.
	_add_solid(Rect2(392, 448, 858, 32), Color("4a403c"), "lower_catacomb")
	_add_solid(Rect2(360, 384, 32, 192), Color("252222"), "ash_wall")
	_add_solid(Rect2(1250, 384, 32, 192), Color("252222"), "ash_wall")
	_add_solid(Rect2(520, 512, 176, 24), Color("342b2a"), "lower_catacomb")
	_add_solid(Rect2(820, 544, 240, 24), Color("312827"), "lower_catacomb")
	_add_ash_catacombs_markers()

func _add_ash_catacombs_markers() -> void:
	var sign := Line2D.new()
	sign.name = "DiggerDownMarker"
	sign.default_color = Color(0.95, 0.68, 0.28, 0.76)
	sign.width = 3.0
	sign.points = PackedVector2Array([
		Vector2(632, 268),
		Vector2(632, 306),
		Vector2(616, 290),
		Vector2(632, 306),
		Vector2(648, 290),
	])
	add_child(sign)

	for x in [430.0, 1130.0, 1195.0]:
		var candle := Node2D.new()
		candle.name = "AshCandle"
		candle.position = Vector2(x, 438.0)
		add_child(candle)
		var wick := Line2D.new()
		wick.default_color = Color("d8b56b")
		wick.width = 2.0
		wick.points = PackedVector2Array([Vector2(0, 0), Vector2(0, -14)])
		candle.add_child(wick)
		var flame := Polygon2D.new()
		flame.color = Color(1.0, 0.58, 0.18, 0.78)
		flame.position = Vector2(0, -18)
		flame.polygon = PackedVector2Array([Vector2(0, -9), Vector2(6, 2), Vector2(0, 7), Vector2(-5, 2)])
		candle.add_child(flame)

func _add_builder_demo_markers() -> void:
	# A single non-colliding build marker. Do not show ghost bridge pieces here:
	# the empty gap needs to read as unbuilt until a Builder creates the ribs.
	var start := Vector2(760, 440)
	var marker := Line2D.new()
	marker.name = "BuilderDemoStartMarker"
	marker.default_color = Color(0.95, 0.78, 0.28, 0.72)
	marker.width = 3.0
	marker.points = PackedVector2Array([start + Vector2(0, -34), start + Vector2(0, 18)])
	add_child(marker)

	var chevron := Line2D.new()
	chevron.name = "BuilderDemoDirectionHint"
	chevron.default_color = Color(0.95, 0.78, 0.28, 0.58)
	chevron.width = 2.0
	chevron.points = PackedVector2Array([
		start + Vector2(10, -14),
		start + Vector2(26, -14),
		start + Vector2(19, -21),
		start + Vector2(26, -14),
		start + Vector2(19, -7),
	])
	add_child(chevron)

func _add_solid(rect: Rect2, color: Color, variant := "crypt") -> StaticBody2D:
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
	# Jagged, tomb-broken silhouette; collision stays a clean rect for puzzles.
	visual.polygon = _build_chipped_silhouette(rect)
	body.add_child(visual)

	_add_hanging_shards(rect, body, color, variant)
	_add_block_underworld_detail(rect, body, variant)
	_add_platform_ash_emitter(rect, variant)
	if variant == "skull_end":
		_add_pillar_capstone(rect, body, color)
	return body

func _add_diggable_plug(rect: Rect2, color: Color) -> StaticBody2D:
	var body := _add_solid(rect, color, "dig_plug")
	body.name = "DiggablePlug"
	diggable_plugs.append({"rect": rect, "body": body})
	return body

func find_diggable_plug_at(world_position: Vector2) -> Dictionary:
	for plug in diggable_plugs:
		var rect: Rect2 = plug["rect"]
		var within_x := world_position.x >= rect.position.x - 12.0 and world_position.x <= rect.end.x + 12.0
		var near_top := absf(world_position.y - rect.position.y) <= 48.0
		if within_x and near_top:
			return plug
	return {}

func remove_diggable_plug(plug: Dictionary) -> bool:
	if plug.is_empty():
		return false
	var rect: Rect2 = plug["rect"]
	var body: Node = plug["body"]
	collision_rects.erase(rect)
	diggable_plugs.erase(plug)
	_spawn_crumble_debris(rect, Color("6f625a"))
	if is_instance_valid(body):
		body.queue_free()
	queue_redraw()
	return true

func _build_chipped_silhouette(rect: Rect2) -> PackedVector2Array:
	# Generate a mostly-rectangular collision footprint with a more organic visual
	# shell: chipped top edge, slanted sides, and a ragged underside. Deterministic
	# per-rect via a position-derived seed so the level is stable between runs.
	var hw := rect.size.x * 0.5
	var hh := rect.size.y * 0.5
	var rng := RandomNumberGenerator.new()
	rng.seed = int(rect.position.x * 1009.0 + rect.position.y * 31.0 + rect.size.x * 7.0)
	var pts := PackedVector2Array()
	pts.append(Vector2(-hw + rng.randf_range(-2.0, 3.0), -hh + rng.randf_range(0.0, 2.4)))
	var notch_count := clampi(int(rect.size.x / 42.0), 3, 14)
	for i in notch_count:
		var t := (float(i) + rng.randf_range(0.30, 0.70)) / float(notch_count)
		var notch_x := lerpf(-hw + 12.0, hw - 12.0, t)
		var notch_w := rng.randf_range(7.0, 20.0)
		var notch_d := rng.randf_range(2.0, 8.0)
		pts.append(Vector2(notch_x - notch_w * 0.5, -hh))
		pts.append(Vector2(notch_x - notch_w * 0.18, -hh + notch_d * 0.55))
		pts.append(Vector2(notch_x, -hh + notch_d))
		pts.append(Vector2(notch_x + notch_w * 0.22, -hh + notch_d * 0.45))
		pts.append(Vector2(notch_x + notch_w * 0.5, -hh))
	pts.append(Vector2(hw + rng.randf_range(-3.0, 2.0), -hh + rng.randf_range(0.0, 2.5)))
	pts.append(Vector2(hw + rng.randf_range(-2.5, 3.5), hh - rng.randf_range(1.0, 5.0)))
	var tooth_count := clampi(int(rect.size.x / 52.0), 2, 12)
	for i in range(tooth_count, -1, -1):
		var t := float(i) / float(maxi(tooth_count, 1))
		var x := lerpf(-hw + 6.0, hw - 6.0, t)
		var drop := rng.randf_range(0.0, minf(12.0, rect.size.y * 0.35))
		pts.append(Vector2(x + rng.randf_range(-4.0, 4.0), hh + drop))
	pts.append(Vector2(-hw + rng.randf_range(-3.0, 2.0), hh - rng.randf_range(1.0, 5.0)))
	return pts

func _add_hanging_shards(rect: Rect2, body: Node2D, color: Color, variant: String) -> void:
	if variant == "skull_end" or rect.size.x < 72.0:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = int(rect.position.x * 719.0 + rect.position.y * 43.0 + rect.size.y * 17.0)
	var shard_count := clampi(int(rect.size.x / 110.0), 1, 6)
	for i in shard_count:
		var x := lerpf(-rect.size.x * 0.5 + 18.0, rect.size.x * 0.5 - 18.0, (float(i) + rng.randf_range(0.18, 0.82)) / float(shard_count))
		var w := rng.randf_range(7.0, 17.0)
		var h := rng.randf_range(8.0, 24.0)
		var shard := Polygon2D.new()
		shard.name = "HangingJaggedShard"
		shard.color = color.darkened(rng.randf_range(0.10, 0.25))
		shard.polygon = PackedVector2Array([
			Vector2(x - w * 0.5, rect.size.y * 0.5 - 1.0),
			Vector2(x + w * 0.45, rect.size.y * 0.5 - rng.randf_range(0.0, 3.0)),
			Vector2(x + rng.randf_range(-2.0, 2.0), rect.size.y * 0.5 + h),
		])
		body.add_child(shard)

func _add_platform_ash_emitter(rect: Rect2, variant: String) -> void:
	if rect.size.x < 96.0 or variant == "skull_end":
		return
	var mote_count := clampi(int(rect.size.x / 150.0), 1, 5)
	for i in mote_count:
		_platform_ash_specs.append({
			"x": rect.position.x + (float(i) + 0.35) * rect.size.x / float(mote_count),
			"y": rect.position.y - 4.0,
			"phase": fposmod(rect.position.x * 0.011 + rect.position.y * 0.017 + float(i) * 0.37, 1.0),
			"rise": 14.0 + float((int(rect.position.x) + i * 13) % 18),
			"drift": -8.0 + float((int(rect.position.y) + i * 19) % 17),
			"speed": 0.10 + float((int(rect.size.x) + i * 7) % 6) * 0.018,
			"color": Color(0.90, 0.68, 0.36, 0.0) if variant == "obsidian" or variant == "dig_plug" else Color(0.62, 0.55, 0.68, 0.0),
		})

func _draw_platform_ash_motes() -> void:
	# Tiny non-colliding motes rising from platforms: a cheap particle-emission
	# pass that keeps the terrain alive without adding physics or audio noise.
	for spec in _platform_ash_specs:
		var cycle := fposmod(_time * float(spec["speed"]) + float(spec["phase"]), 1.0)
		var lift := float(spec["rise"]) * cycle
		var sway := sin(_time * 1.7 + float(spec["x"]) * 0.031) * 3.0 + float(spec["drift"]) * cycle
		var alpha := sin(cycle * PI) * 0.34
		var color: Color = spec["color"]
		color.a = alpha
		var pos := Vector2(float(spec["x"]) + sway, float(spec["y"]) - lift)
		draw_circle(pos, 1.4 + cycle * 1.1, color)

func _add_pillar_capstone(rect: Rect2, body: Node2D, color: Color) -> void:
	# Slightly wider band right at the pillar top — makes the seam where the
	# pillar meets the platform read as proper masonry instead of two flush
	# rectangles butting together.
	var hw := rect.size.x * 0.5
	var hh := rect.size.y * 0.5
	var cap := Polygon2D.new()
	cap.name = "Capstone"
	cap.color = color.lightened(0.04)
	cap.polygon = PackedVector2Array([
		Vector2(-hw - 3.5, -hh),
		Vector2(hw + 3.5, -hh),
		Vector2(hw + 3.5, -hh + 4.0),
		Vector2(hw + 1.0, -hh + 5.5),
		Vector2(-hw - 1.0, -hh + 5.5),
		Vector2(-hw - 3.5, -hh + 4.0),
	])
	body.add_child(cap)
	var cap_shadow := Line2D.new()
	cap_shadow.default_color = Color(0.07, 0.05, 0.07, 0.55)
	cap_shadow.width = 1.4
	cap_shadow.points = PackedVector2Array([
		Vector2(-hw - 1.0, -hh + 5.5),
		Vector2(hw + 1.0, -hh + 5.5),
	])
	body.add_child(cap_shadow)

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
	elif variant == "ash_floor" or variant == "lower_catacomb":
		top_line.default_color = Color("9a8771") if variant == "ash_floor" else Color("74635a")
		for i in range(18, int(rect.size.x), 74):
			var seam := Line2D.new()
			seam.default_color = Color(0.12, 0.095, 0.080, 0.32)
			seam.width = 1.1
			seam.points = PackedVector2Array([
				Vector2(-rect.size.x / 2.0 + i, -rect.size.y / 2.0 + 5.0),
				Vector2(-rect.size.x / 2.0 + i + 16.0, rect.size.y / 2.0 - 6.0),
			])
			body.add_child(seam)
	elif variant == "ash_wall":
		top_line.default_color = Color("6e6258")
		for y in range(-int(rect.size.y / 2.0) + 22, int(rect.size.y / 2.0), 44):
			var slab := Line2D.new()
			slab.default_color = Color(0.08, 0.065, 0.060, 0.38)
			slab.width = 1.2
			slab.points = PackedVector2Array([Vector2(-rect.size.x / 2.0 + 4.0, y), Vector2(rect.size.x / 2.0 - 4.0, y + 5.0)])
			body.add_child(slab)
	elif variant == "dig_plug":
		top_line.default_color = Color("d49a42")
		top_line.width = 3.0
		var warning := Line2D.new()
		warning.name = "DiggerCrackWarning"
		warning.default_color = Color("d4452f")
		warning.width = 2.2
		warning.points = PackedVector2Array([
			Vector2(-rect.size.x / 2.0 + 10.0, -rect.size.y / 2.0 + 5.0),
			Vector2(-rect.size.x / 2.0 + 34.0, rect.size.y / 2.0 - 8.0),
			Vector2(-rect.size.x / 2.0 + 58.0, -rect.size.y / 2.0 + 9.0),
			Vector2(rect.size.x / 2.0 - 12.0, rect.size.y / 2.0 - 6.0),
		])
		body.add_child(warning)
		var chevron := Line2D.new()
		chevron.default_color = Color(1.0, 0.78, 0.22, 0.72)
		chevron.width = 2.0
		chevron.points = PackedVector2Array([Vector2(-15, -4), Vector2(0, 9), Vector2(15, -4)])
		body.add_child(chevron)
	elif variant == "skull_end":
		for y in range(-34, 35, 24):
			var skull := Polygon2D.new()
			skull.color = Color(0.72, 0.65, 0.52, 0.18)
			skull.position = Vector2(0, y)
			skull.polygon = PackedVector2Array([Vector2(-8,-7), Vector2(8,-7), Vector2(10,3), Vector2(4,10), Vector2(-4,10), Vector2(-10,3)])
			body.add_child(skull)

func _add_crumbling_solid(rect: Rect2, color: Color) -> StaticBody2D:
	# Looks like a normal platform; an Area2D sitting just above its top
	# detects the first skeleton to step on and starts a 15–30s fuse, after
	# which the collision and visual disappear in a debris burst.
	var body := _add_solid(rect, color, "crumbling")

	var trigger := Area2D.new()
	trigger.name = "CrumbleTrigger"
	trigger.collision_layer = 0
	trigger.collision_mask = 2  # detect skeletons (CharacterBody2D layer 2)
	trigger.position = Vector2(0.0, -rect.size.y * 0.5 - 4.0)
	body.add_child(trigger)

	var trig_shape := CollisionShape2D.new()
	var trig_rect := RectangleShape2D.new()
	trig_rect.size = Vector2(maxf(rect.size.x - 4.0, 4.0), 8.0)
	trig_shape.shape = trig_rect
	trigger.add_child(trig_shape)

	var rng := RandomNumberGenerator.new()
	rng.seed = int(rect.position.x * 211.0 + rect.position.y * 17.0 + 7919.0)
	var fuse_seconds := rng.randf_range(CRUMBLE_FUSE_MIN, CRUMBLE_FUSE_MAX)

	# Pulsing warning cracks — invisible until the fuse starts. Three vertical
	# zigzag scars across the section, modulate.a ramps from 0 to 1 over the fuse.
	var warning := Node2D.new()
	warning.name = "CrumbleWarning"
	warning.modulate.a = 0.0
	body.add_child(warning)
	for k in 3:
		var scar_x := lerpf(-rect.size.x * 0.5 + 8.0, rect.size.x * 0.5 - 8.0, (float(k) + 0.5) / 3.0)
		scar_x += rng.randf_range(-4.0, 4.0)
		var scar := Line2D.new()
		scar.default_color = Color(0.04, 0.025, 0.030, 0.95)
		scar.width = 1.4
		scar.points = PackedVector2Array([
			Vector2(scar_x - 1.0, -rect.size.y * 0.5 + 1.5),
			Vector2(scar_x + 2.0, -rect.size.y * 0.5 + rect.size.y * 0.35),
			Vector2(scar_x - 1.5, -rect.size.y * 0.5 + rect.size.y * 0.65),
			Vector2(scar_x + 1.5, rect.size.y * 0.5 - 1.5),
		])
		warning.add_child(scar)

	var section := {
		"body": body,
		"rect": rect,
		"color": color,
		"trigger": trigger,
		"warning": warning,
		"fuse_started": false,
		"fuse_at": -1.0,
		"fuse_seconds": fuse_seconds,
		"crumbled": false,
	}
	_crumbling_sections.append(section)

	trigger.body_entered.connect(_on_crumble_trigger_entered.bind(section))
	return body

func _on_crumble_trigger_entered(_body: Node, section: Dictionary) -> void:
	if section["fuse_started"] or section["crumbled"]:
		return
	section["fuse_started"] = true
	section["fuse_at"] = _time + section["fuse_seconds"]

func _tick_crumbling_sections() -> void:
	for section in _crumbling_sections:
		if section["crumbled"]:
			continue
		if not section["fuse_started"]:
			continue
		var body: Node = section["body"]
		if not is_instance_valid(body):
			section["crumbled"] = true
			continue
		var time_left: float = section["fuse_at"] - _time
		if time_left <= 0.0:
			_trigger_crumble(section)
			continue
		# Ramp warning visibility from subtle (early in fuse) to obvious (last
		# few seconds). Add a small breathing pulse so it's clearly alive.
		var fuse_seconds: float = section["fuse_seconds"]
		var progress: float = clampf(1.0 - time_left / fuse_seconds, 0.0, 1.0)
		var pulse: float = 0.5 + 0.5 * sin(_time * 5.6)
		var alpha: float = pow(progress, 2.0) * (0.55 + 0.45 * pulse)
		var warning: Node2D = section["warning"]
		if is_instance_valid(warning):
			warning.modulate.a = alpha

func _trigger_crumble(section: Dictionary) -> void:
	if section["crumbled"]:
		return
	section["crumbled"] = true
	var rect: Rect2 = section["rect"]
	var color: Color = section["color"]
	# Drop the rect from the support-rects list so future builders don't try
	# to anchor a bridge to a section that just fell into Styx.
	collision_rects.erase(rect)
	_spawn_crumble_debris(rect, color)
	var body: Node = section["body"]
	if is_instance_valid(body):
		body.queue_free()

func _spawn_crumble_debris(rect: Rect2, color: Color) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(rect.position.x * 113.0 + 8191.0)
	var chunk_count := 9
	for i in chunk_count:
		var chunk := Polygon2D.new()
		chunk.color = color.darkened(rng.randf_range(0.0, 0.18))
		var sx := rng.randf_range(5.0, 11.0)
		var sy := rng.randf_range(4.0, 8.0)
		chunk.polygon = PackedVector2Array([
			Vector2(-sx * 0.5, -sy * 0.5),
			Vector2(sx * 0.5 + rng.randf_range(-1.5, 1.5), -sy * 0.5),
			Vector2(sx * 0.5, sy * 0.5),
			Vector2(-sx * 0.5 + rng.randf_range(-1.5, 1.5), sy * 0.5),
		])
		chunk.global_position = rect.position + Vector2(
			rng.randf_range(2.0, rect.size.x - 2.0),
			rng.randf_range(0.0, rect.size.y)
		)
		chunk.rotation = rng.randf_range(-0.4, 0.4)
		add_child(chunk)
		var fall := rng.randf_range(180.0, 320.0)
		var spin := rng.randf_range(-2.8, 2.8)
		var sway := rng.randf_range(-22.0, 22.0)
		var dur := rng.randf_range(1.2, 1.8)
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(chunk, "global_position:y", chunk.global_position.y + fall, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(chunk, "global_position:x", chunk.global_position.x + sway, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(chunk, "rotation", chunk.rotation + spin, dur)
		tween.tween_property(chunk, "modulate:a", 0.0, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tween.chain().tween_callback(chunk.queue_free)

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

func _build_bubbles() -> void:
	_bubble_specs.clear()
	for i in 22:
		_bubble_specs.append({
			"x": 52.0 + fposmod(float(i) * 137.0, WORLD_WIDTH - 104.0),
			"phase": float(i) * 0.071,
			"speed": 0.055 + float(i % 5) * 0.012,
			"rise": 46.0 + float((i * 11) % 64),
			"size": 2.0 + float((i * 7) % 9) * 0.42,
			"sway": 8.0 + float((i * 3) % 13),
		})

func _tick_bubble_pops() -> void:
	for spec in _bubble_specs:
		var cycle := fposmod(_time * float(spec["speed"]) + float(spec["phase"]), 1.0)
		var last_cycle := fposmod((_time - 1.0 / TERRAIN_REDRAW_FPS) * float(spec["speed"]) + float(spec["phase"]), 1.0)
		if cycle < last_cycle:
			_bubble_pops.append({
				"pos": Vector2(float(spec["x"]), STYX_WATERLINE_Y + 4.0),
				"born": _time,
				"size": float(spec["size"]),
			})
	for i in range(_bubble_pops.size() - 1, -1, -1):
		if _time - float(_bubble_pops[i]["born"]) > 0.46:
			_bubble_pops.remove_at(i)

func _draw() -> void:
	_draw_crypt_gradient()
	_draw_distant_underworld_background()
	_draw_ground_dust()
	_draw_styx_water()
	_draw_platform_ash_motes()

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
	# Single coherent atmospheric pass: a low-contrast crimson dawn band
	# bleeding into the crypt gradient, a far horizon of jagged crypt towers,
	# a tighter tree silhouette layer, and a few breathing lantern flames.
	# Designed to read as ONE distant skyline, not a stack of competing motifs.
	_draw_horizon_haze()
	_draw_far_skyline()
	_draw_near_tree_line()
	_draw_horizon_lanterns()

func _draw_horizon_haze() -> void:
	# Soft crimson-to-dark gradient band, kept low-saturation so the playable
	# layer always has more visual weight.
	for i in 22:
		var t := float(i) / 21.0
		var color := Color(
			0.085 + t * 0.040,
			0.022 + t * 0.014,
			0.032 + t * 0.020,
			0.20 - t * 0.080
		)
		draw_rect(Rect2(0, 80.0 + i * 11.5, WORLD_WIDTH, 13.0), color)

func _draw_far_skyline() -> void:
	# A continuous, slightly-uneven skyline of distant crypt towers. Heights
	# follow a low-frequency sine so the silhouette feels like a city skyline
	# rather than a row of identical pieces.
	var skyline_color := Color(0.025, 0.020, 0.032, 0.62)
	var base_y := 295.0
	var points := PackedVector2Array()
	points.append(Vector2(0, base_y + 60.0))
	for x in range(0, WORLD_WIDTH + 24, 24):
		var fx := float(x)
		# Mix three sines for a non-repeating profile.
		var h := 28.0 \
			+ sin(fx * 0.0061) * 18.0 \
			+ sin(fx * 0.0143 + 1.2) * 12.0 \
			+ sin(fx * 0.0319 + 0.7) * 5.0
		# Occasional taller spire — every ~5th step, controlled by a slow sine.
		if sin(fx * 0.011 + 2.4) > 0.78:
			h += 28.0
		points.append(Vector2(fx, base_y - h))
	points.append(Vector2(WORLD_WIDTH, base_y + 60.0))
	draw_colored_polygon(points, skyline_color)

func _draw_near_tree_line() -> void:
	# Mid-distance dead-tree silhouette layer in front of the skyline. Smaller
	# and darker than the towers behind, sitting just above the play floor.
	var tree_color := Color(0.014, 0.010, 0.020, 0.58)
	var base_y := 358.0
	var points := PackedVector2Array()
	points.append(Vector2(0, base_y + 60.0))
	for x in range(0, WORLD_WIDTH + 16, 16):
		var fx := float(x)
		var h := 14.0 + absf(sin(fx * 0.024 + 0.4)) * 12.0 + sin(fx * 0.071 + 1.9) * 4.0
		points.append(Vector2(fx, base_y - h))
	points.append(Vector2(WORLD_WIDTH, base_y + 60.0))
	draw_colored_polygon(points, tree_color)

func _draw_horizon_lanterns() -> void:
	# Three lit windows / brazier dots sprinkled along the skyline. Slow pulse,
	# warm color. Replaces the prior cluttered light-pool / portal-ruin /
	# rib-arch layers with a single tiny detail per spot.
	var spots := [
		{"pos": Vector2(345.0, 252.0), "warm": true},
		{"pos": Vector2(910.0, 230.0), "warm": false},
		{"pos": Vector2(1480.0, 248.0), "warm": true},
		{"pos": Vector2(2030.0, 236.0), "warm": false},
	]
	for spot in spots:
		var pos: Vector2 = spot["pos"]
		var warm: bool = spot["warm"]
		var pulse := 0.55 + 0.45 * (0.5 + 0.5 * sin(_time * 1.4 + pos.x * 0.013))
		var color := Color(0.96, 0.74, 0.32, 0.55 * pulse) if warm else Color(0.52, 0.92, 0.58, 0.42 * pulse)
		draw_circle(pos, 9.0, Color(color.r, color.g, color.b, color.a * 0.20))
		draw_circle(pos, 3.4, color)

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
	_draw_styx_bubbles()
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

func _draw_styx_bubbles() -> void:
	for spec in _bubble_specs:
		var cycle := fposmod(_time * float(spec["speed"]) + float(spec["phase"]), 1.0)
		var lift := smoothstep(0.0, 1.0, cycle) * float(spec["rise"])
		var pos := Vector2(
			float(spec["x"]) + sin(_time * 1.8 + float(spec["phase"]) * 21.0) * float(spec["sway"]),
			STYX_WATERLINE_Y + 72.0 - lift
		)
		var alpha := sin(cycle * PI) * 0.22
		var size := float(spec["size"]) * lerpf(0.55, 1.15, cycle)
		var rim := Color(0.68, 0.86, 0.62, alpha)
		draw_circle(pos, size * 1.8, Color(0.15, 0.26, 0.17, alpha * 0.28))
		draw_arc(pos, size, -0.4, PI * 1.36, 12, rim, 1.1, true)
		draw_circle(pos + Vector2(-size * 0.28, -size * 0.24), maxf(0.7, size * 0.18), Color(0.92, 0.98, 0.76, alpha * 0.55))
	for pop in _bubble_pops:
		_draw_bubble_pop(pop)

func _draw_bubble_pop(pop: Dictionary) -> void:
	var age := clampf((_time - float(pop["born"])) / 0.46, 0.0, 1.0)
	var pos: Vector2 = pop["pos"]
	var radius := float(pop["size"]) * lerpf(1.1, 5.6, age)
	var alpha := (1.0 - age) * 0.26
	draw_arc(pos, radius, 0.0, TAU, 18, Color(0.82, 0.95, 0.62, alpha), 1.2, true)
	draw_line(pos + Vector2(-radius * 0.7, 0), pos + Vector2(-radius * 1.15, -radius * 0.45), Color(0.82, 0.95, 0.62, alpha * 0.75), 1.0, true)
	draw_line(pos + Vector2(radius * 0.6, -radius * 0.1), pos + Vector2(radius * 1.05, -radius * 0.55), Color(0.82, 0.95, 0.62, alpha * 0.75), 1.0, true)

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
