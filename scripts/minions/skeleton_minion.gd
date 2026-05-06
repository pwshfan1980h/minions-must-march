extends CharacterBody2D

signal exited(minion: Node)
signal died(minion: Node)
signal death_started(minion: Node, death_kind: String)
signal clicked(minion: Node)

const BoneSplashScene := preload("res://scenes/effects/BoneSplash.tscn")

const WALK_SPEED := 42.0
const GRAVITY := 760.0
const MAX_FALL_SPEED := 520.0
const FATAL_FALL_SPEED := 470.0
const WALL_NORMAL_THRESHOLD := 0.65
const BLOCKER_TURN_DISTANCE := 22.0
const BLOCKER_VERTICAL_TOLERANCE := 18.0
const STYX_SURFACE_Y := 560.0

var direction := 1.0
var alive := true
var rescued := false
var is_blocker := false
var highest_fall_speed := 0.0
var death_kind := ""

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

func rescue(exit_position := Vector2.INF) -> void:
	if rescued or not alive:
		return
	rescued = true
	alive = false
	velocity = Vector2.ZERO
	set_physics_process(false)
	set_process_input(false)
	if collision_shape != null:
		collision_shape.set_deferred("disabled", true)
	if is_blocker:
		remove_from_group("blockers")

	var target_x := global_position.x
	if exit_position != Vector2.INF:
		target_x = exit_position.x
	exited.emit(self)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "global_position:x", target_x, 0.20).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position:y", global_position.y - 86.0, 0.82).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "modulate", Color(0.92, 1.0, 0.72, 0.0), 0.82).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2(0.52, 0.52), 0.82).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished
	queue_free()

func become_blocker() -> bool:
	if not alive or rescued or is_blocker or not is_on_floor():
		return false
	is_blocker = true
	velocity = Vector2.ZERO
	add_to_group("blockers")
	queue_redraw()
	return true

func resume_march() -> bool:
	if not alive or rescued or not is_blocker:
		return false
	is_blocker = false
	remove_from_group("blockers")
	queue_redraw()
	return true

func die_to(kind: String) -> void:
	if not alive or rescued:
		return
	death_kind = kind
	if kind == "styx_water":
		_die_in_styx()
	else:
		_die()

func _die() -> void:
	if not alive or rescued:
		return
	death_kind = "fall" if death_kind.is_empty() else death_kind
	alive = false
	death_started.emit(self, death_kind)
	if is_blocker:
		remove_from_group("blockers")
	_spawn_bone_splash()
	died.emit(self)
	queue_free()

func _die_in_styx() -> void:
	global_position.y = minf(global_position.y, STYX_SURFACE_Y + 2.0)
	alive = false
	death_started.emit(self, death_kind)
	velocity = Vector2.ZERO
	set_physics_process(false)
	set_process_input(false)
	if collision_shape != null:
		collision_shape.set_deferred("disabled", true)
	if is_blocker:
		remove_from_group("blockers")
	_spawn_bone_splash()
	var impact := create_tween()
	impact.set_parallel(true)
	impact.tween_property(self, "position:y", position.y + 8.0, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	impact.tween_property(self, "scale", Vector2(1.12, 0.84), 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await impact.finished

	var sink := create_tween()
	sink.set_parallel(true)
	sink.tween_property(self, "modulate:a", 0.0, 0.78).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	sink.tween_property(self, "position:y", position.y + 44.0, 0.78).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	sink.tween_property(self, "scale", Vector2(0.72, 0.52), 0.78).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await sink.finished
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
