extends CanvasLayer

signal restart_requested
signal job_selected(job_id: String)

@onready var job_bar: Panel = $JobBar
@onready var mission_label: Label = $JobBar/MissionLabel
@onready var stats_label: Label = $JobBar/StatsLabel
@onready var hint_label: Label = $JobBar/HintLabel
@onready var blocker_button: Button = $JobBar/BlockerButton
@onready var builder_button: Button = $JobBar/BuilderButton
@onready var result_label: Label = $ResultLabel

var selected_job := "builder"
var blockers_remaining := 0
var builders_remaining := 0
var _last_stats: Dictionary = {}

func _ready() -> void:
	print("GameUI ready")
	result_label.hide()
	_apply_visual_style()
	blocker_button.pressed.connect(_select_blocker)
	builder_button.pressed.connect(_select_builder)
	_update_job_buttons()

func update_stats(stats: Dictionary) -> void:
	_last_stats = stats
	selected_job = stats.get("selected_job", selected_job)
	blockers_remaining = stats.get("blockers", 0)
	builders_remaining = stats.get("builders", 0)

	mission_label.text = "BUILDER DEMO #1 — FIRST RIB BRIDGE"
	stats_label.text = "Spawned %d/%d   •   Active %d   •   Saved %d/%d   •   Lost %d" % [
		stats.get("spawned", 0),
		stats.get("total", 0),
		stats.get("active", 0),
		stats.get("rescued", 0),
		stats.get("required", 0),
		stats.get("lost", 0),
	]

	blocker_button.text = "1  BLOCKER\nx%d • %s" % [
		blockers_remaining,
		"locked here" if blockers_remaining <= 0 else "brace / release",
	]
	builder_button.text = "2  BUILDER\nx%d • %s" % [
		builders_remaining,
		"spent" if builders_remaining <= 0 else "click skeleton",
	]
	hint_label.text = _build_hint_text(stats)
	_update_job_buttons()

func show_level_finished(success: bool, stats: Dictionary) -> void:
	result_label.show()
	if success:
		result_label.text = "CRYPT CLEARED\nSaved %d/%d" % [stats.get("rescued", 0), stats.get("total", 0)]
		result_label.add_theme_color_override("font_color", Color("b5ffbf"))
	else:
		result_label.text = "MINIONS SQUANDERED\nSaved %d/%d — need %d" % [
			stats.get("rescued", 0), stats.get("total", 0), stats.get("required", 0)
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

func _build_hint_text(stats: Dictionary) -> String:
	var debug_text := "  •  F3 hitbox debug ON" if stats.get("debug_click_areas", false) else "  •  F3 shows click boxes"
	if selected_job == "builder" and builders_remaining > 0:
		return "Builder selected. Click a grounded skeleton on the gold build line to spend 1 charge and throw a six-rib bridge across the soup." + debug_text
	if builders_remaining <= 0:
		return "Builder spent. Watch the ribs land, then let the march carry survivors into the holy uplight on the right. R restarts." + debug_text
	if selected_job == "blocker" and blockers_remaining > 0:
		return "Blocker selected. Click a grounded skeleton to brace; click a blocker again to release it. R restarts." + debug_text
	return "Choose a job, then click an eligible skeleton. R restarts." + debug_text

func _update_job_buttons() -> void:
	blocker_button.disabled = blockers_remaining <= 0
	builder_button.disabled = builders_remaining <= 0
	_style_job_button(blocker_button, selected_job == "blocker", blocker_button.disabled)
	_style_job_button(builder_button, selected_job == "builder", builder_button.disabled)

func _apply_visual_style() -> void:
	job_bar.add_theme_stylebox_override("panel", _panel_box(Color(0.055, 0.045, 0.065, 0.92), Color(0.93, 0.66, 0.22, 0.55), 2, 0))

	mission_label.add_theme_color_override("font_color", Color("ffd98a"))
	mission_label.add_theme_font_size_override("font_size", 18)
	stats_label.add_theme_color_override("font_color", Color("d9ccae"))
	stats_label.add_theme_font_size_override("font_size", 15)
	hint_label.add_theme_color_override("font_color", Color("f1e7c8"))
	hint_label.add_theme_font_size_override("font_size", 14)

	result_label.add_theme_font_size_override("font_size", 30)
	result_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	result_label.add_theme_constant_override("shadow_offset_x", 3)
	result_label.add_theme_constant_override("shadow_offset_y", 3)

	for button in [blocker_button, builder_button]:
		button.add_theme_font_size_override("font_size", 17)
		button.add_theme_color_override("font_disabled_color", Color(0.50, 0.47, 0.43, 0.9))
		button.add_theme_color_override("font_color", Color("f0e2bf"))
		button.add_theme_color_override("font_hover_color", Color("fff1c4"))
		button.add_theme_color_override("font_pressed_color", Color("fff1c4"))
		button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func _style_job_button(button: Button, selected: bool, disabled: bool) -> void:
	var fill := Color(0.15, 0.12, 0.11, 0.96)
	var border := Color(0.42, 0.34, 0.24, 0.85)
	if disabled:
		fill = Color(0.08, 0.075, 0.08, 0.82)
		border = Color(0.22, 0.20, 0.19, 0.75)
	elif selected:
		fill = Color(0.30, 0.20, 0.08, 0.98)
		border = Color(1.0, 0.73, 0.25, 0.95)
	button.add_theme_stylebox_override("normal", _panel_box(fill, border, 2, 8))
	button.add_theme_stylebox_override("hover", _panel_box(fill.lightened(0.12), border.lightened(0.18), 2, 8))
	button.add_theme_stylebox_override("pressed", _panel_box(fill.darkened(0.08), border.lightened(0.28), 2, 8))
	button.add_theme_stylebox_override("disabled", _panel_box(fill, border, 2, 8))

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
