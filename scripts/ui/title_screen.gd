extends Node2D

const GAME_ROOT_PATH := "res://scenes/GameRoot.tscn"
const SCREEN_WIDTH := 1280
const SCREEN_HEIGHT := 720

@onready var prompt_label: Label = $UI/PromptLabel

const AMBIENT_GROUND_Y := 508.0
const AMBIENT_WALK_SPEED := 22.0

var _time := 0.0
var _starting := false
var _ambient_skeletons: Array[Dictionary] = []

func _ready() -> void:
	_seed_ambient_skeletons()
	queue_redraw()

func _seed_ambient_skeletons() -> void:
	# A small wandering chorus across the foreground. Varied sizes and phases
	# so the silhouettes don't move in lockstep. Bounds keep them in the wide
	# central area so they pass behind the title text.
	var rng := RandomNumberGenerator.new()
	rng.seed = 0xBEEFCAFE
	for i in 6:
		_ambient_skeletons.append({
			"x": rng.randf_range(140.0, 1140.0),
			"y_offset": rng.randf_range(-4.0, 6.0),
			"dir": 1.0 if rng.randf() < 0.5 else -1.0,
			"scale": rng.randf_range(0.78, 1.05),
			"phase": rng.randf_range(0.0, TAU),
			"speed": AMBIENT_WALK_SPEED * rng.randf_range(0.8, 1.18),
			"left_bound": rng.randf_range(80.0, 220.0),
			"right_bound": rng.randf_range(1060.0, 1200.0),
		})

func _process(delta: float) -> void:
	_time += delta
	_step_ambient_skeletons(delta)
	queue_redraw()
	if prompt_label != null:
		# Slow breathing pulse on the "click to begin" prompt.
		var pulse: float = 0.55 + 0.45 * (0.5 + 0.5 * sin(_time * 2.2))
		prompt_label.modulate.a = pulse if not _starting else clampf(prompt_label.modulate.a - delta * 2.5, 0.0, 1.0)

func _step_ambient_skeletons(delta: float) -> void:
	for skel in _ambient_skeletons:
		var dx: float = float(skel["dir"]) * float(skel["speed"]) * delta
		skel["x"] = float(skel["x"]) + dx
		skel["phase"] = float(skel["phase"]) + delta * 8.0
		if skel["x"] >= float(skel["right_bound"]):
			skel["x"] = float(skel["right_bound"])
			skel["dir"] = -1.0
		elif skel["x"] <= float(skel["left_bound"]):
			skel["x"] = float(skel["left_bound"])
			skel["dir"] = 1.0

func _unhandled_input(event: InputEvent) -> void:
	if _starting:
		return
	var go := false
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		go = true
	elif event is InputEventKey and event.pressed and not event.is_echo():
		go = true
	if go:
		_starting = true
		LevelState.reset()
		# Brief delay so the click register reads on screen before the cut.
		await get_tree().create_timer(0.18).timeout
		get_tree().change_scene_to_file(GAME_ROOT_PATH)

func _draw() -> void:
	_draw_background()
	_draw_horizon()
	_draw_skull_motif()
	_draw_ambient_skeletons()

func _draw_ambient_skeletons() -> void:
	# Pure-silhouette skeletons ambling along the foreground. No bone detail —
	# they read as dark shapes lit from behind by the distant horizon glow.
	# Bumped well above pure black so they read clearly against the dark
	# gradient and crimson horizon haze behind them.
	var silhouette := Color(0.16, 0.14, 0.20, 0.96)
	for skel in _ambient_skeletons:
		var sx: float = float(skel["x"])
		var face: float = float(skel["dir"])
		var s: float = float(skel["scale"])
		var phase: float = float(skel["phase"])
		var stride: float = sin(phase)
		var bob: float = absf(stride) * 1.4 * s
		var base_y: float = AMBIENT_GROUND_Y + float(skel["y_offset"])
		_draw_silhouette_skeleton(Vector2(sx, base_y - bob), face, s, stride, silhouette)

func _draw_silhouette_skeleton(pos: Vector2, face: float, s: float, stride: float, color: Color) -> void:
	# Coarse skeleton silhouette: head circle, torso slab, two legs swinging in
	# alternation, two arms counter-swinging. No internal bone detail — by
	# design a flat dark cutout against the background haze.
	var head_r := 7.0 * s
	var head_pos := pos + Vector2(face * 1.0, -38.0 * s)
	draw_circle(head_pos, head_r, color)

	# Torso as a symmetric tapered quad. Vertex order is fixed (TL, TR, BR, BL)
	# regardless of face so triangulation never sees a crossed polygon.
	var torso := PackedVector2Array([
		head_pos + Vector2(-4.5 * s, head_r * 0.6),
		head_pos + Vector2(4.5 * s, head_r * 0.6),
		pos + Vector2(5.0 * s, -2.0 * s),
		pos + Vector2(-5.0 * s, -2.0 * s),
	])
	draw_colored_polygon(torso, color)

	# Legs: alternating swing.
	var leg_lift_a: float = maxf(0.0, stride) * 5.0 * s
	var leg_lift_b: float = maxf(0.0, -stride) * 5.0 * s
	var hip_a := pos + Vector2(face * 2.0 * s, -1.0 * s)
	var hip_b := pos + Vector2(-face * 2.0 * s, -1.0 * s)
	var ankle_a := pos + Vector2(face * (3.0 + stride * 4.0) * s, 18.0 * s - leg_lift_a)
	var ankle_b := pos + Vector2(-face * (3.0 + stride * 4.0) * s, 18.0 * s - leg_lift_b)
	draw_line(hip_a, ankle_a, color, 2.4 * s, true)
	draw_line(hip_b, ankle_b, color, 2.4 * s, true)
	# Tiny foot stubs.
	draw_line(ankle_a, ankle_a + Vector2(face * 4.0 * s, 1.5 * s), color, 2.0 * s, true)
	draw_line(ankle_b, ankle_b + Vector2(-face * 4.0 * s, 1.5 * s), color, 2.0 * s, true)

	# Arms: counter-swing.
	var shoulder := pos + Vector2(0, -22.0 * s)
	var arm_swing := -stride
	draw_line(shoulder, shoulder + Vector2(face * (5.0 + arm_swing * 3.0) * s, 12.0 * s), color, 2.0 * s, true)
	draw_line(shoulder, shoulder + Vector2(-face * (5.0 - arm_swing * 3.0) * s, 12.0 * s), color, 2.0 * s, true)

func _draw_background() -> void:
	# Dark crypt gradient, top to bottom.
	var bands := 32
	for i in bands:
		var t := float(i) / float(bands - 1)
		var color := Color(
			0.012 + t * 0.06,
			0.010 + t * 0.05,
			0.018 + t * 0.10,
			1.0
		)
		var y := t * SCREEN_HEIGHT
		draw_rect(Rect2(0, y, SCREEN_WIDTH, SCREEN_HEIGHT / bands + 2.0), color)
	# Faint underworld glow behind the title.
	draw_circle(Vector2(SCREEN_WIDTH * 0.5, SCREEN_HEIGHT * 0.42), 360, Color(0.42, 0.30, 0.18, 0.05))
	draw_circle(Vector2(SCREEN_WIDTH * 0.5, SCREEN_HEIGHT * 0.62), 220, Color(0.22, 0.36, 0.30, 0.05))

func _draw_horizon() -> void:
	# Distant ruined skyline silhouette across the bottom third.
	var horizon_y := SCREEN_HEIGHT * 0.74
	draw_rect(Rect2(0, horizon_y, SCREEN_WIDTH, SCREEN_HEIGHT - horizon_y), Color(0.020, 0.015, 0.024, 0.85))
	# Jagged tree/ruin tops.
	for x in range(-20, SCREEN_WIDTH + 40, 28):
		var peak := horizon_y - 18.0 - sin(float(x) * 0.011) * 14.0 - sin(float(x) * 0.027 + 1.7) * 10.0
		var crown := PackedVector2Array([
			Vector2(x - 8.0, horizon_y + 4.0),
			Vector2(x + 13.0, peak),
			Vector2(x + 34.0, horizon_y + 4.0),
		])
		draw_colored_polygon(crown, Color(0.012, 0.010, 0.018, 0.78))
	# Two distant lit windows.
	for slot in [Vector2(SCREEN_WIDTH * 0.27, horizon_y + 14.0), Vector2(SCREEN_WIDTH * 0.71, horizon_y + 22.0)]:
		var pulse: float = 0.62 + 0.38 * sin(_time * 1.4 + slot.x * 0.01)
		draw_rect(Rect2(slot, Vector2(4.0, 7.0)), Color(0.96, 0.74, 0.32, 0.55 * pulse))

func _draw_skull_motif() -> void:
	# A faint single skull silhouette behind the title text. Adds atmosphere
	# without competing with the name itself.
	var center := Vector2(SCREEN_WIDTH * 0.5, SCREEN_HEIGHT * 0.42)
	var bone := Color(0.78, 0.74, 0.68, 0.07)
	var eye := Color(0.04, 0.03, 0.05, 0.18)
	var skull_polygon := PackedVector2Array([
		center + Vector2(-110, -100),
		center + Vector2(110, -100),
		center + Vector2(150, -40),
		center + Vector2(150, 40),
		center + Vector2(110, 110),
		center + Vector2(40, 140),
		center + Vector2(-40, 140),
		center + Vector2(-110, 110),
		center + Vector2(-150, 40),
		center + Vector2(-150, -40),
	])
	draw_colored_polygon(skull_polygon, bone)
	draw_circle(center + Vector2(-55, -10), 26, eye)
	draw_circle(center + Vector2(55, -10), 26, eye)
	# Teeth row.
	for i in 8:
		var tx := center.x - 70.0 + float(i) * 20.0
		draw_rect(Rect2(tx, center.y + 60.0, 14.0, 26.0), Color(0.78, 0.74, 0.68, 0.05))
