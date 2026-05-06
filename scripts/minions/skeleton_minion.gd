extends CharacterBody2D

signal exited(minion: Node)
signal died(minion: Node)
signal clicked(minion: Node)

const BoneSplashScene := preload("res://scenes/effects/BoneSplash.tscn")

const WALK_SPEED := 42.0
const GRAVITY := 760.0
const MAX_FALL_SPEED := 520.0
const FATAL_FALL_SPEED := 470.0
const WALL_NORMAL_THRESHOLD := 0.65
const BLOCKER_TURN_DISTANCE := 22.0
const BLOCKER_VERTICAL_TOLERANCE := 18.0

var direction := 1.0
var alive := true
var rescued := false
var is_blocker := false
var highest_fall_speed := 0.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group("minions")
	input_pickable = true
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not alive or rescued:
		return

	velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)
	velocity.x = 0.0 if is_blocker else WALK_SPEED * direction
	if not is_blocker:
		highest_fall_speed = maxf(highest_fall_speed, velocity.y)

	move_and_slide()

	if is_on_floor():
		if highest_fall_speed >= FATAL_FALL_SPEED:
			_die()
		else:
			highest_fall_speed = 0.0

		if not is_blocker and (_is_blocked_ahead() or _has_blocker_ahead()):
			_turn_around()

	if position.y > 760:
		_die()

	queue_redraw()

func rescue() -> void:
	if rescued or not alive:
		return
	rescued = true
	alive = false
	if is_blocker:
		remove_from_group("blockers")
	hide()
	exited.emit(self)
	queue_free()

func become_blocker() -> bool:
	if not alive or rescued or is_blocker or not is_on_floor():
		return false
	is_blocker = true
	velocity = Vector2.ZERO
	add_to_group("blockers")
	queue_redraw()
	return true

func _die() -> void:
	if not alive or rescued:
		return
	alive = false
	if is_blocker:
		remove_from_group("blockers")
	_spawn_bone_splash()
	died.emit(self)
	queue_free()

func _spawn_bone_splash() -> void:
	var splash := BoneSplashScene.instantiate()
	splash.global_position = global_position
	get_parent().add_child(splash)

func _turn_around() -> void:
	direction *= -1.0

func _is_blocked_ahead() -> bool:
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		if absf(collision.get_normal().x) > WALL_NORMAL_THRESHOLD:
			return true
	return false

func _has_blocker_ahead() -> bool:
	for blocker in get_tree().get_nodes_in_group("blockers"):
		if blocker == self or not is_instance_valid(blocker):
			continue
		var blocker_offset: Vector2 = blocker.global_position - global_position
		if absf(blocker_offset.y) <= BLOCKER_VERTICAL_TOLERANCE and signf(blocker_offset.x) == signf(direction):
			if absf(blocker_offset.x) <= BLOCKER_TURN_DISTANCE:
				return true
	return false

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(self)

func _draw() -> void:
	# Tiny lanky skeleton placeholder. Real sprite/animation comes later.
	var bone := Color("f1e7c8") if is_blocker else Color("e8e0c8") if alive else Color("8c7f91")
	var shadow := Color("211b2b")
	draw_circle(Vector2(0, -22), 8, bone)
	draw_circle(Vector2(-3, -24), 1.8, shadow)
	draw_circle(Vector2(3, -24), 1.8, shadow)
	draw_line(Vector2(0, -14), Vector2(0, 2), bone, 3)
	if is_blocker:
		draw_line(Vector2(-14, -8), Vector2(14, -8), bone, 3)
		draw_line(Vector2(-10, 12), Vector2(-18, 16), bone, 3)
		draw_line(Vector2(10, 12), Vector2(18, 16), bone, 3)
		draw_rect(Rect2(Vector2(-19, -28), Vector2(38, 48)), Color(0.95, 0.76, 0.23, 0.18), false, 2.0)
	else:
		draw_line(Vector2(-8, -8), Vector2(8, -8), bone, 2)
		draw_line(Vector2(-4, 2), Vector2(-8, 14), bone, 2)
		draw_line(Vector2(4, 2), Vector2(8, 14), bone, 2)
		draw_line(Vector2(-8, -6), Vector2(-12, 4), bone, 2)
		draw_line(Vector2(8, -6), Vector2(12, 4), bone, 2)
