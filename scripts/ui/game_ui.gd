extends CanvasLayer

const LevelState := preload("res://scripts/core/level_state.gd")

signal restart_requested
signal job_selected(job_id: String)
signal level_selected(level_number: int)
signal pause_toggled
signal speed_requested(multiplier: float)
signal audio_settings_changed(settings: Dictionary)
signal accessibility_settings_changed(settings: Dictionary)

@onready var job_bar: Panel = $JobBar
@onready var mission_label: Label = $JobBar/MissionLabel
@onready var goal_label: Label = $JobBar/GoalLabel
@onready var hint_label: Label = $JobBar/HintLabel
@onready var objective_collapsed_label: Label = $JobBar/ObjectiveCollapsedLabel
@onready var stats_panel: Panel = $StatsPanel
@onready var score_label: Label = $StatsPanel/ScoreLabel
@onready var stats_label: Label = $StatsPanel/StatsLabel
@onready var rescue_progress: ProgressBar = $StatsPanel/RescueProgress
@onready var level_list_toggle_button: Button = $LevelListToggleButton
@onready var speed_button: Button = $SpeedButton
@onready var settings_button: Button = $SettingsButton
@onready var settings_panel: Panel = $SettingsPanel
@onready var settings_title: Label = $SettingsPanel/SettingsTitle
@onready var master_label: Label = $SettingsPanel/MasterLabel
@onready var master_slider: HSlider = $SettingsPanel/MasterSlider
@onready var sfx_label: Label = $SettingsPanel/SfxLabel
@onready var sfx_slider: HSlider = $SettingsPanel/SfxSlider
@onready var ambience_label: Label = $SettingsPanel/AmbienceLabel
@onready var ambience_slider: HSlider = $SettingsPanel/AmbienceSlider
@onready var mute_check: CheckButton = $SettingsPanel/MuteCheck
@onready var range_label: Label = $SettingsPanel/RangeLabel
@onready var range_option: OptionButton = $SettingsPanel/RangeOption
@onready var accessibility_title: Label = $SettingsPanel/AccessibilityTitle
@onready var high_contrast_check: CheckButton = $SettingsPanel/HighContrastCheck
@onready var reduced_motion_check: CheckButton = $SettingsPanel/ReducedMotionCheck
@onready var captions_check: CheckButton = $SettingsPanel/CaptionsCheck
@onready var skill_dock: Panel = $SkillDock
@onready var chamber_map: Panel = $ChamberMap
@onready var chamber_title: Label = $ChamberMap/ChamberTitle
@onready var campaign_track_label: Label = $ChamberMap/CampaignTrackLabel
@onready var level_button_container: VBoxContainer = $ChamberMap/LevelButtonContainer
@onready var event_log_label: Label = $EventLogLabel
@onready var sound_caption_label: Label = $SoundCaptionLabel
@onready var tutorial_popup: Panel = $TutorialPopup
@onready var tutorial_skull_label: Label = $TutorialPopup/SkullLabel
@onready var tutorial_title: Label = $TutorialPopup/TutorialTitle
@onready var tutorial_text: Label = $TutorialPopup/TutorialText
@onready var tutorial_ok_button: Button = $TutorialPopup/TutorialOkButton
@onready var blocker_button: Button = $SkillDock/BlockerButton
@onready var builder_button: Button = $SkillDock/BuilderButton
@onready var digger_button: Button = $SkillDock/DiggerButton
@onready var featherfall_button: Button = $SkillDock/FeatherfallButton
@onready var result_label: Label = $ResultLabel
@onready var inspect_label: Label = $InspectLabel
@onready var perf_label: Label = $PerfLabel

var selected_job := "builder"
var blockers_remaining := 0
var builders_remaining := 0
var diggers_remaining := 0
var featherfalls_remaining := 0
var _last_stats: Dictionary = {}
var _spooky_font: SystemFont
var _perf_overlay_enabled := false
var _perf_update_timer := 0.0
var _event_lines: Array[String] = []
var _objective_collapsed := false
var _objective_collapse_pending := false
var _objective_collapse_elapsed := 0.0
var _last_level_number := -1
var _march_speed := 1
var _feedback_flash: ColorRect
var _feedback_tween: Tween
var _caption_tween: Tween
var _audio_settings := {
	"master_db": 0.0,
	"sfx_db": 0.0,
	"ambience_db": 0.0,
	"muted": false,
	"dynamic_range": "full",
}
var _accessibility_settings := {
	"high_contrast": false,
	"reduced_motion": false,
	"sound_captions": false,
}
const SOUND_CAPTIONS := {
	"builder_snap": "RIB BRIDGE SET",
	"blocker_brace": "BLOCKER BRACES",
	"digger_crack": "STONE CRACKS",
	"feather_chime": "FEATHERFALL CHIMES",
	"styx_impact": "STYX SPLASH",
	"death_yelp_tall": "SKELETON CRIES OUT",
	"death_yelp_wiry": "SKELETON CRIES OUT",
	"death_yelp_stocky": "SKELETON CRIES OUT",
	"exit_rescue": "SOUL RESCUED",
	"level_success": "CRYPT CLEARED",
	"level_fail": "MARCH FAILED",
}
static var tutorial_seen_this_session := false

const COLOR_BONE := Color("f1eadb")
const COLOR_MUTED_BONE := Color("cfc5b1")
const COLOR_BUILD := Color("f0bd52")
const COLOR_BLOCK := Color("e77b69")
const COLOR_DIG := Color("d98945")
const COLOR_FEATHER := Color("82d9eb")
const COLOR_RESCUE := Color("8ce3c5")

func _ready() -> void:
	print("GameUI ready")
	result_label.hide()
	inspect_label.hide()
	perf_label.hide()
	_spooky_font = _make_spooky_font()
	_build_feedback_flash()
	_apply_visual_style()
	blocker_button.pressed.connect(_select_blocker)
	builder_button.pressed.connect(_select_builder)
	digger_button.pressed.connect(_select_digger)
	featherfall_button.pressed.connect(_select_featherfall)
	level_list_toggle_button.pressed.connect(_toggle_level_list)
	speed_button.pressed.connect(_cycle_march_speed)
	settings_button.pressed.connect(_toggle_audio_settings)
	tutorial_ok_button.pressed.connect(_dismiss_tutorial_popup)
	_configure_audio_settings()
	if tutorial_seen_this_session:
		tutorial_popup.hide()
	else:
		tutorial_popup.show()
		tutorial_seen_this_session = true
	chamber_map.hide()
	settings_panel.hide()
	_populate_chamber_map()
	_update_event_log()
	_update_job_buttons()
	_expand_objective_then_collapse()

func update_stats(stats: Dictionary) -> void:
	_last_stats = stats
	var level_number := int(stats.get("level_number", LevelState.current_level))
	if level_number != _last_level_number:
		_last_level_number = level_number
		_expand_objective_then_collapse()
	selected_job = stats.get("selected_job", selected_job)
	blockers_remaining = stats.get("blockers", 0)
	builders_remaining = stats.get("builders", 0)
	diggers_remaining = stats.get("diggers", 0)
	featherfalls_remaining = stats.get("featherfalls", 0)

	mission_label.text = String(stats.get("level_name", "Bone Bridge")).to_upper()
	objective_collapsed_label.text = "OBJ ▸ " + String(stats.get("level_name", "Bone Bridge")).to_upper()
	goal_label.text = "☠ %s" % _objective_summary(stats)
	score_label.text = "SCORE\n%04d" % stats.get("score", 0)
	stats_label.text = "SPN %d/%d\nSAV %d/%d  LOST %d" % [
		stats.get("spawned", 0),
		stats.get("total", 0),
		stats.get("rescued", 0),
		stats.get("required", 0),
		stats.get("lost", 0),
	]
	rescue_progress.max_value = maxi(1, int(stats.get("required", 1)))
	rescue_progress.value = int(stats.get("rescued", 0))
	rescue_progress.tooltip_text = "%d of %d required skeletons rescued" % [stats.get("rescued", 0), stats.get("required", 0)]

	blocker_button.text = "1 [] BLOCK x%d" % blockers_remaining
	builder_button.text = "2 // BUILD x%d" % builders_remaining
	digger_button.text = "3 VV DIG   x%d" % diggers_remaining
	featherfall_button.text = "4 ** FEATHER x%d" % featherfalls_remaining
	hint_label.text = _build_hint_text(stats)
	_update_job_buttons()
	_update_perf_overlay(true)

func _process(delta: float) -> void:
	if _objective_collapse_pending:
		_objective_collapse_elapsed += delta
		if _objective_collapse_elapsed >= 4.0:
			_objective_collapse_pending = false
			_set_objective_collapsed(true)
	if not _perf_overlay_enabled:
		return
	_perf_update_timer += delta
	if _perf_update_timer < 0.25:
		return
	_perf_update_timer = 0.0
	_update_perf_overlay()

func _expand_objective_then_collapse() -> void:
	# Objective appears full-size whenever a level loads, then collapses into a
	# small upper-left marker so the playfield is not covered during the puzzle.
	_set_objective_collapsed(false)
	_objective_collapse_elapsed = 0.0
	_objective_collapse_pending = true

func _set_objective_collapsed(collapsed: bool) -> void:
	_objective_collapsed = collapsed
	objective_collapsed_label.visible = collapsed
	mission_label.visible = not collapsed
	goal_label.visible = not collapsed
	hint_label.visible = not collapsed
	if collapsed:
		job_bar.offset_right = job_bar.offset_left + 252.0
		job_bar.offset_bottom = job_bar.offset_top + 30.0
	else:
		job_bar.offset_right = job_bar.offset_left + 376.0
		job_bar.offset_bottom = job_bar.offset_top + 108.0

func set_pause_inspect(paused: bool) -> void:
	inspect_label.visible = paused
	inspect_label.text = "PAUSED — inspect\nA/D or arrows pan  •  Space resumes"

func add_event_log(text: String) -> void:
	_event_lines.push_front("• " + text)
	while _event_lines.size() > 4:
		_event_lines.pop_back()
	_update_event_log()

func play_feedback(kind: String) -> void:
	if bool(_accessibility_settings["reduced_motion"]):
		return
	var color := Color(1.0, 1.0, 1.0, 0.04)
	var button: Button
	match kind:
		"builder":
			color = Color(COLOR_BUILD, 0.065)
			button = builder_button
		"blocker":
			color = Color(COLOR_BLOCK, 0.065)
			button = blocker_button
		"digger":
			color = Color(COLOR_DIG, 0.075)
			button = digger_button
		"featherfall":
			color = Color(COLOR_FEATHER, 0.075)
			button = featherfall_button
		"rescue":
			color = Color(COLOR_RESCUE, 0.085)
		"styx", "failure":
			color = Color(0.82, 0.18, 0.10, 0.075)
	if _feedback_tween != null:
		_feedback_tween.kill()
	_feedback_flash.color = color
	_feedback_tween = create_tween()
	_feedback_tween.tween_property(_feedback_flash, "color:a", 0.0, 0.34).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if button != null and not button.disabled:
		_pulse_button(button)

func _build_feedback_flash() -> void:
	_feedback_flash = ColorRect.new()
	_feedback_flash.name = "FeedbackFlash"
	_feedback_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_feedback_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_feedback_flash.color = Color(1.0, 1.0, 1.0, 0.0)
	add_child(_feedback_flash)
	move_child(_feedback_flash, 0)

func _pulse_button(button: Button) -> void:
	button.pivot_offset = button.size * 0.5
	var tween := create_tween()
	tween.tween_property(button, "scale", Vector2(1.045, 1.045), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2.ONE, 0.13).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func show_sound_caption(sound_id: String, horizontal_offset: float) -> void:
	if not bool(_accessibility_settings["sound_captions"]) or not SOUND_CAPTIONS.has(sound_id):
		return
	var direction := ""
	if horizontal_offset < -120.0:
		direction = "<  "
	elif horizontal_offset > 120.0:
		direction = "  >"
	sound_caption_label.text = direction + String(SOUND_CAPTIONS[sound_id])
	sound_caption_label.visible = true
	sound_caption_label.modulate.a = 1.0
	if _caption_tween != null:
		_caption_tween.kill()
	_caption_tween = create_tween()
	_caption_tween.tween_interval(0.72)
	_caption_tween.tween_property(sound_caption_label, "modulate:a", 0.0, 0.28)
	_caption_tween.tween_callback(sound_caption_label.hide)

func _update_event_log() -> void:
	if _event_lines.is_empty():
		event_log_label.text = "March log sleeps."
	else:
		event_log_label.text = "MARCH LOG\n" + "\n".join(_event_lines)

func _objective_summary(stats: Dictionary) -> String:
	var skills := []
	if stats.get("blockers", 0) > 0:
		skills.append("BLOCK x%d" % stats.get("blockers", 0))
	if stats.get("builders", 0) > 0:
		skills.append("BUILD x%d" % stats.get("builders", 0))
	if stats.get("diggers", 0) > 0:
		skills.append("DIG x%d" % stats.get("diggers", 0))
	if stats.get("featherfalls", 0) > 0:
		skills.append("FEATHER x%d" % stats.get("featherfalls", 0))
	var skill_text := " / ".join(skills) if not skills.is_empty() else "none"
	return "%s  •  Skills: %s" % [stats.get("goal_text", "Save the march"), skill_text]

func _populate_chamber_map() -> void:
	for child in level_button_container.get_children():
		child.queue_free()
	var track_nodes: Array[String] = []
	for cfg in LevelState.all_levels():
		var n := int(cfg.get("number", 0))
		var biome := String(cfg.get("biome", "crypt"))
		track_nodes.append("◆" if biome == "ash_catacombs" else "●")
		var button := Button.new()
		button.name = "LevelButton%02d" % n
		button.focus_mode = Control.FOCUS_NONE
		button.clip_text = true
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		button.custom_minimum_size = Vector2(0.0, 26.0)
		var current := "▶" if n == int(_last_stats.get("level_number", LevelState.current_level)) else " "
		var node := "◆" if biome == "ash_catacombs" else "●"
		button.text = "%s%s L%02d %s" % [current, node, n, _campaign_button_name(String(cfg.get("name", "Chamber")))]
		button.tooltip_text = "Campaign stop: %s\n%s" % [biome, String(cfg.get("hint", ""))]
		button.pressed.connect(func() -> void: level_selected.emit(n))
		_style_utility_button(button)
		level_button_container.add_child(button)
	campaign_track_label.text = "F4 closes  •  %d maps" % track_nodes.size()

func _campaign_button_name(level_name: String) -> String:
	# Keep campaign map names inside the visual box; full names remain in tooltips
	# and the mission header. Text overrun is still enabled as a second guard.
	const MAX_CAMPAIGN_NAME_CHARS := 18
	if level_name.length() <= MAX_CAMPAIGN_NAME_CHARS:
		return level_name
	return level_name.substr(0, MAX_CAMPAIGN_NAME_CHARS - 1).rstrip(" ") + "…"

func show_level_finished(success: bool, stats: Dictionary) -> void:
	result_label.show()
	if success:
		result_label.text = "CRYPT CLEARED\nSaved %d/%d  •  Score %04d" % [stats.get("rescued", 0), stats.get("total", 0), stats.get("score", 0)]
		result_label.add_theme_color_override("font_color", Color("b5ffbf"))
	else:
		result_label.text = "MINIONS SQUANDERED\nSaved %d/%d — need %d  •  Score %04d" % [
			stats.get("rescued", 0), stats.get("total", 0), stats.get("required", 0), stats.get("score", 0)
		]
		result_label.add_theme_color_override("font_color", Color("ff9d8f"))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			restart_requested.emit()
		elif event.keycode == KEY_1:
			_select_blocker()
		elif event.keycode == KEY_2:
			_select_builder()
		elif event.keycode == KEY_3:
			_select_digger()
		elif event.keycode == KEY_4:
			_select_featherfall()
		elif event.keycode == KEY_SPACE:
			pause_toggled.emit()
		elif event.keycode == KEY_F4:
			_toggle_level_list()
		elif event.keycode == KEY_F2:
			_toggle_audio_settings()
		elif event.keycode == KEY_F:
			_cycle_march_speed()

func _dismiss_tutorial_popup() -> void:
	tutorial_popup.hide()

func _toggle_level_list() -> void:
	chamber_map.visible = not chamber_map.visible
	if chamber_map.visible:
		settings_panel.hide()
	level_list_toggle_button.text = "F4 CLOSE" if chamber_map.visible else "F4 LEVELS"

func _toggle_audio_settings() -> void:
	settings_panel.visible = not settings_panel.visible
	if settings_panel.visible:
		chamber_map.hide()
		level_list_toggle_button.text = "F4 LEVELS"
	settings_button.text = "F2 CLOSE" if settings_panel.visible else "F2 AUDIO"

func get_audio_settings() -> Dictionary:
	return _audio_settings.duplicate(true)

func get_accessibility_settings() -> Dictionary:
	return _accessibility_settings.duplicate(true)

func _configure_audio_settings() -> void:
	range_option.add_item("FULL RANGE")
	range_option.add_item("NIGHT MODE")
	_load_audio_settings()
	master_slider.value = float(_audio_settings["master_db"])
	sfx_slider.value = float(_audio_settings["sfx_db"])
	ambience_slider.value = float(_audio_settings["ambience_db"])
	mute_check.button_pressed = bool(_audio_settings["muted"])
	range_option.select(1 if String(_audio_settings["dynamic_range"]) == "night" else 0)
	high_contrast_check.button_pressed = bool(_accessibility_settings["high_contrast"])
	reduced_motion_check.button_pressed = bool(_accessibility_settings["reduced_motion"])
	captions_check.button_pressed = bool(_accessibility_settings["sound_captions"])
	master_slider.value_changed.connect(func(value: float) -> void:
		_audio_settings["master_db"] = value
		audio_settings_changed.emit(get_audio_settings())
	)
	sfx_slider.value_changed.connect(func(value: float) -> void:
		_audio_settings["sfx_db"] = value
		audio_settings_changed.emit(get_audio_settings())
	)
	ambience_slider.value_changed.connect(func(value: float) -> void:
		_audio_settings["ambience_db"] = value
		audio_settings_changed.emit(get_audio_settings())
	)
	master_slider.drag_ended.connect(func(_changed: bool) -> void: _save_audio_settings())
	sfx_slider.drag_ended.connect(func(_changed: bool) -> void: _save_audio_settings())
	ambience_slider.drag_ended.connect(func(_changed: bool) -> void: _save_audio_settings())
	mute_check.toggled.connect(func(enabled: bool) -> void:
		_audio_settings["muted"] = enabled
		_save_audio_settings()
		audio_settings_changed.emit(get_audio_settings())
	)
	range_option.item_selected.connect(func(index: int) -> void:
		_audio_settings["dynamic_range"] = "night" if index == 1 else "full"
		_save_audio_settings()
		audio_settings_changed.emit(get_audio_settings())
	)
	high_contrast_check.toggled.connect(_on_accessibility_toggled.bind("high_contrast"))
	reduced_motion_check.toggled.connect(_on_accessibility_toggled.bind("reduced_motion"))
	captions_check.toggled.connect(_on_accessibility_toggled.bind("sound_captions"))

func _on_accessibility_toggled(enabled: bool, key: String) -> void:
	_accessibility_settings[key] = enabled
	_save_audio_settings()
	accessibility_settings_changed.emit(get_accessibility_settings())

func _load_audio_settings() -> void:
	var config := ConfigFile.new()
	if config.load("user://settings.cfg") != OK:
		return
	for key in _audio_settings.keys():
		_audio_settings[key] = config.get_value("audio", key, _audio_settings[key])
	for key in _accessibility_settings.keys():
		_accessibility_settings[key] = config.get_value("accessibility", key, _accessibility_settings[key])

func _save_audio_settings() -> void:
	var config := ConfigFile.new()
	config.load("user://settings.cfg")
	for key in _audio_settings.keys():
		config.set_value("audio", key, _audio_settings[key])
	for key in _accessibility_settings.keys():
		config.set_value("accessibility", key, _accessibility_settings[key])
	config.save("user://settings.cfg")

func _cycle_march_speed() -> void:
	_march_speed = 1 if _march_speed >= 3 else _march_speed + 1
	speed_button.text = "F SPEED %d×" % _march_speed
	speed_button.tooltip_text = "March speed: %d× (F cycles)" % _march_speed
	speed_requested.emit(float(_march_speed))

func _select_blocker() -> void:
	if blockers_remaining <= 0:
		return
	selected_job = "blocker"
	_update_job_buttons()
	job_selected.emit(selected_job)

func _select_builder() -> void:
	if builders_remaining <= 0:
		return
	selected_job = "builder"
	_update_job_buttons()
	job_selected.emit(selected_job)

func _select_digger() -> void:
	if diggers_remaining <= 0:
		return
	selected_job = "digger"
	_update_job_buttons()
	job_selected.emit(selected_job)

func _select_featherfall() -> void:
	if featherfalls_remaining <= 0:
		return
	selected_job = "featherfall"
	_update_job_buttons()
	job_selected.emit(selected_job)

func _build_hint_text(stats: Dictionary) -> String:
	var debug_text := "  •  F3 hitbox ON" if stats.get("debug_click_areas", false) else "  •  F3 hitboxes"
	debug_text += "  •  F4 levels"
	if selected_job == "builder" and builders_remaining > 0:
		return "BUILD selected: click a grounded skeleton by the gold mark. A/D pan. R restarts." + debug_text
	if selected_job == "blocker" and blockers_remaining > 0:
		return "BLOCK selected: brace/release a skeleton. A/D pan. R restarts." + debug_text
	if selected_job == "digger" and diggers_remaining > 0:
		return "DIG selected: click a skeleton standing on cracked ash floor. A/D pan. R restarts." + debug_text
	if selected_job == "featherfall" and featherfalls_remaining > 0:
		return "FEATHER selected: bless one skeleton to survive its next fatal drop. A/D pan. R restarts." + debug_text
	if builders_remaining <= 0 and diggers_remaining <= 0 and featherfalls_remaining <= 0:
		return "Bones and picks spent. Keep marching to the uplight. R restarts." + debug_text
	if builders_remaining <= 0:
		return "Build bones spent. Keep marching to the uplight. R restarts." + debug_text
	if int(stats.get("spawned", 0)) == 0 and int(stats.get("active", 0)) == 0:
		return "Click the pulsing spawn portal to begin. Use A/D or arrows to pan. R restarts." + debug_text
	return "Pick a skeleton skill from the bottom dock, then click a skeleton. A/D pan. R restarts." + debug_text

func _update_job_buttons() -> void:
	blocker_button.disabled = blockers_remaining <= 0
	builder_button.disabled = builders_remaining <= 0
	digger_button.disabled = diggers_remaining <= 0
	featherfall_button.disabled = featherfalls_remaining <= 0
	_style_job_button(blocker_button, selected_job == "blocker", blocker_button.disabled, COLOR_BLOCK)
	_style_job_button(builder_button, selected_job == "builder", builder_button.disabled, COLOR_BUILD)
	_style_job_button(digger_button, selected_job == "digger", digger_button.disabled, COLOR_DIG)
	_style_job_button(featherfall_button, selected_job == "featherfall", featherfall_button.disabled, COLOR_FEATHER)

func _apply_visual_style() -> void:
	# Corner-and-bottom bone UI: objective appears in the upper-left then collapses;
	# stats stay small in the upper-right; actions live in a bottom horizontal stack.
	job_bar.add_theme_stylebox_override("panel", _panel_box(Color(0.015, 0.014, 0.013, 0.88), Color(0.78, 0.74, 0.64, 0.62), 1, 6))
	stats_panel.add_theme_stylebox_override("panel", _panel_box(Color(0.012, 0.012, 0.011, 0.82), Color(0.78, 0.74, 0.64, 0.58), 1, 6))
	skill_dock.add_theme_stylebox_override("panel", _panel_box(Color(0.010, 0.010, 0.009, 0.62), Color(0.88, 0.84, 0.74, 0.52), 1, 6))
	chamber_map.add_theme_stylebox_override("panel", _panel_box(Color(0.012, 0.012, 0.011, 0.86), Color(0.70, 0.68, 0.62, 0.54), 1, 6))
	tutorial_popup.add_theme_stylebox_override("panel", _panel_box(Color(0.012, 0.011, 0.010, 0.96), Color(0.88, 0.84, 0.74, 0.82), 2, 12))

	for label in [mission_label, goal_label, objective_collapsed_label, score_label, stats_label, hint_label, event_log_label, chamber_title, campaign_track_label, inspect_label, result_label, tutorial_skull_label, tutorial_title, tutorial_text, settings_title, master_label, sfx_label, ambience_label, range_label, accessibility_title, sound_caption_label]:
		label.add_theme_font_override("font", _spooky_font)
		label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.88))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)

	mission_label.add_theme_color_override("font_color", COLOR_BONE)
	mission_label.add_theme_font_size_override("font_size", 15)
	goal_label.add_theme_color_override("font_color", COLOR_RESCUE)
	goal_label.add_theme_font_size_override("font_size", 10)
	objective_collapsed_label.add_theme_color_override("font_color", COLOR_BONE)
	objective_collapsed_label.add_theme_font_size_override("font_size", 12)
	score_label.add_theme_color_override("font_color", Color("f7f1e4"))
	score_label.add_theme_font_size_override("font_size", 11)
	stats_label.add_theme_color_override("font_color", COLOR_MUTED_BONE)
	stats_label.add_theme_font_size_override("font_size", 10)
	hint_label.add_theme_color_override("font_color", Color("e8e1d4"))
	hint_label.add_theme_font_size_override("font_size", 10)
	event_log_label.add_theme_color_override("font_color", COLOR_MUTED_BONE)
	event_log_label.add_theme_font_size_override("font_size", 9)
	chamber_title.add_theme_color_override("font_color", Color("f0eadc"))
	chamber_title.add_theme_font_size_override("font_size", 11)
	campaign_track_label.add_theme_color_override("font_color", Color("d6d0c2"))
	campaign_track_label.add_theme_font_size_override("font_size", 9)
	tutorial_skull_label.add_theme_color_override("font_color", Color("f3eddf"))
	tutorial_skull_label.add_theme_font_size_override("font_size", 86)
	tutorial_title.add_theme_color_override("font_color", Color("f7f1e4"))
	tutorial_title.add_theme_font_size_override("font_size", 20)
	tutorial_text.add_theme_color_override("font_color", Color("d8d1c2"))
	tutorial_text.add_theme_font_size_override("font_size", 15)

	result_label.add_theme_font_size_override("font_size", 26)
	inspect_label.add_theme_color_override("font_color", Color("f7f1e4"))
	inspect_label.add_theme_font_size_override("font_size", 18)
	result_label.add_theme_constant_override("shadow_offset_x", 2)
	result_label.add_theme_constant_override("shadow_offset_y", 2)
	perf_label.add_theme_font_override("font", _spooky_font)
	perf_label.add_theme_font_size_override("font_size", 11)
	perf_label.add_theme_color_override("font_color", Color("f0eadc"))
	perf_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	perf_label.add_theme_constant_override("shadow_offset_x", 1)
	perf_label.add_theme_constant_override("shadow_offset_y", 1)

	for button in [blocker_button, builder_button, digger_button, featherfall_button]:
		button.add_theme_font_override("font", _spooky_font)
		button.add_theme_font_size_override("font_size", 10)
		button.add_theme_color_override("font_disabled_color", Color(0.42, 0.40, 0.37, 0.9))
		button.add_theme_color_override("font_color", Color("eee7d8"))
		button.add_theme_color_override("font_hover_color", Color("ffffff"))
		button.add_theme_color_override("font_pressed_color", Color("ffffff"))
		button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_utility_button(level_list_toggle_button)
	_style_utility_button(speed_button)
	_style_utility_button(settings_button)
	_style_utility_button(mute_check)
	_style_utility_button(range_option)
	_style_utility_button(high_contrast_check)
	_style_utility_button(reduced_motion_check)
	_style_utility_button(captions_check)
	_style_utility_button(tutorial_ok_button)
	settings_panel.add_theme_stylebox_override("panel", _panel_box(Color(0.012, 0.011, 0.010, 0.96), Color(0.58, 0.82, 0.72, 0.76), 1, 8))
	settings_title.add_theme_color_override("font_color", COLOR_RESCUE)
	accessibility_title.add_theme_color_override("font_color", COLOR_FEATHER)
	sound_caption_label.add_theme_color_override("font_color", COLOR_BONE)
	sound_caption_label.add_theme_font_size_override("font_size", 13)
	rescue_progress.show_percentage = false
	rescue_progress.add_theme_stylebox_override("background", _panel_box(Color(0.04, 0.035, 0.03, 0.95), Color(0.36, 0.34, 0.30, 0.9), 1, 3))
	rescue_progress.add_theme_stylebox_override("fill", _panel_box(COLOR_RESCUE.darkened(0.18), COLOR_RESCUE.lightened(0.22), 1, 3))

func _style_job_button(button: Button, selected: bool, disabled: bool, accent: Color) -> void:
	var fill := Color(0.025, 0.024, 0.022, 0.94)
	var border := Color(accent, 0.58)
	if disabled:
		fill = Color(0.012, 0.012, 0.012, 0.70)
		border = Color(0.28, 0.27, 0.25, 0.70)
		button.add_theme_color_override("font_color", Color(0.42, 0.40, 0.37, 0.9))
	elif selected:
		fill = Color(accent.darkened(0.66), 0.98)
		border = accent.lightened(0.16)
		button.add_theme_color_override("font_color", accent.lightened(0.38))
	else:
		button.add_theme_color_override("font_color", accent.lightened(0.25))
	button.add_theme_stylebox_override("normal", _panel_box(fill, border, 1 if not selected else 2, 5))
	button.add_theme_stylebox_override("hover", _panel_box(fill.lightened(0.10), border.lightened(0.18), 2, 5))
	button.add_theme_stylebox_override("pressed", _panel_box(fill.darkened(0.08), border.lightened(0.28), 2, 5))
	button.add_theme_stylebox_override("disabled", _panel_box(fill, border, 1, 5))

func _style_utility_button(button: Button) -> void:
	button.add_theme_font_override("font", _spooky_font)
	button.add_theme_font_size_override("font_size", 11)
	button.add_theme_color_override("font_color", Color("eee7d8"))
	button.add_theme_color_override("font_hover_color", Color("ffffff"))
	button.add_theme_color_override("font_pressed_color", Color("080807"))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("normal", _panel_box(Color(0.025, 0.024, 0.022, 0.94), Color(0.72, 0.69, 0.61, 0.70), 1, 5))
	button.add_theme_stylebox_override("hover", _panel_box(Color(0.075, 0.072, 0.066, 0.96), Color(0.90, 0.86, 0.75, 0.85), 1, 5))
	button.add_theme_stylebox_override("pressed", _panel_box(Color(0.82, 0.78, 0.68, 0.96), Color(1.0, 0.98, 0.90, 1.0), 2, 5))
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER

func _panel_box(fill: Color, border: Color, border_width: int, corner_radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.border_width_left = border_width
	box.border_width_top = border_width
	box.border_width_right = border_width
	box.border_width_bottom = border_width
	box.corner_radius_top_left = corner_radius
	box.corner_radius_top_right = corner_radius
	box.corner_radius_bottom_left = corner_radius
	box.corner_radius_bottom_right = corner_radius
	box.content_margin_left = 4
	box.content_margin_top = 3
	box.content_margin_right = 4
	box.content_margin_bottom = 3
	return box

func _make_spooky_font() -> SystemFont:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Copperplate", "Avenir Next Condensed", "Georgia", "Times New Roman"])
	font.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	return font

func _toggle_perf_overlay() -> void:
	_perf_overlay_enabled = not _perf_overlay_enabled
	perf_label.visible = _perf_overlay_enabled
	_update_perf_overlay(true)

func _update_perf_overlay(force := false) -> void:
	if not force and not _perf_overlay_enabled:
		return
	perf_label.text = "FPS %d   ACT %d   SPN %d/%d   NODES %d" % [
		Engine.get_frames_per_second(),
		_last_stats.get("active", 0),
		_last_stats.get("spawned", 0),
		_last_stats.get("total", 0),
		get_tree().get_node_count(),
	]
