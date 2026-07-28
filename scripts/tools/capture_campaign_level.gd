extends SceneTree

const LevelState := preload("res://scripts/core/level_state.gd")
const GAME_ROOT_SCENE := preload("res://scenes/GameRoot.tscn")

func _initialize() -> void:
	var requested := OS.get_environment("MMM_LEVEL").to_int()
	LevelState.goto(requested if requested > 0 else 1)
	var game_root := GAME_ROOT_SCENE.instantiate()
	root.add_child(game_root)
	if OS.get_environment("MMM_CAPTURE_PLAYFIELD") == "1":
		call_deferred("_prepare_playfield_capture", game_root)

func _prepare_playfield_capture(game_root: Node) -> void:
	await process_frame
	game_root.get_node("GameUI/TutorialPopup").hide()
	game_root.get_node("LevelController/MinionRoot").start_spawning()
	if OS.get_environment("MMM_CAPTURE_SETTINGS") == "1":
		game_root.get_node("GameUI").call("_toggle_audio_settings")
	if OS.get_environment("MMM_CAPTURE_ACCESSIBILITY") == "1":
		var ui := game_root.get_node("GameUI")
		ui.get_node("SettingsPanel/HighContrastCheck").button_pressed = true
		ui.get_node("SettingsPanel/CaptionsCheck").button_pressed = true
		ui.call("show_sound_caption", "styx_impact", -260.0)
	var result_mode := OS.get_environment("MMM_CAPTURE_RESULT")
	if result_mode == "success" or result_mode == "failure":
		game_root.get_node("GameUI").call("show_level_finished", result_mode == "success", {
			"rescued": 10,
			"total": 12,
			"required": 10,
			"score": 1125,
		})
