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
const VISUAL_SCALE := 0.72
const WALK_ANIM_FPS := 14.0

var direction := 1.0
var alive := true
var rescued := false
var is_blocker := false
var highest_fall_speed := 0.0
var death_kind := ""
var _walk_time := 0.0
var _height_variant := 1.0
var _spine_variant := 0.0
var _stride_variant := 1.0
var _last_anim_frame := -1

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group("minions")
	input_pickable = true
	var rng := RandomNumberGenerator.new()
	rng.seed = int(get_instance_id())
	_height_variant = rng.randf_range(0.92, 1.10)
	_spine_variant = rng.randf_range(-0.10, 0.16)
	_stride_variant = rng.randf_range(0.88, 1.14)
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not alive or rescued:
		return

	velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)
	velocity.x = 0.0 if is_blocker else WALK_SPEED * direction
	if is_on_floor() and not is_blocker:
		_walk_time += delta * 8.8 * _stride_variant
		var anim_frame := int(_walk_time * WALK_ANIM_FPS)
		if anim_frame != _last_anim_frame:
			_last_anim_frame = anim_frame
			queue_redraw()
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
	queue_redraw()

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
	# Draw at a smaller in-world scale. This keeps the same level camera/field,
	# but makes the crowd feel more numerous and less toy-large.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(VISUAL_SCALE, VISUAL_SCALE))

	var bone := Color("f1e7c8") if is_blocker else Color("e8e0c8") if alive else Color("8c7f91")
	var shadow := Color("211b2b")
	var accent := Color("b9a77b")
	var back_bone := bone.darkened(0.16)
	var face := signf(direction)
	if face == 0.0:
		face = 1.0

	var stride := 0.0 if is_blocker else sin(_walk_time)
	var leg_front_phase := stride
	var leg_back_phase := -stride
	var front_lift := maxf(0.0, leg_front_phase)
	var back_lift := maxf(0.0, leg_back_phase)
	var bob := 0.0 if is_blocker else absf(stride) * 1.05
	var lean := face * (2.8 + _spine_variant * 7.0 + (0.45 * absf(stride) if not is_blocker else -1.0))
	var h := _height_variant

	var hip := Vector2(-face * 0.8, 3.0 - bob)
	var chest := Vector2(lean * 0.45, -12.5 * h - bob)
	var neck := Vector2(lean * 0.78, -19.2 * h - bob)
	var head := neck + Vector2(face * 4.0, -5.9 * h)
	var shoulder := chest + Vector2(face * 1.4, -0.8)

	# Core silhouette first: spine, compact ribs, pelvis. Fewer draw calls than the
	# earlier anatomy pass, but enough bone landmarks to read at small scale.
	_draw_bone_segment(hip, chest, bone, 2.6)
	for i in 3:
		var t := float(i) / 2.0
		var rib_center := chest.lerp(hip + Vector2(face * 0.5, -4.5), t)
		var rib_width := lerpf(6.6, 4.2, t) * h
		draw_arc(rib_center, rib_width, -0.72 * PI if face > 0.0 else -0.28 * PI, 0.18 * PI if face > 0.0 else 1.22 * PI, 6, bone, 1.35)
	_draw_pelvis(hip, face, bone.darkened(0.04), h)
	_draw_clavicles(chest, shoulder, face, bone.darkened(0.02))
	_draw_side_skull(head, face, bone, shadow)

	# Arms: counter-swing, but subordinate to legs for readability.
	var arm_swing := -stride
	var elbow_front := shoulder + Vector2(face * (6.0 + arm_swing * 2.4), 7.2 + stride * 1.2)
	var hand_front := elbow_front + Vector2(face * (4.8 + arm_swing * 1.5), 7.2 - stride * 0.9)
	var elbow_back := shoulder + Vector2(-face * (4.8 + arm_swing * 1.6), 6.8 - stride * 1.0)
	var hand_back := elbow_back + Vector2(-face * (4.4 + arm_swing * 1.6), 7.0 + stride * 0.7)

	# Legs: explicit two-phase side-view gait. Near/far legs move in opposite
	# horizontal phases: one plants behind while the other passes forward.
	var ground_y := 24.6 * h
	var hip_front := hip + Vector2(face * 2.4, 2.4 * h)
	var hip_back := hip + Vector2(-face * 2.8, 2.6 * h)
	var ankle_front := Vector2(face * (8.4 + leg_front_phase * 5.6), ground_y - front_lift * 2.9)
	var ankle_back := Vector2(face * (-8.2 + leg_back_phase * 5.3), ground_y - back_lift * 2.7)
	var knee_front := Vector2(face * (4.6 + leg_front_phase * 3.7), lerpf(hip_front.y + 7.2 * h, ankle_front.y - 6.6 * h, 0.58) - front_lift * 2.0)
	var knee_back := Vector2(face * (-4.8 + leg_back_phase * 3.5), lerpf(hip_back.y + 7.4 * h, ankle_back.y - 6.4 * h, 0.58) - back_lift * 1.9)

	if is_blocker:
		elbow_front = shoulder + Vector2(face * 13.0, 6.0)
		hand_front = elbow_front + Vector2(face * 7.0, 4.8)
		elbow_back = shoulder + Vector2(-face * 11.0, 6.0)
		hand_back = elbow_back + Vector2(-face * 7.0, 4.8)
		ankle_front = Vector2(face * 17.0, ground_y)
		ankle_back = Vector2(-face * 17.0, ground_y)
		knee_front = hip_front + Vector2(face * 7.0, 11.0 * h)
		knee_back = hip_back + Vector2(-face * 7.0, 11.0 * h)

	_draw_bone_segment(shoulder, elbow_back, back_bone, 1.75)
	_draw_bone_segment(elbow_back, hand_back, back_bone, 1.65)
	_draw_bone_segment(hip_back, knee_back, back_bone, 1.85)
	_draw_bone_segment(knee_back, ankle_back, back_bone, 1.85)
	_draw_foot(ankle_back, face, back_bone, false)

	_draw_bone_segment(shoulder, elbow_front, bone, 1.95)
	_draw_bone_segment(elbow_front, hand_front, bone, 1.75)
	draw_circle(hand_front, 1.45, accent)
	_draw_bone_segment(hip_front, knee_front, bone, 2.05)
	_draw_bone_segment(knee_front, ankle_front, bone, 2.05)
	_draw_foot(ankle_front, face, bone, true)

	if is_blocker:
		draw_rect(Rect2(Vector2(-20, -30), Vector2(40, 55)), Color(0.95, 0.76, 0.23, 0.13), false, 2.0)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_bone_segment(a: Vector2, b: Vector2, color: Color, width: float) -> void:
	draw_line(a, b, color, width, true)
	draw_circle(a, width * 0.45, color)
	draw_circle(b, width * 0.45, color)

func _draw_clavicles(chest: Vector2, shoulder: Vector2, face: float, color: Color) -> void:
	_draw_bone_segment(chest + Vector2(0, -1.5), shoulder, color, 1.2)
	_draw_bone_segment(chest + Vector2(-face * 0.8, -1.0), chest + Vector2(-face * 4.6, 1.2), color.darkened(0.10), 1.05)

func _draw_pelvis(hip: Vector2, face: float, color: Color, h: float) -> void:
	var rear := hip + Vector2(-face * 4.8, 1.6 * h)
	var front := hip + Vector2(face * 5.4, 1.9 * h)
	var pubis := hip + Vector2(face * 0.5, 6.2 * h)
	_draw_bone_segment(rear, pubis, color.darkened(0.09), 1.35)
	_draw_bone_segment(front, pubis, color, 1.45)
	draw_circle(front, 1.45, color)
	draw_circle(rear, 1.35, color.darkened(0.12))

func _draw_side_skull(center: Vector2, face: float, bone: Color, shadow: Color) -> void:
	var skull := PackedVector2Array([
		center + Vector2(-face * 5.3, -5.7),
		center + Vector2(face * 3.4, -7.1),
		center + Vector2(face * 8.7, -3.0),
		center + Vector2(face * 9.3, 1.3),
		center + Vector2(face * 4.8, 5.3),
		center + Vector2(-face * 2.7, 4.8),
		center + Vector2(-face * 6.4, 0.5),
	])
	draw_colored_polygon(skull, bone)
	draw_rect(Rect2(center + Vector2(face * 0.8 - 2.0, 2.0), Vector2(6.5, 4.4)), bone)
	draw_circle(center + Vector2(face * 3.6, -1.8), 1.85, shadow)
	draw_line(center + Vector2(face * 6.8, 0.7), center + Vector2(face * 10.0, 1.6), shadow, 1.05)
	draw_line(center + Vector2(face * 1.4, 6.1), center + Vector2(face * 6.5, 6.2), shadow, 0.95)

func _draw_foot(ankle: Vector2, face: float, color: Color, is_front: bool) -> void:
	# Small angled foot bone: about 45 degrees from the lower leg, not a long flat shoe.
	var foot_len := 5.1 if is_front else 4.4
	var toe := ankle + Vector2(face * foot_len, foot_len * 0.55)
	draw_line(ankle, toe, color, 1.65 if is_front else 1.45, true)
	draw_line(toe, toe + Vector2(face * 1.8, 0.6), color, 0.9, true)
