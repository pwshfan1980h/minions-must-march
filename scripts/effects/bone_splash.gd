extends Node2D

const FRAGMENT_COUNT := 10
const LIFE_SECONDS := 0.55
const GRAVITY := 620.0

var _age := 0.0
var _fragments: Array[Dictionary] = []

func _ready() -> void:
	_build_fragments()
	queue_redraw()

func _process(delta: float) -> void:
	_age += delta
	for fragment in _fragments:
		fragment["velocity"].y += GRAVITY * delta
		fragment["position"] += fragment["velocity"] * delta
		fragment["rotation"] += fragment["spin"] * delta

	if _age >= LIFE_SECONDS:
		queue_free()
		return

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

func _draw() -> void:
	var fade := clampf(1.0 - (_age / LIFE_SECONDS), 0.0, 1.0)
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
