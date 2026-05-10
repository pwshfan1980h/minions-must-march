extends Node2D

const GAME_ROOT_PATH := "res://scenes/GameRoot.tscn"
const SCREEN_WIDTH := 1280
const SCREEN_HEIGHT := 720

@onready var prompt_label: Label = $UI/PromptLabel

var _time := 0.0
var _starting := false

func _ready() -> void:
	queue_redraw()

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()
	if prompt_label != null:
		# Slow breathing pulse on the "click to begin" prompt.
		var pulse: float = 0.55 + 0.45 * (0.5 + 0.5 * sin(_time * 2.2))
		prompt_label.modulate.a = pulse if not _starting else clampf(prompt_label.modulate.a - delta * 2.5, 0.0, 1.0)

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
		# Brief delay so the click register reads on screen before the cut.
		await get_tree().create_timer(0.18).timeout
		get_tree().change_scene_to_file(GAME_ROOT_PATH)

func _draw() -> void:
	_draw_background()
	_draw_horizon()
	_draw_skull_motif()

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
