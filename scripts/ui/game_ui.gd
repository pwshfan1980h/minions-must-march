extends CanvasLayer

signal restart_requested
signal job_selected(job_id: String)
signal level_selected(level_number: int)
signal pause_toggled

@onready var job_bar: Panel = $JobBar
@onready var mission_label: Label = $JobBar/MissionLabel
@onready var goal_label: Label = $JobBar/GoalLabel
@onready var score_label: Label = $JobBar/ScoreLabel
@onready var stats_label: Label = $JobBar/StatsLabel
@onready var hint_label: Label = $HintLabel
@onready var skill_dock: Panel = $SkillDock
@onready var chamber_map: Panel = $ChamberMap
@onready var chamber_title: Label = $ChamberMap/ChamberTitle
@onready var campaign_track_label: Label = $ChamberMap/CampaignTrackLabel
@onready var level_button_container: VBoxContainer = $ChamberMap/LevelButtonContainer
@onready var event_log_label: Label = $EventLogLabel
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

func _ready() -> void:
	print("GameUI ready")
	result_label.hide()
	inspect_label.hide()
	perf_label.hide()
	_spooky_font = _make_spooky_font()
	_apply_visual_style()
	blocker_button.pressed.connect(_select_blocker)
	builder_button.pressed.connect(_select_builder)
	digger_button.pressed.connect(_select_digger)
	featherfall_button.pressed.connect(_select_featherfall)
	_populate_chamber_map()
	_update_event_log()
	_update_job_buttons()

func update_stats(stats: Dictionary) -> void:
	_last_stats = stats
	selected_job = stats.get("selected_job", selected_job)
	blockers_remaining = stats.get("blockers", 0)
	builders_remaining = stats.get("builders", 0)
	diggers_remaining = stats.get("diggers", 0)
	featherfalls_remaining = stats.get("featherfalls", 0)

	mission_label.text = String(stats.get("level_name", "Bone Bridge")).to_upper()
	goal_label.text = "☠ %s" % _objective_summary(stats)
	score_label.text = "SCORE\n%04d" % stats.get("score", 0)
	stats_label.text = "SPN %d/%d  SAV %d/%d  LOST %d" % [
		stats.get("spawned", 0),
		stats.get("total", 0),
		stats.get("rescued", 0),
		stats.get("required", 0),
		stats.get("lost", 0),
	]

	blocker_button.text = "1\nBLOCK\n⛔ x%d" % blockers_remaining
	builder_button.text = "2\nBUILD\n🦴 x%d" % builders_remaining
	digger_button.text = "3\nDIG\n⛏ x%d" % diggers_remaining
	featherfall_button.text = "4\nFEATHER\n🪶 x%d" % featherfalls_remaining
	hint_label.text = _build_hint_text(stats)
	_update_job_buttons()
	_update_perf_overlay(true)

func _process(delta: float) -> void:
	if not _perf_overlay_enabled:
		return
	_perf_update_timer += delta
	if _perf_update_timer < 0.25:
		return
	_perf_update_timer = 0.0
	_update_perf_overlay()

func set_pause_inspect(paused: bool) -> void:
	inspect_label.visible = paused
	inspect_label.text = "PAUSED — inspect\nA/D or arrows pan  •  Space resumes"

func add_event_log(text: String) -> void:
	_event_lines.push_front("• " + text)
	while _event_lines.size() > 4:
		_event_lines.pop_back()
	_update_event_log()

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
		var current := "▶" if n == int(_last_stats.get("level_number", LevelState.current_level)) else " "
		var node := "◆" if biome == "ash_catacombs" else "●"
		button.text = "%s %s─ L%02d  %s" % [current, node, n, String(cfg.get("name", "Chamber"))]
		button.tooltip_text = "Campaign stop: %s\n%s" % [biome, String(cfg.get("hint", ""))]
		button.pressed.connect(func() -> void: level_selected.emit(n))
		level_button_container.add_child(button)
	campaign_track_label.text = "──".join(track_nodes) + "   CAMPAIGN ROAD"

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
			_toggle_perf_overlay()

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
	debug_text += "  •  F4 perf ON" if _perf_overlay_enabled else "  •  F4 perf"
	if selected_job == "builder" and builders_remaining > 0:
		return "BUILD selected: click a grounded skeleton by the gold mark. R restarts." + debug_text
	if selected_job == "blocker" and blockers_remaining > 0:
		return "BLOCK selected: brace/release a skeleton. R restarts." + debug_text
	if selected_job == "digger" and diggers_remaining > 0:
		return "DIG selected: click a skeleton standing on cracked ash floor. R restarts." + debug_text
	if selected_job == "featherfall" and featherfalls_remaining > 0:
		return "FEATHER selected: bless one skeleton to survive its next fatal drop. R restarts." + debug_text
	if builders_remaining <= 0 and diggers_remaining <= 0 and featherfalls_remaining <= 0:
		return "Bones and picks spent. Keep marching to the uplight. R restarts." + debug_text
	if builders_remaining <= 0:
		return "Build bones spent. Keep marching to the uplight. R restarts." + debug_text
	return "Pick a skeleton skill from the level dock, then click a skeleton. R restarts." + debug_text

func _update_job_buttons() -> void:
	blocker_button.disabled = blockers_remaining <= 0
	builder_button.disabled = builders_remaining <= 0
	digger_button.disabled = diggers_remaining <= 0
	featherfall_button.disabled = featherfalls_remaining <= 0
	_style_job_button(blocker_button, selected_job == "blocker", blocker_button.disabled)
	_style_job_button(builder_button, selected_job == "builder", builder_button.disabled)
	_style_job_button(digger_button, selected_job == "digger", digger_button.disabled)
	_style_job_button(featherfall_button, selected_job == "featherfall", featherfall_button.disabled)

func _apply_visual_style() -> void:
	job_bar.add_theme_stylebox_override("panel", _panel_box(Color(0.034, 0.027, 0.042, 0.86), Color(0.66, 0.53, 0.31, 0.48), 1, 10))
	skill_dock.add_theme_stylebox_override("panel", _panel_box(Color(0.030, 0.024, 0.034, 0.58), Color(0.95, 0.72, 0.28, 0.38), 1, 12))
	chamber_map.add_theme_stylebox_override("panel", _panel_box(Color(0.025, 0.021, 0.032, 0.72), Color(0.52, 0.70, 0.58, 0.34), 1, 10))

	for label in [mission_label, goal_label, score_label, stats_label, hint_label, event_log_label, chamber_title, campaign_track_label, inspect_label, result_label]:
		label.add_theme_font_override("font", _spooky_font)
		label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.86))
		label.add_theme_constant_override("shadow_offset_x", 2)
		label.add_theme_constant_override("shadow_offset_y", 2)

	mission_label.add_theme_color_override("font_color", Color("ffd36f"))
	mission_label.add_theme_font_size_override("font_size", 18)
	goal_label.add_theme_color_override("font_color", Color("e8d7a9"))
	goal_label.add_theme_font_size_override("font_size", 12)
	score_label.add_theme_color_override("font_color", Color("aef5a4"))
	score_label.add_theme_font_size_override("font_size", 14)
	stats_label.add_theme_color_override("font_color", Color("d9ccae"))
	stats_label.add_theme_font_size_override("font_size", 12)
	hint_label.add_theme_color_override("font_color", Color("f1e7c8"))
	hint_label.add_theme_font_size_override("font_size", 12)
	event_log_label.add_theme_color_override("font_color", Color("b9d8bd"))
	event_log_label.add_theme_font_size_override("font_size", 11)
	chamber_title.add_theme_color_override("font_color", Color("bff0c4"))
	chamber_title.add_theme_font_size_override("font_size", 13)
	campaign_track_label.add_theme_color_override("font_color", Color("ffbf6e"))
	campaign_track_label.add_theme_font_size_override("font_size", 12)

	result_label.add_theme_font_size_override("font_size", 30)
	inspect_label.add_theme_color_override("font_color", Color("fff1c4"))
	inspect_label.add_theme_font_size_override("font_size", 22)
	result_label.add_theme_constant_override("shadow_offset_x", 3)
	result_label.add_theme_constant_override("shadow_offset_y", 3)
	perf_label.add_theme_font_override("font", _spooky_font)
	perf_label.add_theme_font_size_override("font_size", 13)
	perf_label.add_theme_color_override("font_color", Color("b5ffbf"))
	perf_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	perf_label.add_theme_constant_override("shadow_offset_x", 2)
	perf_label.add_theme_constant_override("shadow_offset_y", 2)

	for button in [blocker_button, builder_button, digger_button, featherfall_button]:
		button.add_theme_font_override("font", _spooky_font)
		button.add_theme_font_size_override("font_size", 15)
		button.add_theme_color_override("font_disabled_color", Color(0.50, 0.47, 0.43, 0.9))
		button.add_theme_color_override("font_color", Color("f0e2bf"))
		button.add_theme_color_override("font_hover_color", Color("fff1c4"))
		button.add_theme_color_override("font_pressed_color", Color("fff1c4"))
		button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER

func _style_job_button(button: Button, selected: bool, disabled: bool) -> void:
	var fill := Color(0.12, 0.095, 0.075, 0.94)
	var border := Color(0.55, 0.47, 0.34, 0.82)
	if disabled:
		fill = Color(0.055, 0.052, 0.058, 0.76)
		border = Color(0.22, 0.20, 0.19, 0.75)
	elif selected:
		fill = Color(0.35, 0.20, 0.055, 0.98)
		border = Color(1.0, 0.78, 0.28, 1.0)
	button.add_theme_stylebox_override("normal", _panel_box(fill, border, 2 if not selected else 3, 12))
	button.add_theme_stylebox_override("hover", _panel_box(fill.lightened(0.13), border.lightened(0.20), 2, 12))
	button.add_theme_stylebox_override("pressed", _panel_box(fill.darkened(0.10), border.lightened(0.30), 3, 12))
	button.add_theme_stylebox_override("disabled", _panel_box(fill, border, 1, 12))

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
	box.content_margin_left = 8
	box.content_margin_top = 6
	box.content_margin_right = 8
	box.content_margin_bottom = 6
	return box

func _make_spooky_font() -> SystemFont:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Papyrus", "Chalkduster", "Marker Felt", "Georgia", "Times New Roman"])
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
