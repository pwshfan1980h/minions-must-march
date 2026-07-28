extends Node2D

const LevelState := preload("res://scripts/core/level_state.gd")
const WORLD_WIDTH := 2400.0
const VIEWPORT_WIDTH := 1280.0
const CAMERA_PAN_SPEED := 520.0
const CAMERA_WHEEL_STEP := 220.0

@onready var level_controller: Node = $LevelController
@onready var game_ui: CanvasLayer = $GameUI
@onready var sfx: Node = $SfxPlayer
@onready var camera: Camera2D = $Camera2D
@onready var terrain: Node = $LevelController/TerrainRoot
@onready var object_root: Node = $LevelController/ObjectRoot

var _shake_time := 0.0
var _shake_strength := 0.0
var _shake_rng := RandomNumberGenerator.new()
var _reduced_motion := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_shake_rng.randomize()
	print("Minions Must March: GameRoot ready")
	camera.position.x = VIEWPORT_WIDTH / 2.0
	camera.limit_left = 0
	camera.limit_right = int(WORLD_WIDTH)
	camera.limit_top = 0
	camera.limit_bottom = 720
	level_controller.stats_changed.connect(game_ui.update_stats)
	level_controller.level_finished.connect(game_ui.show_level_finished)
	level_controller.sfx_requested.connect(_on_world_sfx_requested)
	level_controller.event_logged.connect(game_ui.add_event_log)
	game_ui.restart_requested.connect(level_controller.restart_level)
	game_ui.level_selected.connect(level_controller.select_level)
	game_ui.pause_toggled.connect(_toggle_pause_inspect)
	game_ui.speed_requested.connect(_set_march_speed)
	game_ui.job_selected.connect(_on_job_selected)
	game_ui.audio_settings_changed.connect(sfx.apply_mix_settings)
	game_ui.accessibility_settings_changed.connect(_apply_accessibility_settings)
	sfx.set_biome_profile(String(LevelState.config().get("biome", "crypt")))
	sfx.apply_mix_settings(game_ui.get_audio_settings())
	_apply_accessibility_settings(game_ui.get_accessibility_settings())
	game_ui.update_stats(level_controller.get_stats())
	_maybe_capture_screenshot()

func _process(delta: float) -> void:
	_update_camera_pan(delta)
	_update_camera_feedback(delta)

func _on_world_sfx_requested(sound_id: String, world_position: Vector2) -> void:
	sfx.play_at(sound_id, world_position)
	game_ui.show_sound_caption(sound_id, 0.0 if world_position == Vector2.INF else world_position.x - camera.position.x)
	match sound_id:
		"styx_impact":
			if terrain.has_method("add_styx_impact"):
				terrain.add_styx_impact(world_position, 1.15)
			_kick_camera(5.2, 0.32)
			game_ui.play_feedback("styx")
		"digger_crack":
			_kick_camera(2.8, 0.20)
			game_ui.play_feedback("digger")
		"builder_snap":
			_kick_camera(1.2, 0.12)
			game_ui.play_feedback("builder")
		"blocker_brace":
			_kick_camera(2.0, 0.15)
			game_ui.play_feedback("blocker")
		"feather_chime":
			game_ui.play_feedback("featherfall")
		"exit_rescue":
			game_ui.play_feedback("rescue")
		"level_fail":
			_kick_camera(4.0, 0.28)
			game_ui.play_feedback("failure")

func _kick_camera(strength: float, duration: float) -> void:
	if _reduced_motion:
		return
	_shake_strength = maxf(_shake_strength, strength)
	_shake_time = maxf(_shake_time, duration)

func _update_camera_feedback(delta: float) -> void:
	if _shake_time <= 0.0:
		camera.offset = Vector2.ZERO
		return
	_shake_time = maxf(0.0, _shake_time - delta)
	var fade := clampf(_shake_time / 0.32, 0.0, 1.0)
	camera.offset = Vector2(
		_shake_rng.randf_range(-1.0, 1.0),
		_shake_rng.randf_range(-0.7, 0.7)
	) * _shake_strength * fade
	_shake_strength = maxf(0.0, _shake_strength - delta * 8.0)

func _apply_accessibility_settings(settings: Dictionary) -> void:
	_reduced_motion = bool(settings.get("reduced_motion", false))
	if _reduced_motion:
		_shake_time = 0.0
		_shake_strength = 0.0
		camera.offset = Vector2.ZERO
	if terrain.has_method("set_accessibility_settings"):
		terrain.set_accessibility_settings(settings)
	if object_root.has_method("set_accessibility_settings"):
		object_root.set_accessibility_settings(settings)

func _on_job_selected(job_id: String) -> void:
	sfx.play("job_select")
	level_controller.set_selected_job(job_id)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F3 and level_controller.has_method("toggle_debug_click_areas"):
			var enabled: bool = level_controller.toggle_debug_click_areas()
			print("Click-area debug: %s" % ("ON" if enabled else "OFF"))
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_LEFT or event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_pan_camera(-CAMERA_WHEEL_STEP)
		elif event.button_index == MOUSE_BUTTON_WHEEL_RIGHT or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_pan_camera(CAMERA_WHEEL_STEP)

func _toggle_pause_inspect() -> void:
	get_tree().paused = not get_tree().paused
	game_ui.set_pause_inspect(get_tree().paused)

func _set_march_speed(multiplier: float) -> void:
	Engine.time_scale = clampf(multiplier, 1.0, 3.0)

func _exit_tree() -> void:
	Engine.time_scale = 1.0

func _pan_camera(amount: float) -> void:
	var min_x := VIEWPORT_WIDTH / 2.0
	var max_x := WORLD_WIDTH - VIEWPORT_WIDTH / 2.0
	camera.position.x = clampf(camera.position.x + amount, min_x, max_x)

func _update_camera_pan(delta: float) -> void:
	var pan := 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_Z):
		pan -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_X):
		pan += 1.0
	if pan == 0.0:
		return
	var min_x := VIEWPORT_WIDTH / 2.0
	var max_x := WORLD_WIDTH - VIEWPORT_WIDTH / 2.0
	camera.position.x = clampf(camera.position.x + pan * CAMERA_PAN_SPEED * delta, min_x, max_x)

func _maybe_capture_screenshot() -> void:
	var screenshot_path := OS.get_environment("MMM_SCREENSHOT_PATH")
	if screenshot_path.is_empty():
		return
	await get_tree().process_frame
	var delay := OS.get_environment("MMM_SCREENSHOT_DELAY").to_float()
	if delay <= 0.0:
		delay = 1.5
	await get_tree().create_timer(delay).timeout
	# Capture only after the renderer finishes a frame. Reading the viewport from
	# a process callback can otherwise produce partially updated UI bands on Metal.
	await RenderingServer.frame_post_draw
	var texture := get_viewport().get_texture()
	if texture == null:
		push_warning("Screenshot skipped: viewport texture unavailable")
		if OS.get_environment("MMM_EXIT_AFTER_SCREENSHOT") == "1":
			get_tree().quit()
		return
	var image := texture.get_image()
	if image == null:
		push_warning("Screenshot skipped: viewport image unavailable")
		if OS.get_environment("MMM_EXIT_AFTER_SCREENSHOT") == "1":
			get_tree().quit()
		return
	var err := image.save_png(screenshot_path)
	print("Screenshot saved: %s err=%s" % [screenshot_path, err])
	if OS.get_environment("MMM_EXIT_AFTER_SCREENSHOT") == "1":
		get_tree().quit()
