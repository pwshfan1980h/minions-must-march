extends CanvasLayer

signal restart_requested
signal job_selected(job_id: String)

@onready var status_label: Label = $JobBar/StatusLabel
@onready var blocker_button: Button = $JobBar/BlockerButton
@onready var builder_button: Button = $JobBar/BuilderButton
@onready var result_label: Label = $ResultLabel

var selected_job := "builder"
var blockers_remaining := 0
var builders_remaining := 0

func _ready() -> void:
	print("GameUI ready")
	result_label.hide()
	blocker_button.pressed.connect(_select_blocker)
	builder_button.pressed.connect(_select_builder)
	_update_job_buttons()

func update_stats(stats: Dictionary) -> void:
	selected_job = stats.get("selected_job", selected_job)
	var debug_text := " | F3: Hitboxes ON" if stats.get("debug_click_areas", false) else " | F3: Hitboxes"
	status_label.text = "Builder Demo #1 | Spawned %d/%d | Active %d | Saved %d/%d | Lost %d | Selected %s | 1: Blocker | 2: Builder | R: Restart%s" % [
		stats.get("spawned", 0),
		stats.get("total", 0),
		stats.get("active", 0),
		stats.get("rescued", 0),
		stats.get("required", 0),
		stats.get("lost", 0),
		selected_job.capitalize(),
		debug_text,
	]
	blockers_remaining = stats.get("blockers", 0)
	builders_remaining = stats.get("builders", 0)
	blocker_button.text = "1 BLOCKER x%d\n%s" % [blockers_remaining, "No blockers in this demo" if blockers_remaining <= 0 else "Click blocker to Resume March"]
	builder_button.text = "2 BUILDER x%d\n%s" % [builders_remaining, "No builders left" if builders_remaining <= 0 else "Click skeleton to build"]
	_update_job_buttons()

func show_level_finished(success: bool, stats: Dictionary) -> void:
	result_label.show()
	if success:
		result_label.text = "CRYPT CLEARED\nSaved %d/%d" % [stats.get("rescued", 0), stats.get("total", 0)]
		result_label.add_theme_color_override("font_color", Color("73d677"))
	else:
		result_label.text = "MINIONS SQUANDERED\nSaved %d/%d — need %d" % [
			stats.get("rescued", 0), stats.get("total", 0), stats.get("required", 0)
		]
		result_label.add_theme_color_override("font_color", Color("e87676"))

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

func _update_job_buttons() -> void:
	blocker_button.disabled = blockers_remaining <= 0
	builder_button.disabled = builders_remaining <= 0

	if selected_job == "blocker":
		blocker_button.add_theme_color_override("font_color", Color("f1e7c8"))
		blocker_button.add_theme_color_override("font_pressed_color", Color("f1e7c8"))
	else:
		blocker_button.remove_theme_color_override("font_color")
		blocker_button.remove_theme_color_override("font_pressed_color")

	if selected_job == "builder":
		builder_button.add_theme_color_override("font_color", Color("f1e7c8"))
		builder_button.add_theme_color_override("font_pressed_color", Color("f1e7c8"))
	else:
		builder_button.remove_theme_color_override("font_color")
		builder_button.remove_theme_color_override("font_pressed_color")
