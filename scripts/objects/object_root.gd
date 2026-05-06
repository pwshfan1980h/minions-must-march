extends Node2D

signal minion_entered_exit(minion: Node)

const SPIKE_KILL_Y := 560.0
var exit_area: Area2D
var spike_rect := Rect2(576, 544, 128, 32)

func _ready() -> void:
	_build_placeholder_objects()

func _physics_process(_delta: float) -> void:
	_check_spikes()

func _build_placeholder_objects() -> void:
	_add_spawn_marker(Vector2(520, 420))
	_add_exit(Vector2(584, 448))
	_add_spikes(Vector2(672, SPIKE_KILL_Y), 128)

func _add_spawn_marker(pos: Vector2) -> void:
	var marker := Label.new()
	marker.position = pos + Vector2(-18, -66)
	marker.text = "S"
	marker.add_theme_color_override("font_color", Color("4a8be8"))
	marker.add_theme_font_size_override("font_size", 32)
	add_child(marker)

func _add_exit(pos: Vector2) -> void:
	exit_area = Area2D.new()
	exit_area.name = "ExitArea"
	exit_area.position = pos
	exit_area.collision_layer = 0
	exit_area.collision_mask = 2
	exit_area.body_entered.connect(_on_exit_body_entered)
	add_child(exit_area)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(56, 72)
	shape.shape = rect
	shape.position = Vector2(0, -24)
	exit_area.add_child(shape)

	var arch := Polygon2D.new()
	arch.color = Color("315a36")
	arch.polygon = PackedVector2Array([
		Vector2(-28, 16), Vector2(28, 16), Vector2(28, -48),
		Vector2(18, -64), Vector2(0, -72), Vector2(-18, -64), Vector2(-28, -48)
	])
	exit_area.add_child(arch)

	var glow := Label.new()
	glow.position = Vector2(-13, -58)
	glow.text = "E"
	glow.add_theme_color_override("font_color", Color("73d677"))
	glow.add_theme_font_size_override("font_size", 30)
	exit_area.add_child(glow)

func _add_spikes(pos: Vector2, width: int) -> void:
	spike_rect = Rect2(pos.x, pos.y - 16, width, 32)
	var spike_color := Color("b9b0c8")
	for x in range(0, width, 16):
		var tri := Polygon2D.new()
		tri.color = spike_color
		tri.polygon = PackedVector2Array([
			pos + Vector2(x, 16),
			pos + Vector2(x + 8, 0),
			pos + Vector2(x + 16, 16),
		])
		add_child(tri)

func _on_exit_body_entered(body: Node) -> void:
	if body.is_in_group("minions") and body.has_method("rescue"):
		minion_entered_exit.emit(body)
		body.rescue()

func _check_spikes() -> void:
	for minion in get_tree().get_nodes_in_group("minions"):
		if is_instance_valid(minion) and spike_rect.has_point(minion.global_position):
			if minion.has_method("_die"):
				minion._die()
