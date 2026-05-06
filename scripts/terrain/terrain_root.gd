extends Node2D

const TILE_SIZE := 32
const WORLD_WIDTH := 1280
const PLAYFIELD_HEIGHT := 608

var collision_rects: Array[Rect2] = []

func _ready() -> void:
	_build_level_001_terrain()

func _build_level_001_terrain() -> void:
	# Blocker-test layout for the current prototype pass.
	# Minions spawn on the right, march left toward an edge, and can be redirected
	# back toward the exit by clicking one minion to make it brace as a blocker.
	_add_solid(Rect2(0, 576, WORLD_WIDTH, 32), Color("5d5368"))
	_add_solid(Rect2(96, 448, 544, 32), Color("6f6578"))
	_add_solid(Rect2(64, 480, 32, 64), Color("5d5368"))
	_add_solid(Rect2(608, 480, 32, 64), Color("5d5368"))

func _add_solid(rect: Rect2, color: Color) -> void:
	collision_rects.append(rect)

	var body := StaticBody2D.new()
	body.name = "SolidBlock"
	body.position = rect.position + rect.size / 2.0
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)

	var shape := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = rect.size
	shape.shape = rect_shape
	body.add_child(shape)

	var visual := Polygon2D.new()
	visual.name = "Visual"
	visual.color = color
	visual.polygon = PackedVector2Array([
		-rect.size / 2.0,
		Vector2(rect.size.x / 2.0, -rect.size.y / 2.0),
		rect.size / 2.0,
		Vector2(-rect.size.x / 2.0, rect.size.y / 2.0),
	])
	body.add_child(visual)

	_add_block_trim(rect, body)

func _add_block_trim(rect: Rect2, body: Node2D) -> void:
	var top_line := Line2D.new()
	top_line.default_color = Color("8f839f")
	top_line.width = 2.0
	top_line.points = PackedVector2Array([
		Vector2(-rect.size.x / 2.0, -rect.size.y / 2.0 + 2.0),
		Vector2(rect.size.x / 2.0, -rect.size.y / 2.0 + 2.0),
	])
	body.add_child(top_line)
