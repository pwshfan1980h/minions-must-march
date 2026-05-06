extends Node2D

@onready var level_controller: Node = $LevelController
@onready var game_ui: CanvasLayer = $GameUI
@onready var sfx: Node = $SfxPlayer

func _ready() -> void:
	print("Minions Must March: GameRoot ready")
	level_controller.stats_changed.connect(game_ui.update_stats)
	level_controller.level_finished.connect(game_ui.show_level_finished)
	level_controller.sfx_requested.connect(sfx.play)
	game_ui.restart_requested.connect(level_controller.restart_level)
	game_ui.job_selected.connect(_on_job_selected)
	game_ui.update_stats(level_controller.get_stats())
	_maybe_capture_screenshot()

func _on_job_selected(job_id: String) -> void:
	sfx.play("job_select")
	level_controller.set_selected_job(job_id)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		level_controller.restart_level()

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
