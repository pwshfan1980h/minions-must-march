extends Node2D

const WORLD_WIDTH := 2400.0
const VIEWPORT_WIDTH := 1280.0
const CAMERA_PAN_SPEED := 520.0
const CAMERA_WHEEL_STEP := 220.0

@onready var level_controller: Node = $LevelController
@onready var game_ui: CanvasLayer = $GameUI
@onready var sfx: Node = $SfxPlayer
@onready var camera: Camera2D = $Camera2D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("Minions Must March: GameRoot ready")
	camera.position.x = VIEWPORT_WIDTH / 2.0
	camera.limit_left = 0
	camera.limit_right = int(WORLD_WIDTH)
	camera.limit_top = 0
	camera.limit_bottom = 720
	level_controller.stats_changed.connect(game_ui.update_stats)
	level_controller.level_finished.connect(game_ui.show_level_finished)
	level_controller.sfx_requested.connect(sfx.play_at)
	level_controller.event_logged.connect(game_ui.add_event_log)
	game_ui.restart_requested.connect(level_controller.restart_level)
	game_ui.level_selected.connect(level_controller.select_level)
	game_ui.pause_toggled.connect(_toggle_pause_inspect)
	game_ui.speed_requested.connect(_set_march_speed)
	game_ui.job_selected.connect(_on_job_selected)
	game_ui.update_stats(level_controller.get_stats())
	_maybe_capture_screenshot()

func _process(delta: float) -> void:
	_update_camera_pan(delta)

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
