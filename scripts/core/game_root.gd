extends Node2D

const BeatConductorScene := preload("res://scripts/audio/beat_conductor.gd")
const WORLD_WIDTH := 2400.0
const VIEWPORT_WIDTH := 1280.0
const CAMERA_PAN_SPEED := 520.0

@onready var level_controller: Node = $LevelController
@onready var game_ui: CanvasLayer = $GameUI
@onready var sfx: Node = $SfxPlayer
@onready var camera: Camera2D = $Camera2D

var beat_conductor: BeatConductor

func _ready() -> void:
	print("Minions Must March: GameRoot ready")
	_setup_beat_conductor()
	if sfx.has_method("start_music"):
		sfx.start_music(LevelState.config().get("beat", {}))
	if sfx.has_method("play_march_step"):
		beat_conductor.step_crossed.connect(sfx.play_march_step)
	camera.position.x = VIEWPORT_WIDTH / 2.0
	camera.limit_left = 0
	camera.limit_right = int(WORLD_WIDTH)
	camera.limit_top = 0
	camera.limit_bottom = 720
	level_controller.stats_changed.connect(game_ui.update_stats)
	level_controller.level_finished.connect(game_ui.show_level_finished)
	level_controller.sfx_requested.connect(sfx.play)
	game_ui.restart_requested.connect(level_controller.restart_level)
	game_ui.job_selected.connect(_on_job_selected)
	game_ui.update_stats(level_controller.get_stats())
	_maybe_capture_screenshot()

func _setup_beat_conductor() -> void:
	beat_conductor = BeatConductorScene.new()
	beat_conductor.name = "BeatConductor"
	beat_conductor.add_to_group("beat_conductor")
	beat_conductor.configure(LevelState.config().get("beat", {}))
	add_child(beat_conductor)

func _process(delta: float) -> void:
	_update_camera_pan(delta)

func _on_job_selected(job_id: String) -> void:
	sfx.play("job_select")
	level_controller.set_selected_job(job_id)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			level_controller.restart_level()
		elif event.keycode == KEY_F3 and level_controller.has_method("toggle_debug_click_areas"):
			var enabled: bool = level_controller.toggle_debug_click_areas()
			print("Click-area debug: %s" % ("ON" if enabled else "OFF"))

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
