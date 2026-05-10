extends Node2D

const FRAGMENT_COUNT := 6
const RIPPLE_COUNT := 3
const LIFE_SECONDS := 0.85
const GRAVITY := 620.0
const STYX_SURFACE_Y := 560.0
const REDRAW_FPS := 30.0

var _age := 0.0
var _fragments: Array[Dictionary] = []
var _ripples: Array[Dictionary] = []
var _goop_jets: Array[Dictionary] = []
var _redraw_timer := 0.0

func _ready() -> void:
	_build_fragments()
	_build_styx_impact()
	queue_redraw()

func _process(delta: float) -> void:
	_age += delta
	_redraw_timer += delta
	for fragment in _fragments:
		fragment["velocity"].y += GRAVITY * delta
		fragment["position"] += fragment["velocity"] * delta
		fragment["rotation"] += fragment["spin"] * delta

	if _age >= LIFE_SECONDS:
		queue_free()
		return

	if _redraw_timer >= 1.0 / REDRAW_FPS:
		_redraw_timer = 0.0
		queue_redraw()

func _build_fragments() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in FRAGMENT_COUNT:
		var angle := rng.randf_range(-PI * 0.92, -PI * 0.08)
		var speed := rng.randf_range(86.0, 188.0)
		_fragments.append({
			"position": Vector2(rng.randf_range(-4.0, 4.0), rng.randf_range(-18.0, -4.0)),
			"velocity": Vector2(cos(angle), sin(angle)) * speed,
			"length": rng.randf_range(5.0, 12.0),
			"radius": rng.randf_range(1.8, 3.8),
			"rotation": rng.randf_range(0.0, TAU),
			"spin": rng.randf_range(-12.0, 12.0),
			"round": rng.randi_range(0, 3) == 0,
		})

func _build_styx_impact() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in RIPPLE_COUNT:
		_ripples.append({
			"delay": float(i) * 0.045,
			"width": rng.randf_range(36.0, 86.0),
			"offset": rng.randf_range(-14.0, 14.0),
			"phase": rng.randf_range(0.0, TAU),
		})
	for i in 5:
		_goop_jets.append({
			"x": rng.randf_range(-24.0, 24.0),
			"height": rng.randf_range(16.0, 42.0),
			"lean": rng.randf_range(-10.0, 10.0),
			"delay": rng.randf_range(0.0, 0.16),
			"width": rng.randf_range(2.0, 4.6),
		})

func _draw() -> void:
	var fade := clampf(1.0 - (_age / LIFE_SECONDS), 0.0, 1.0)
	_draw_styx_impact(fade)
	_draw_bone_fragments(fade)

func _draw_styx_impact(fade: float) -> void:
	var surface_local_y := STYX_SURFACE_Y - global_position.y
	var impact_fade := clampf(1.0 - (_age / 0.62), 0.0, 1.0)
	for jet in _goop_jets:
		var delay := float(jet["delay"])
		if _age < delay:
			continue
		var t := clampf((_age - delay) / 0.42, 0.0, 1.0)
		var height := float(jet["height"]) * sin(t * PI)
		var x := float(jet["x"])
		var lean := float(jet["lean"]) * t
		var base := Vector2(x, surface_local_y + 4.0)
		var tip := Vector2(x + lean, surface_local_y - height)
		draw_line(base, tip, Color(0.18, 0.14, 0.09, impact_fade * 0.58), float(jet["width"]), true)
		draw_line(base + Vector2(2, 0), tip + Vector2(2, 1), Color(0.42, 0.33, 0.16, impact_fade * 0.18), 1.2, true)

	for ripple in _ripples:
		var delay := float(ripple["delay"])
		if _age < delay:
			continue
		var t := clampf((_age - delay) / 0.68, 0.0, 1.0)
		var half_width := lerpf(6.0, float(ripple["width"]), t)
		var alpha := sin(t * PI) * 0.34 * fade
		var y := surface_local_y + float(ripple["offset"]) * 0.12
		var points := PackedVector2Array()
		for j in 9:
			var u := float(j) / 8.0
			var x := lerpf(-half_width, half_width, u)
			var wave := sin(float(ripple["phase"]) + u * TAU * 1.4 + _age * 8.0) * 2.8 * (1.0 - t)
			points.append(Vector2(x, y + wave))
		draw_polyline(points, Color(0.55, 0.44, 0.22, alpha), 2.2, true)

func _draw_bone_fragments(fade: float) -> void:
	var bone := Color(0.91, 0.86, 0.72, fade)
	var shadow := Color(0.14, 0.11, 0.18, fade * 0.45)

	for fragment in _fragments:
		var pos: Vector2 = fragment["position"]
		if fragment["round"]:
			draw_circle(pos + Vector2(1, 1), fragment["radius"], shadow)
			draw_circle(pos, fragment["radius"], bone)
		else:
			var dir := Vector2.RIGHT.rotated(float(fragment["rotation"]))
			var half_len := float(fragment["length"]) * 0.5
			draw_line(pos - dir * half_len + Vector2(1, 1), pos + dir * half_len + Vector2(1, 1), shadow, 3.0)
			draw_line(pos - dir * half_len, pos + dir * half_len, bone, 2.0)
