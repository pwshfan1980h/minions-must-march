extends CharacterBody2D

signal exited(minion: Node)
signal died(minion: Node)
signal death_started(minion: Node, death_kind: String)
signal clicked(minion: Node)

const BoneSplashScene := preload("res://scenes/effects/BoneSplash.tscn")

const WALK_SPEED := 34.0
const GRAVITY := 760.0
const MAX_FALL_SPEED := 520.0
const FATAL_FALL_SPEED := 470.0
const WALL_NORMAL_THRESHOLD := 0.65
const BLOCKER_TURN_DISTANCE := 22.0
const BLOCKER_VERTICAL_TOLERANCE := 18.0
const STYX_SURFACE_Y := 560.0
const VISUAL_SCALE := 0.72
const WALK_ANIM_FPS := 10.0
const BUILDER_SWING_FPS := 5.5
const BUILDER_PULSE_SECONDS := 0.46
const VAULT_CONTACT_MAX_HEIGHT := 30.0
const VAULT_FORWARD_DISTANCE := 16.0
const VAULT_MIN_CLEARANCE := 6.0
const VAULT_COOLDOWN_SECONDS := 0.12
const VAULT_ANIM_SECONDS := 0.34
const STYX_IMPACT_Y := STYX_SURFACE_Y - 2.0
const STANCE_FRACTION := 0.6
const FOOT_NEUTRAL_PITCH := 0.46
const VISUAL_REDRAW_FPS := 24.0
const OFFSCREEN_REDRAW_FPS := 8.0
const BLOCKER_CHECK_INTERVAL := 0.08

# Three body archetypes — each minion picks one at spawn. Within an archetype
# we add small jitter so duplicates don't look copy-pasted, but the silhouette
# and gait personality stay recognizable.
const BODY_TYPES := {
	"tall": {
		"height_base": 1.16, "height_jitter": 0.06,
		"body_width": 0.86,
		"head_scale": 0.94,
		"leg_length": 1.10,
		"stride_speed": 0.96,
		"bob_scale": 0.85,
		"spine_bias": -0.04,
	},
	"stocky": {
		"height_base": 0.86, "height_jitter": 0.05,
		"body_width": 1.22,
		"head_scale": 1.12,
		"leg_length": 0.84,
		"stride_speed": 0.80,
		"bob_scale": 1.32,
		"spine_bias": 0.10,
	},
	"wiry": {
		"height_base": 0.99, "height_jitter": 0.05,
		"body_width": 0.94,
		"head_scale": 0.96,
		"leg_length": 1.00,
		"stride_speed": 1.18,
		"bob_scale": 0.95,
		"spine_bias": 0.04,
	},
}

var direction := 1.0
var alive := true
var rescued := false
var is_blocker := false
var is_builder := false
var highest_fall_speed := 0.0
var death_kind := ""
var _walk_time := 0.0
var _body_type := "wiry"
var _height_variant := 1.0
var _spine_variant := 0.0
var _stride_variant := 1.0
var _body_width := 1.0
var _head_scale := 1.0
var _leg_length := 1.0
var _bob_scale := 1.0
var _last_anim_frame := -1
var _is_tumbling := false
var _visual_tumble_rotation := 0.0
var _tumble_speed := 0.0
var _air_time := 0.0
var _sink_wobble := 0.0
var _debug_click_area := false
var _builder_anim_time := 0.0
var _builder_pulse_time := 0.0
var _vault_cooldown := 0.0
var _vault_anim_time := 0.0
var _styx_death_started := false
var _visual_redraw_timer := 0.0
var _visual_redraw_requested := false
var _is_on_screen := true
var _blocker_check_timer := 0.0
var _blocker_ahead_cached := false
var _target_affordance_job := ""
var _target_affordance_visible := false
var _target_affordance_valid := false
var _target_hovered := false
var _invalid_target_flash := 0.0
var _featherfall_active := false
var _featherfall_glow := 0.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var click_area: Area2D = $ClickArea
@onready var click_shape: CollisionShape2D = $ClickArea/ClickShape
@onready var screen_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

func _ready() -> void:
	add_to_group("minions")
	input_pickable = false
	if click_area != null:
		click_area.input_event.connect(_on_click_area_input_event)
		click_area.mouse_entered.connect(func() -> void:
			_target_hovered = true
			_request_visual_redraw(true)
		)
		click_area.mouse_exited.connect(func() -> void:
			_target_hovered = false
			_request_visual_redraw(true)
		)
	if screen_notifier != null:
		_is_on_screen = screen_notifier.is_on_screen()
		screen_notifier.screen_entered.connect(_on_screen_entered)
		screen_notifier.screen_exited.connect(_on_screen_exited)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(get_instance_id())
	var type_keys := BODY_TYPES.keys()
	_body_type = String(type_keys[rng.randi() % type_keys.size()])
	var bt: Dictionary = BODY_TYPES[_body_type]
	_height_variant = float(bt["height_base"]) + rng.randf_range(-float(bt["height_jitter"]), float(bt["height_jitter"]))
	_body_width = float(bt["body_width"]) * rng.randf_range(0.96, 1.04)
	_head_scale = float(bt["head_scale"]) * rng.randf_range(0.97, 1.03)
	_leg_length = float(bt["leg_length"]) * rng.randf_range(0.97, 1.03)
	_bob_scale = float(bt["bob_scale"])
	# Keep the crowd loose: each skeleton starts on a different foot and drifts
	# at its own gait speed, so the line shuffles instead of marching in sync.
	_stride_variant = float(bt["stride_speed"]) * rng.randf_range(0.82, 1.18)
	_spine_variant = float(bt["spine_bias"]) + rng.randf_range(-0.05, 0.05)
	_walk_time = rng.randf_range(0.0, TAU)
	_request_visual_redraw(true)

func _process(delta: float) -> void:
	_visual_redraw_timer += delta
	# Tweened custom draw properties need redraws while the sinking corpse animates.
	if not alive and not rescued:
		_request_visual_redraw()
	if is_builder:
		_builder_anim_time += delta
		_builder_pulse_time = maxf(0.0, _builder_pulse_time - delta)
		_request_visual_redraw()
	if _vault_anim_time > 0.0:
		_vault_anim_time = maxf(0.0, _vault_anim_time - delta)
		_request_visual_redraw()
	if _invalid_target_flash > 0.0:
		_invalid_target_flash = maxf(0.0, _invalid_target_flash - delta)
		_request_visual_redraw()
	if _featherfall_glow > 0.0:
		_featherfall_glow = maxf(0.0, _featherfall_glow - delta)
		_request_visual_redraw()
	_flush_visual_redraw_if_due()

func _physics_process(delta: float) -> void:
	if not alive or rescued:
		return

	if _vault_cooldown > 0.0:
		_vault_cooldown = maxf(0.0, _vault_cooldown - delta)

	var was_on_floor := is_on_floor()
	velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)
	velocity.x = 0.0 if is_blocker or is_builder else WALK_SPEED * direction
	if is_on_floor() and not is_blocker and not is_builder:
		_walk_time += delta * 8.8 * _stride_variant
		var anim_frame := int(_walk_time * WALK_ANIM_FPS)
		if anim_frame != _last_anim_frame:
			_last_anim_frame = anim_frame
			_request_visual_redraw()
	if not is_blocker and not is_builder:
		highest_fall_speed = maxf(highest_fall_speed, velocity.y)
		if _is_tumbling:
			_air_time += delta
			var wobble := sin(_air_time * 8.5 + float(get_instance_id()) * 0.01) * 0.10
			_visual_tumble_rotation += (_tumble_speed + wobble) * delta
			_tumble_speed = clampf(_tumble_speed + signf(_tumble_speed) * 0.11 * delta, -4.8, 4.8)
			_request_visual_redraw()

	move_and_slide()

	if global_position.y >= STYX_IMPACT_Y and velocity.y > 0.0:
		die_to("styx_water")
		return

	var on_floor := is_on_floor()
	if not is_blocker and not is_builder and was_on_floor and not on_floor and velocity.y > 0.0:
		_start_tumble()

	if on_floor:
		if highest_fall_speed >= FATAL_FALL_SPEED:
			if _consume_featherfall_landing():
				highest_fall_speed = 0.0
				_stop_tumble()
			else:
				_die()
		else:
			highest_fall_speed = 0.0
			_stop_tumble()

		if not is_blocker and not is_builder:
			if _has_blocker_ahead(delta):
				_turn_around()
			elif _is_blocked_ahead() and not _try_vault_ahead():
				# A just-vaulted skeleton may still be settling onto the next step or
				# platform lip. Do not instantly reverse during that grace window.
				if _vault_cooldown <= 0.0:
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
	_disable_click_target()
	_disable_click_target()
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

func can_become_builder() -> bool:
	return alive and not rescued and not is_blocker and not is_builder and is_on_floor()

func can_become_digger() -> bool:
	return alive and not rescued and not is_blocker and not is_builder and is_on_floor()

func can_receive_featherfall() -> bool:
	return alive and not rescued and not _featherfall_active

func activate_featherfall() -> bool:
	if not can_receive_featherfall():
		return false
	_featherfall_active = true
	_featherfall_glow = 0.85
	_request_visual_redraw(true)
	return true

func _consume_featherfall_landing() -> bool:
	if not _featherfall_active:
		return false
	_featherfall_active = false
	_featherfall_glow = 0.75
	velocity.y = -42.0
	_request_visual_redraw(true)
	return true

func set_target_affordance(job_id: String, valid: bool) -> void:
	_target_affordance_job = job_id
	_target_affordance_valid = valid
	_target_affordance_visible = not job_id.is_empty() and alive and not rescued
	_request_visual_redraw(true)

func flash_invalid_target() -> void:
	# InvalidTargetFlash: a small red pulse says "not this skeleton" without stealing input.
	_invalid_target_flash = 0.35
	_request_visual_redraw(true)

func play_digger_dust() -> void:
	# Digger v0 is an instant cracked-floor command; a forced redraw gives the
	# player immediate feedback while the removed plug/debris does the heavy read.
	_request_visual_redraw(true)

func set_builder_active(active: bool) -> void:
	if not alive or rescued or is_blocker:
		return
	is_builder = active
	if active:
		_builder_anim_time = 0.0
		_builder_pulse_time = 0.0
	velocity = Vector2.ZERO
	_stop_tumble()
	_request_visual_redraw(true)

func play_builder_build_pulse(duration := BUILDER_PULSE_SECONDS) -> void:
	_builder_pulse_time = duration
	_request_visual_redraw(true)

func death_voice_id() -> String:
	match _body_type:
		"tall":
			return "death_yelp_tall"
		"stocky":
			return "death_yelp_stocky"
		_:
			return "death_yelp_wiry"

func become_blocker() -> bool:
	if not alive or rescued or is_blocker or not is_on_floor():
		return false
	is_blocker = true
	_stop_tumble()
	velocity = Vector2.ZERO
	add_to_group("blockers")
	_request_visual_redraw(true)
	return true

func resume_march() -> bool:
	if not alive or rescued or not is_blocker:
		return false
	is_blocker = false
	remove_from_group("blockers")
	_request_visual_redraw(true)
	return true

func die_to(kind: String) -> void:
	if not alive or rescued or _styx_death_started:
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
	# Normalize all river deaths to one surface impact. Whether the Area2D or the
	# proactive physics check catches the fall first, the skeleton hits the soup
	# line once, then sinks out of view like a soggy cracker.
	_styx_death_started = true
	global_position.y = STYX_SURFACE_Y - 2.0
	alive = false
	death_started.emit(self, death_kind)
	velocity = Vector2.ZERO
	set_physics_process(false)
	set_process_input(false)
	_disable_click_target()
	if collision_shape != null:
		collision_shape.disabled = true
	if is_blocker:
		remove_from_group("blockers")
	_spawn_bone_splash(Vector2(global_position.x, STYX_SURFACE_Y))
	var impact_rotation := _visual_tumble_rotation + signf(_tumble_speed if _tumble_speed != 0.0 else direction) * 0.38
	var impact := create_tween()
	impact.set_parallel(true)
	impact.tween_property(self, "position:y", position.y + 8.0, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	impact.tween_property(self, "scale", Vector2(1.16, 0.78), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	impact.tween_property(self, "_visual_tumble_rotation", impact_rotation, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	impact.tween_callback(queue_redraw).set_delay(0.14)
	await impact.finished

	var sink := create_tween()
	sink.set_parallel(true)
	sink.tween_property(self, "modulate:a", 0.0, 1.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	sink.tween_property(self, "position:y", position.y + 86.0, 1.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	sink.tween_property(self, "position:x", position.x + direction * 6.0, 0.44).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	sink.tween_property(self, "scale", Vector2(0.58, 0.34), 1.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	sink.tween_property(self, "_sink_wobble", signf(direction) * 0.10, 0.44).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	sink.tween_property(self, "_sink_wobble", signf(direction) * -0.07, 0.44).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).set_delay(0.44)
	sink.tween_property(self, "_visual_tumble_rotation", impact_rotation + signf(impact_rotation if impact_rotation != 0.0 else direction) * 0.22, 0.88).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	sink.tween_callback(queue_redraw).set_delay(0.88)
	await sink.finished
	died.emit(self)
	queue_free()

func _start_tumble() -> void:
	if _is_tumbling or is_blocker:
		return
	_is_tumbling = true
	var variant := fposmod(float(get_instance_id()), 13.0) / 13.0
	_air_time = 0.0
	_tumble_speed = direction * lerpf(2.05, 3.15, variant)
	_visual_tumble_rotation = direction * lerpf(0.06, 0.14, variant)
	_request_visual_redraw(true)

func _stop_tumble() -> void:
	if not _is_tumbling and absf(_visual_tumble_rotation) < 0.001:
		return
	_is_tumbling = false
	_tumble_speed = 0.0
	_air_time = 0.0
	_visual_tumble_rotation = 0.0
	_sink_wobble = 0.0
	_request_visual_redraw(true)

func _spawn_bone_splash(spawn_position := Vector2.INF) -> void:
	var splash := BoneSplashScene.instantiate()
	splash.global_position = global_position if spawn_position == Vector2.INF else spawn_position
	get_parent().add_child(splash)

func _turn_around() -> void:
	direction *= -1.0
	_request_visual_redraw(true)

func _is_blocked_ahead() -> bool:
	return _get_wall_collision_ahead() != null

func _get_wall_collision_ahead() -> KinematicCollision2D:
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		if absf(collision.get_normal().x) > WALL_NORMAL_THRESHOLD:
			return collision
	return null

func _try_vault_ahead() -> bool:
	if _vault_cooldown > 0.0 or not is_on_floor():
		return false
	var collision := _get_wall_collision_ahead()
	if collision == null:
		return false
	var contact_height := global_position.y - collision.get_position().y
	if contact_height < -VAULT_MIN_CLEARANCE or contact_height > VAULT_CONTACT_MAX_HEIGHT:
		return false
	var facing := signf(direction)
	if facing == 0.0:
		facing = 1.0
	for lift in [6.0, 8.0, 12.0, 16.0, 20.0, 24.0, 28.0, 32.0]:
		var up := Vector2(0.0, -lift)
		var forward := Vector2(facing * VAULT_FORWARD_DISTANCE, 0.0)
		if test_move(global_transform, up):
			continue
		if test_move(global_transform.translated(up), forward):
			continue
		global_position += up + forward
		velocity.y = -28.0
		_vault_cooldown = VAULT_COOLDOWN_SECONDS
		_vault_anim_time = VAULT_ANIM_SECONDS
		_stop_tumble()
		_request_visual_redraw(true)
		return true
	return false

func _has_blocker_ahead(delta: float) -> bool:
	_blocker_check_timer -= delta
	if _blocker_check_timer > 0.0:
		return _blocker_ahead_cached
	_blocker_check_timer = BLOCKER_CHECK_INTERVAL
	_blocker_ahead_cached = false
	for blocker in get_tree().get_nodes_in_group("blockers"):
		if blocker == self or not is_instance_valid(blocker):
			continue
		var blocker_offset: Vector2 = blocker.global_position - global_position
		if absf(blocker_offset.y) <= BLOCKER_VERTICAL_TOLERANCE and signf(blocker_offset.x) == signf(direction):
			if absf(blocker_offset.x) <= BLOCKER_TURN_DISTANCE:
				_blocker_ahead_cached = true
				return true
	return _blocker_ahead_cached

func set_debug_click_area(enabled: bool) -> void:
	_debug_click_area = enabled
	_request_visual_redraw(true)

func _request_visual_redraw(force := false) -> void:
	if force:
		_visual_redraw_requested = false
		_visual_redraw_timer = 0.0
		queue_redraw()
		return
	_visual_redraw_requested = true

func _flush_visual_redraw_if_due() -> void:
	if not _visual_redraw_requested:
		return
	var fps := VISUAL_REDRAW_FPS if _is_on_screen else OFFSCREEN_REDRAW_FPS
	if _visual_redraw_timer < 1.0 / fps:
		return
	_visual_redraw_requested = false
	_visual_redraw_timer = 0.0
	queue_redraw()

func _on_screen_entered() -> void:
	_is_on_screen = true
	_request_visual_redraw(true)

func _on_screen_exited() -> void:
	_is_on_screen = false

func _disable_click_target() -> void:
	if click_area != null:
		click_area.set_deferred("input_pickable", false)
	if click_shape != null:
		click_shape.set_deferred("disabled", true)

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	_handle_click_event(event)

func _on_click_area_input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	_handle_click_event(event)

func _handle_click_event(event: InputEvent) -> void:
	if alive and not rescued and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(self)

func _draw() -> void:
	# Draw at a smaller in-world scale. This keeps the same level camera/field,
	# but makes the crowd feel more numerous and less toy-large.
	if _target_affordance_visible or _invalid_target_flash > 0.0:
		_draw_target_affordance()
	draw_set_transform(Vector2.ZERO, _visual_tumble_rotation + _sink_wobble, Vector2(VISUAL_SCALE, VISUAL_SCALE))

	var bone := Color("f1d27a") if is_builder else Color("f1e7c8") if is_blocker else Color("e8e0c8") if alive else Color("8c7f91")
	var shadow := Color("211b2b")
	var accent := Color("b9a77b")
	var back_bone := bone.darkened(0.16)
	var face := signf(direction)
	if face == 0.0:
		face = 1.0

	var airborne_motion := _is_tumbling or (not alive and not rescued)
	var fall_phase := _air_time * 9.5 + float(get_instance_id()) * 0.01
	var vault_progress := 1.0 - clampf(_vault_anim_time / VAULT_ANIM_SECONDS, 0.0, 1.0)
	var stride := sin(fall_phase) * 0.55 if airborne_motion else 0.0 if is_blocker or is_builder else sin(_walk_time)
	if _vault_anim_time > 0.0 and not is_blocker and not is_builder:
		stride = sin(vault_progress * PI * 1.35) * 0.88
	var leg_front_phase := stride
	var leg_back_phase := -stride
	var front_lift := maxf(0.0, leg_front_phase)
	var back_lift := maxf(0.0, leg_back_phase)
	var vault_bob := -sin(vault_progress * PI) * 5.2 if _vault_anim_time > 0.0 else 0.0
	var bob := 0.0 if is_blocker or is_builder else absf(stride) * (0.55 if airborne_motion else 1.05) * _bob_scale
	bob += vault_bob
	var lean := face * (2.8 + _spine_variant * 7.0 + (0.45 * absf(stride) if not is_blocker else -1.0))
	if airborne_motion:
		lean += sin(fall_phase * 0.74) * 5.0
	var h := _height_variant
	var w := _body_width

	var hip := Vector2(-face * 0.8, 3.0 - bob)
	var chest := Vector2(lean * 0.45, -12.5 * h - bob)
	var neck := Vector2(lean * 0.78, -19.2 * h - bob)
	var head := neck + Vector2(face * 4.0, -5.9 * h)
	var shoulder := chest + Vector2(face * 1.4 * w, -0.8)

	# Core silhouette first: spine, compact ribs, pelvis. Fewer draw calls than the
	# earlier anatomy pass, but enough bone landmarks to read at small scale.
	_draw_bone_segment(hip, chest, bone, 2.6)
	for i in 3:
		var t := float(i) / 2.0
		var rib_center := chest.lerp(hip + Vector2(face * 0.5, -4.5), t)
		var rib_width := lerpf(6.6, 4.2, t) * h * w
		draw_arc(rib_center, rib_width, -0.72 * PI if face > 0.0 else -0.28 * PI, 0.18 * PI if face > 0.0 else 1.22 * PI, 6, bone, 1.35)
	_draw_pelvis(hip, face, bone.darkened(0.04), h, w)
	_draw_clavicles(chest, shoulder, face, bone.darkened(0.02))
	_draw_side_skull(head, face, bone, shadow, _head_scale)

	# Arms: counter-swing, but subordinate to legs for readability.
	var arm_swing := -stride
	var elbow_front := shoulder + Vector2(face * (6.0 + arm_swing * 2.4), 7.2 + stride * 1.2)
	var hand_front := elbow_front + Vector2(face * (4.8 + arm_swing * 1.5), 7.2 - stride * 0.9)
	var elbow_back := shoulder + Vector2(-face * (4.8 + arm_swing * 1.6), 6.8 - stride * 1.0)
	var hand_back := elbow_back + Vector2(-face * (4.4 + arm_swing * 1.6), 7.0 + stride * 0.7)
	if airborne_motion:
		elbow_front += Vector2(face * sin(fall_phase) * 3.8, -5.5 + cos(fall_phase * 0.7) * 2.5)
		hand_front += Vector2(face * sin(fall_phase + 0.7) * 5.2, -7.5 + cos(fall_phase) * 3.4)
		elbow_back += Vector2(-face * cos(fall_phase * 0.8) * 3.2, -4.0 + sin(fall_phase * 0.9) * 2.2)
		hand_back += Vector2(-face * cos(fall_phase + 0.4) * 4.8, -6.8 + sin(fall_phase * 0.8) * 3.0)

	# Legs: explicit two-phase side-view gait. Near/far legs move in opposite
	# horizontal phases: one plants behind while the other passes forward.
	var ground_y := 24.6 * h * _leg_length
	var hip_front := hip + Vector2(face * 2.4 * w, 2.4 * h)
	var hip_back := hip + Vector2(-face * 2.8 * w, 2.6 * h)
	var ankle_front: Vector2
	var ankle_back: Vector2
	var knee_front: Vector2
	var knee_back: Vector2
	var foot_angle_front := 0.0
	var foot_angle_back := 0.0
	var use_walk_gait := not airborne_motion and not is_blocker and not is_builder and _vault_anim_time <= 0.0
	if use_walk_gait:
		var phase_front := fposmod(_walk_time / TAU, 1.0)
		var phase_back := fposmod(phase_front + 0.5, 1.0)
		var cycle_speed := 8.8 * _stride_variant
		var stance_slide := WALK_SPEED * STANCE_FRACTION * TAU / cycle_speed
		var pose_front := _walk_leg_pose(phase_front, hip_front, face, h, stance_slide)
		var pose_back := _walk_leg_pose(phase_back, hip_back, face, h, stance_slide)
		ankle_front = pose_front["ankle"]
		knee_front = pose_front["knee"]
		foot_angle_front = pose_front["foot_angle"]
		ankle_back = pose_back["ankle"]
		knee_back = pose_back["knee"]
		foot_angle_back = pose_back["foot_angle"]
	else:
		ankle_front = Vector2(face * (8.4 + leg_front_phase * 5.6), ground_y - front_lift * 2.9)
		ankle_back = Vector2(face * (-8.2 + leg_back_phase * 5.3), ground_y - back_lift * 2.7)
		knee_front = Vector2(face * (4.6 + leg_front_phase * 3.7), lerpf(hip_front.y + 7.2 * h, ankle_front.y - 6.6 * h, 0.58) - front_lift * 2.0)
		knee_back = Vector2(face * (-4.8 + leg_back_phase * 3.5), lerpf(hip_back.y + 7.4 * h, ankle_back.y - 6.4 * h, 0.58) - back_lift * 1.9)
	if airborne_motion:
		ankle_front += Vector2(face * sin(fall_phase * 0.7) * 4.2, -4.2 + cos(fall_phase) * 4.0)
		ankle_back += Vector2(-face * cos(fall_phase * 0.8) * 4.0, -3.6 + sin(fall_phase * 0.9) * 3.4)
		knee_front += Vector2(face * sin(fall_phase + 0.6) * 3.0, -2.5)
		knee_back += Vector2(-face * cos(fall_phase + 0.2) * 2.8, -2.2)
		foot_angle_front = sin(fall_phase + 0.3) * 0.4
		foot_angle_back = sin(fall_phase + 1.7) * 0.4

	if is_blocker or is_builder:
		elbow_front = shoulder + Vector2(face * 13.0, 6.0)
		hand_front = elbow_front + Vector2(face * 7.0, 4.8)
		elbow_back = shoulder + Vector2(-face * 11.0, 6.0)
		hand_back = elbow_back + Vector2(-face * 7.0, 4.8)
		ankle_front = Vector2(face * 17.0, ground_y)
		ankle_back = Vector2(-face * 17.0, ground_y)
		knee_front = hip_front + Vector2(face * 7.0, 11.0 * h)
		knee_back = hip_back + Vector2(-face * 7.0, 11.0 * h)
		if is_builder:
			var build_phase := sin(_builder_anim_time * TAU * BUILDER_SWING_FPS)
			var throw_snap := clampf(_builder_pulse_time / BUILDER_PULSE_SECONDS, 0.0, 1.0)
			var windup := sin(throw_snap * PI)
			var release := pow(throw_snap, 2.2)
			elbow_front = shoulder + Vector2(face * (8.0 + build_phase * 2.2 + release * 11.0), 7.0 - windup * 5.5)
			hand_front = elbow_front + Vector2(face * (6.0 + release * 9.0), 6.2 - windup * 8.0)
			elbow_back = shoulder + Vector2(-face * (8.0 + build_phase * 2.4 + windup * 3.0), 6.0 + windup * 2.0)
			hand_back = elbow_back + Vector2(-face * (6.0 + windup * 3.5), 6.5 + windup * 2.0)

	_draw_bone_segment(shoulder, elbow_back, back_bone, 1.75)
	_draw_bone_segment(elbow_back, hand_back, back_bone, 1.65)
	_draw_bone_segment(hip_back, knee_back, back_bone, 1.85)
	_draw_bone_segment(knee_back, ankle_back, back_bone, 1.85)
	_draw_foot(ankle_back, face, back_bone, foot_angle_back, false)

	_draw_bone_segment(shoulder, elbow_front, bone, 1.95)
	_draw_bone_segment(elbow_front, hand_front, bone, 1.75)
	draw_circle(hand_front, 1.45, accent)
	if is_builder:
		var glow := clampf(_builder_pulse_time / BUILDER_PULSE_SECONDS, 0.0, 1.0)
		var held_tip := hand_front + Vector2(face * 8.0, -1.5)
		draw_line(hand_front - Vector2(face * 5.0, -1.0), held_tip, Color(1.0, 0.86, 0.54, 0.95), 2.3, true)
		if glow > 0.0:
			draw_circle(held_tip, 2.0 + glow * 4.0, Color(1.0, 0.74, 0.24, 0.24 * glow))
			draw_line(held_tip + Vector2(face * 1.0, -4.0), held_tip + Vector2(face * 5.0, -8.0), Color(1.0, 0.86, 0.45, 0.65 * glow), 1.1)
	_draw_bone_segment(hip_front, knee_front, bone, 2.05)
	_draw_bone_segment(knee_front, ankle_front, bone, 2.05)
	_draw_foot(ankle_front, face, bone, foot_angle_front, true)

	if is_blocker or is_builder:
		var outline_color := Color(0.95, 0.76, 0.23, 0.18) if is_builder else Color(0.95, 0.76, 0.23, 0.13)
		draw_rect(Rect2(Vector2(-20, -30), Vector2(40, 55)), outline_color, false, 2.0)

	if _featherfall_active or _featherfall_glow > 0.0:
		_draw_featherfall_charm(head, face)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if _debug_click_area:
		_draw_click_debug()

func _draw_featherfall_charm(anchor: Vector2, face: float) -> void:
	# FeatherfallCharm: a blue-white bone feather pinned above the skull while
	# active; a brief pulse remains when it saves a fatal landing.
	var pulse := 0.45 + 0.55 * clampf(_featherfall_glow / 0.85, 0.0, 1.0)
	var color := Color(0.66, 0.90, 1.0, 0.72 if _featherfall_active else 0.48 * pulse)
	var base := anchor + Vector2(-face * 8.0, -9.0)
	var tip := base + Vector2(face * 13.0, -10.0)
	draw_line(base, tip, color, 1.9, true)
	for i in 4:
		var t := float(i + 1) / 5.0
		var p := base.lerp(tip, t)
		draw_line(p, p + Vector2(-face * (4.5 - t * 2.0), 4.0 + t * 2.0), Color(color.r, color.g, color.b, color.a * 0.78), 0.95, true)
	draw_circle(tip, 2.2 + 3.2 * pulse, Color(color.r, color.g, color.b, 0.12 * pulse))

func _draw_click_debug() -> void:
	# Mirrors the ClickArea/ClickShape capsule so tuning click fairness is visible in-game.
	var center := Vector2(0, -8)
	var radius := 13.0
	var half_segment := (48.0 - radius * 2.0) * 0.5
	var top := center + Vector2(0, -half_segment)
	var bottom := center + Vector2(0, half_segment)
	var color := Color(0.25, 0.95, 1.0, 0.72)
	var fill := Color(0.25, 0.95, 1.0, 0.10)
	draw_rect(Rect2(center.x - radius, top.y, radius * 2.0, half_segment * 2.0), fill)
	draw_circle(top, radius, fill)
	draw_circle(bottom, radius, fill)
	draw_line(Vector2(center.x - radius, top.y), Vector2(center.x - radius, bottom.y), color, 1.5)
	draw_line(Vector2(center.x + radius, top.y), Vector2(center.x + radius, bottom.y), color, 1.5)
	draw_arc(top, radius, PI, TAU, 16, color, 1.5)
	draw_arc(bottom, radius, 0.0, PI, 16, color, 1.5)

func _draw_target_affordance() -> void:
	var valid_color := Color(1.0, 0.78, 0.22, 0.56 if _target_hovered else 0.34)
	var invalid_color := Color(1.0, 0.18, 0.12, 0.52 if _target_hovered else 0.28)
	var pulse_color := Color(1.0, 0.08, 0.06, 0.70 * clampf(_invalid_target_flash / 0.35, 0.0, 1.0))
	var color := valid_color if _target_affordance_valid else invalid_color
	if _invalid_target_flash > 0.0:
		color = pulse_color
	var width := 2.6 if _target_hovered else 1.5
	draw_arc(Vector2(0, -9), 20.0, 0.0, TAU, 28, color, width)
	draw_line(Vector2(-12, -36), Vector2(12, -36), color, width, true)
	if _target_affordance_job == "builder" and _target_affordance_valid:
		_draw_builder_preview_ghost(color)
	elif _target_affordance_job == "featherfall" and _target_affordance_valid:
		var feather := Color(0.72, 0.92, 1.0, 0.28 if not _target_hovered else 0.48)
		draw_line(Vector2(-16, -42), Vector2(16, -30), feather, 2.0, true)
		draw_line(Vector2(-10, -39), Vector2(-2, -30), feather, 1.1, true)
		draw_line(Vector2(2, -36), Vector2(10, -28), feather, 1.1, true)

func _draw_builder_preview_ghost(color: Color) -> void:
	# BuilderPreviewGhost: tiny rib bridge forecast beside the selected skeleton.
	var face := signf(direction)
	if face == 0.0:
		face = 1.0
	var ghost := Color(color.r, color.g, color.b, 0.24 if not _target_hovered else 0.42)
	for i in 6:
		var a := Vector2(face * (20.0 + float(i) * 16.0), 12.0 - float(i) * 5.0)
		var b := a + Vector2(face * 18.0, -5.0)
		draw_line(a, b, ghost, 2.0, true)
		draw_circle(a, 2.1, ghost)
		draw_circle(b, 2.1, ghost)

func _draw_bone_segment(a: Vector2, b: Vector2, color: Color, width: float) -> void:
	draw_line(a, b, color, width, true)
	draw_circle(a, width * 0.45, color)
	draw_circle(b, width * 0.45, color)

func _draw_clavicles(chest: Vector2, shoulder: Vector2, face: float, color: Color) -> void:
	_draw_bone_segment(chest + Vector2(0, -1.5), shoulder, color, 1.2)
	_draw_bone_segment(chest + Vector2(-face * 0.8, -1.0), chest + Vector2(-face * 4.6, 1.2), color.darkened(0.10), 1.05)

func _draw_pelvis(hip: Vector2, face: float, color: Color, h: float, w: float = 1.0) -> void:
	var rear := hip + Vector2(-face * 4.8 * w, 1.6 * h)
	var front := hip + Vector2(face * 5.4 * w, 1.9 * h)
	var pubis := hip + Vector2(face * 0.5, 6.2 * h)
	_draw_bone_segment(rear, pubis, color.darkened(0.09), 1.35)
	_draw_bone_segment(front, pubis, color, 1.45)
	draw_circle(front, 1.45, color)
	draw_circle(rear, 1.35, color.darkened(0.12))

func _draw_side_skull(center: Vector2, face: float, bone: Color, shadow: Color, scale_factor: float = 1.0) -> void:
	var s := scale_factor
	var skull := PackedVector2Array([
		center + Vector2(-face * 5.3, -5.7) * s,
		center + Vector2(face * 3.4, -7.1) * s,
		center + Vector2(face * 8.7, -3.0) * s,
		center + Vector2(face * 9.3, 1.3) * s,
		center + Vector2(face * 4.8, 5.3) * s,
		center + Vector2(-face * 2.7, 4.8) * s,
		center + Vector2(-face * 6.4, 0.5) * s,
	])
	draw_colored_polygon(skull, bone)
	draw_rect(Rect2(center + Vector2(face * 0.8 - 2.0, 2.0) * s, Vector2(6.5, 4.4) * s), bone)
	draw_circle(center + Vector2(face * 3.6, -1.8) * s, 1.85 * s, shadow)
	draw_line(center + Vector2(face * 6.8, 0.7) * s, center + Vector2(face * 10.0, 1.6) * s, shadow, 1.05 * s)
	draw_line(center + Vector2(face * 1.4, 6.1) * s, center + Vector2(face * 6.5, 6.2) * s, shadow, 0.95 * s)

func _draw_foot(ankle: Vector2, face: float, color: Color, foot_angle: float, is_front: bool) -> void:
	# Articulated foot wedge. foot_angle in radians: positive rotates the toe upward
	# (dorsiflexion), negative rotates the toe downward (plantarflexion / toe-off push).
	var foot_len := 5.6 if is_front else 4.8
	var thickness := 1.6 if is_front else 1.35
	var pitch := FOOT_NEUTRAL_PITCH - foot_angle
	var forward := Vector2(face * cos(pitch), sin(pitch))
	var up := Vector2(forward.y * face, -forward.x * face)
	var heel_back := ankle - forward * 0.8 + up * 0.2
	var heel_sole := ankle - forward * 0.5 - up * (thickness * 0.85)
	var toe_sole := ankle + forward * (foot_len * 0.92) - up * (thickness * 0.45)
	var toe_tip := ankle + forward * foot_len - up * 0.1
	var top_arch := ankle + forward * (foot_len * 0.42) + up * (thickness * 0.7)
	var poly := PackedVector2Array([heel_back, top_arch, toe_tip, toe_sole, heel_sole])
	draw_colored_polygon(poly, color)
	draw_line(heel_back, top_arch, color.darkened(0.18), 0.6, true)
	draw_line(top_arch, toe_tip, color.darkened(0.18), 0.6, true)

func _walk_leg_pose(phase: float, hip: Vector2, face: float, h: float, stance_slide: float) -> Dictionary:
	# Stance/swing leg pose. phase in [0,1) within one gait cycle: stance occupies
	# [0, STANCE_FRACTION), swing the rest. During stance the planted foot slides
	# backward at body speed so it appears glued to the ground while the body passes
	# over it. During swing the foot lifts and arcs forward, knee bends sharply.
	var ground_y := 24.6 * h
	var heel_strike_x := face * stance_slide * 0.5
	var toe_off_x := -face * stance_slide * 0.5
	var ankle: Vector2
	var swing_progress := 0.0
	var foot_angle := 0.0
	if phase < STANCE_FRACTION:
		var t := phase / STANCE_FRACTION
		ankle = Vector2(lerpf(heel_strike_x, toe_off_x, t), ground_y)
		if t < 0.18:
			foot_angle = lerpf(0.18, 0.0, t / 0.18)
		elif t > 0.7:
			foot_angle = lerpf(0.0, -0.55, (t - 0.7) / 0.3)
	else:
		var t := (phase - STANCE_FRACTION) / (1.0 - STANCE_FRACTION)
		swing_progress = sin(t * PI)
		var ease := smoothstep(0.0, 1.0, t)
		ankle = Vector2(lerpf(toe_off_x, heel_strike_x, ease), ground_y - swing_progress * 4.6)
		if t < 0.35:
			foot_angle = lerpf(-0.55, 0.55, t / 0.35)
		else:
			foot_angle = lerpf(0.55, 0.18, (t - 0.35) / 0.65)
	var midpoint := (hip + ankle) * 0.5
	var bend := 1.5 + swing_progress * 3.6
	var knee := midpoint + Vector2(face * bend, -0.6 - swing_progress * 1.5)
	return {"ankle": ankle, "knee": knee, "foot_angle": foot_angle}
