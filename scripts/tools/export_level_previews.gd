extends SceneTree

const DATA_PATH := "res://docs/level-preview-data.json"
const PREVIEW_WIDTH := 1280
const PREVIEW_HEIGHT := 720
const BOARD_OFFSET := Vector2i(40, 170)
const FONT_SCALE := 3

const PALETTES := {
	"styx": {
		"bg": Color8(10, 8, 17), "sky": Color8(28, 10, 27), "terrain": Color8(84, 69, 91),
		"support": Color8(105, 91, 71), "back": Color8(25, 21, 28), "hazard": Color8(23, 20, 12),
		"hazard2": Color8(74, 95, 47), "accent": Color8(143, 225, 96), "text": Color8(239, 220, 168)
	},
	"forge": {
		"bg": Color8(12, 7, 10), "sky": Color8(43, 15, 11), "terrain": Color8(66, 62, 74),
		"support": Color8(77, 69, 69), "back": Color8(26, 19, 18), "hazard": Color8(86, 28, 11),
		"hazard2": Color8(224, 103, 34), "accent": Color8(255, 168, 57), "text": Color8(246, 204, 142)
	},
	"soul": {
		"bg": Color8(8, 10, 22), "sky": Color8(21, 16, 49), "terrain": Color8(61, 63, 89),
		"support": Color8(54, 78, 89), "back": Color8(17, 19, 31), "hazard": Color8(14, 22, 36),
		"hazard2": Color8(80, 218, 202), "accent": Color8(164, 244, 221), "text": Color8(218, 230, 255)
	},
	"bone": {
		"bg": Color8(12, 9, 15), "sky": Color8(30, 22, 40), "terrain": Color8(92, 79, 96),
		"support": Color8(113, 102, 78), "back": Color8(21, 20, 24), "hazard": Color8(20, 24, 17),
		"hazard2": Color8(111, 143, 78), "accent": Color8(219, 205, 150), "text": Color8(237, 222, 184)
	}
}

const FONT := {
	"A": ["01110","10001","10001","11111","10001","10001","10001"],
	"B": ["11110","10001","10001","11110","10001","10001","11110"],
	"C": ["01111","10000","10000","10000","10000","10000","01111"],
	"D": ["11110","10001","10001","10001","10001","10001","11110"],
	"E": ["11111","10000","10000","11110","10000","10000","11111"],
	"F": ["11111","10000","10000","11110","10000","10000","10000"],
	"G": ["01111","10000","10000","10111","10001","10001","01111"],
	"H": ["10001","10001","10001","11111","10001","10001","10001"],
	"I": ["11111","00100","00100","00100","00100","00100","11111"],
	"J": ["00111","00010","00010","00010","10010","10010","01100"],
	"K": ["10001","10010","10100","11000","10100","10010","10001"],
	"L": ["10000","10000","10000","10000","10000","10000","11111"],
	"M": ["10001","11011","10101","10101","10001","10001","10001"],
	"N": ["10001","11001","10101","10011","10001","10001","10001"],
	"O": ["01110","10001","10001","10001","10001","10001","01110"],
	"P": ["11110","10001","10001","11110","10000","10000","10000"],
	"Q": ["01110","10001","10001","10001","10101","10010","01101"],
	"R": ["11110","10001","10001","11110","10100","10010","10001"],
	"S": ["01111","10000","10000","01110","00001","00001","11110"],
	"T": ["11111","00100","00100","00100","00100","00100","00100"],
	"U": ["10001","10001","10001","10001","10001","10001","01110"],
	"V": ["10001","10001","10001","10001","10001","01010","00100"],
	"W": ["10001","10001","10001","10101","10101","10101","01010"],
	"X": ["10001","10001","01010","00100","01010","10001","10001"],
	"Y": ["10001","10001","01010","00100","00100","00100","00100"],
	"Z": ["11111","00001","00010","00100","01000","10000","11111"],
	"0": ["01110","10001","10011","10101","11001","10001","01110"],
	"1": ["00100","01100","00100","00100","00100","00100","01110"],
	"2": ["01110","10001","00001","00010","00100","01000","11111"],
	"3": ["11110","00001","00001","01110","00001","00001","11110"],
	"4": ["10010","10010","10010","11111","00010","00010","00010"],
	"5": ["11111","10000","10000","11110","00001","00001","11110"],
	"6": ["01111","10000","10000","11110","10001","10001","01110"],
	"7": ["11111","00001","00010","00100","01000","01000","01000"],
	"8": ["01110","10001","10001","01110","10001","10001","01110"],
	"9": ["01110","10001","10001","01111","00001","00001","11110"],
	" ": ["00000","00000","00000","00000","00000","00000","00000"],
	"-": ["00000","00000","00000","11111","00000","00000","00000"],
	"/": ["00001","00010","00010","00100","01000","01000","10000"],
	":": ["00000","00100","00100","00000","00100","00100","00000"],
	".": ["00000","00000","00000","00000","00000","01100","01100"]
}

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var data := _load_data()
	if data.is_empty():
		quit(1)
	var output_dir := String(data.get("outputDir", "res://docs/level-previews"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	var tile_size := int(data.get("tileSize", 16))
	var levels: Array = data.get("levels", [])
	for level in levels:
		var path := "%s/%s.png" % [output_dir, String(level.get("id", "preview"))]
		var image := _render_level(level, tile_size)
		var err := image.save_png(path)
		print("preview %s err=%s" % [path, err])
	quit(0)

func _load_data() -> Dictionary:
	var text := FileAccess.get_file_as_string(DATA_PATH)
	if text.is_empty():
		push_error("Could not read %s" % DATA_PATH)
		return {}
	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		push_error("JSON parse error %s at line %s" % [json.get_error_message(), json.get_error_line()])
		return {}
	return json.data

func _render_level(level: Dictionary, tile_size: int) -> Image:
	var palette: Dictionary = PALETTES.get(String(level.get("palette", "styx")), PALETTES["styx"])
	var image := Image.create(PREVIEW_WIDTH, PREVIEW_HEIGHT, false, Image.FORMAT_RGBA8)
	image.fill(palette["bg"])
	_fill_rect(image, Rect2i(0, 0, PREVIEW_WIDTH, PREVIEW_HEIGHT), palette["sky"])
	_fill_rect(image, Rect2i(0, 120, PREVIEW_WIDTH, PREVIEW_HEIGHT - 120), Color(palette["bg"]).darkened(0.18))
	_draw_background_shapes(image, palette)

	_draw_text(image, Vector2i(38, 32), String(level.get("name", "LEVEL")), palette["text"], FONT_SCALE)
	_draw_text(image, Vector2i(40, 76), "%s  %s" % [String(level.get("biome", "BIOME")), String(level.get("goal", "SAVE"))], Color(palette["text"]).darkened(0.1), 2)
	_draw_tools(image, level.get("tools", {}), Vector2i(890, 28), palette)

	for hazard in level.get("hazards", []):
		_draw_hazard(image, hazard, tile_size, palette)
	for terrain in level.get("terrain", []):
		_draw_terrain(image, terrain, tile_size, palette)
	_draw_spawn(image, level.get("spawn", {}), tile_size, palette)
	_draw_exit(image, level.get("exit", {}), tile_size, palette)
	for marker in level.get("markers", []):
		_draw_marker(image, marker, tile_size, palette)

	_fill_rect(image, Rect2i(34, 154, 1212, 2), Color(palette["accent"]).darkened(0.2))
	_fill_rect(image, Rect2i(34, 154, 2, 340), Color(palette["accent"]).darkened(0.3))
	return image

func _draw_background_shapes(image: Image, palette: Dictionary) -> void:
	for i in 8:
		var x := 70 + i * 155
		var h := 30 + (i * 23) % 80
		_fill_rect(image, Rect2i(x, 120 - h, 20, h), Color(palette["bg"]).darkened(0.15))
	for i in 18:
		var x := i * 78
		_draw_triangle(image, Vector2i(x, 318), Vector2i(x + 45, 318), Vector2i(x + 22, 232 + (i * 13) % 48), Color(palette["bg"]).darkened(0.06))

func _draw_terrain(image: Image, terrain: Dictionary, tile_size: int, palette: Dictionary) -> void:
	var kind := String(terrain.get("kind", "terrain"))
	var color: Color = palette["terrain"]
	if kind == "support":
		color = palette["support"]
	elif kind == "back":
		color = palette["back"]
	var rect := _tile_rect(terrain, tile_size)
	_fill_rect(image, rect, color)
	_fill_rect(image, Rect2i(rect.position, Vector2i(rect.size.x, 3)), color.lightened(0.22))
	for x in range(rect.position.x + 10, rect.end.x, 48):
		_draw_line(image, Vector2i(x, rect.position.y + 5), Vector2i(x + 18, rect.end.y - 5), color.darkened(0.25))

func _draw_hazard(image: Image, hazard: Dictionary, tile_size: int, palette: Dictionary) -> void:
	var rect := _tile_rect(hazard, tile_size)
	_fill_rect(image, rect, palette["hazard"])
	for x in range(rect.position.x, rect.end.x, 18):
		var y := rect.position.y + 7 + int(sin(float(x) * 0.08) * 4.0)
		_draw_line(image, Vector2i(x, y), Vector2i(x + 12, y + 3), palette["hazard2"])

func _draw_spawn(image: Image, spawn: Dictionary, tile_size: int, palette: Dictionary) -> void:
	var p := _tile_point(spawn, tile_size) + Vector2i(0, -tile_size * 2)
	_draw_circle(image, p, 36, Color(palette["accent"]).darkened(0.25))
	_draw_circle(image, p, 24, Color(palette["accent"]).darkened(0.55))
	_draw_circle(image, p, 12, palette["accent"])
	_draw_arrow(image, p + Vector2i(0, 48), String(spawn.get("dir", "right")), palette["accent"])

func _draw_exit(image: Image, exit_data: Dictionary, tile_size: int, palette: Dictionary) -> void:
	var p := _tile_point(exit_data, tile_size) + Vector2i(0, -tile_size * 3)
	_draw_line(image, p + Vector2i(0, 74), p + Vector2i(0, -50), Color8(202, 244, 202))
	_draw_circle(image, p + Vector2i(0, 18), 26, Color8(149, 225, 190, 120))
	_fill_rect(image, Rect2i(p.x - 18, p.y + 60, 36, 10), Color8(203, 220, 180))

func _draw_marker(image: Image, marker: Dictionary, tile_size: int, palette: Dictionary) -> void:
	var p := _tile_point(marker, tile_size) + Vector2i(0, -tile_size)
	var kind := String(marker.get("kind", "arrow"))
	if kind == "blocker":
		_draw_line(image, p + Vector2i(0, -22), p + Vector2i(0, 24), Color8(255, 82, 66))
		_draw_line(image, p + Vector2i(-16, -6), p + Vector2i(16, -6), Color8(255, 82, 66))
	elif kind == "build":
		_draw_line(image, p + Vector2i(-4, 24), p + Vector2i(-4, -32), Color8(255, 206, 61))
		_draw_arrow(image, p + Vector2i(16, -12), String(marker.get("dir", "right")), Color8(255, 206, 61))
	else:
		_draw_arrow(image, p, String(marker.get("dir", "right")), palette["accent"])

func _draw_tools(image: Image, tools: Dictionary, pos: Vector2i, palette: Dictionary) -> void:
	var x := pos.x
	for key in tools.keys():
		_fill_rect(image, Rect2i(x, pos.y, 105, 68), Color(palette["bg"]).lightened(0.08))
		_fill_rect(image, Rect2i(x, pos.y, 105, 2), palette["accent"])
		_draw_text(image, Vector2i(x + 12, pos.y + 12), String(key).to_upper().substr(0, 5), palette["text"], 1)
		_draw_text(image, Vector2i(x + 35, pos.y + 38), "X%d" % int(tools[key]), palette["accent"], 2)
		x += 118

func _tile_rect(data: Dictionary, tile_size: int) -> Rect2i:
	return Rect2i(BOARD_OFFSET.x + int(data.get("x", 0)) * tile_size, BOARD_OFFSET.y + int(data.get("y", 0)) * tile_size, int(data.get("w", 1)) * tile_size, int(data.get("h", 1)) * tile_size)

func _tile_point(data: Dictionary, tile_size: int) -> Vector2i:
	return Vector2i(BOARD_OFFSET.x + int(data.get("x", 0)) * tile_size, BOARD_OFFSET.y + int(data.get("y", 0)) * tile_size)

func _fill_rect(image: Image, rect: Rect2i, color: Color) -> void:
	image.fill_rect(rect, color)

func _draw_line(image: Image, a: Vector2i, b: Vector2i, color: Color, width := 2) -> void:
	var dx: int = abs(b.x - a.x)
	var sx: int = 1 if a.x < b.x else -1
	var dy: int = -abs(b.y - a.y)
	var sy: int = 1 if a.y < b.y else -1
	var err: int = dx + dy
	var x: int = a.x
	var y: int = a.y
	while true:
		_fill_rect(image, Rect2i(x - width / 2, y - width / 2, width, width), color)
		if x == b.x and y == b.y:
			break
		var e2: int = 2 * err
		if e2 >= dy:
			err += dy
			x += sx
		if e2 <= dx:
			err += dx
			y += sy

func _draw_circle(image: Image, center: Vector2i, radius: int, color: Color) -> void:
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			var d := Vector2i(x, y) - center
			if d.x * d.x + d.y * d.y <= radius * radius:
				if x >= 0 and x < PREVIEW_WIDTH and y >= 0 and y < PREVIEW_HEIGHT:
					image.set_pixel(x, y, color)

func _draw_triangle(image: Image, a: Vector2i, b: Vector2i, c: Vector2i, color: Color) -> void:
	var min_x := mini(a.x, mini(b.x, c.x))
	var max_x := maxi(a.x, maxi(b.x, c.x))
	var min_y := mini(a.y, mini(b.y, c.y))
	var max_y := maxi(a.y, maxi(b.y, c.y))
	var area := _edge(a, b, c)
	if area == 0:
		return
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var p := Vector2i(x, y)
			var w0 := _edge(b, c, p)
			var w1 := _edge(c, a, p)
			var w2 := _edge(a, b, p)
			if (w0 >= 0 and w1 >= 0 and w2 >= 0) or (w0 <= 0 and w1 <= 0 and w2 <= 0):
				if x >= 0 and x < PREVIEW_WIDTH and y >= 0 and y < PREVIEW_HEIGHT:
					image.set_pixel(x, y, color)

func _edge(a: Vector2i, b: Vector2i, c: Vector2i) -> int:
	return (c.x - a.x) * (b.y - a.y) - (c.y - a.y) * (b.x - a.x)

func _draw_arrow(image: Image, p: Vector2i, dir: String, color: Color) -> void:
	var a := p
	var b := p + Vector2i(32, 0)
	if dir == "left":
		b = p + Vector2i(-32, 0)
	elif dir == "up":
		b = p + Vector2i(0, -32)
	elif dir == "down":
		b = p + Vector2i(0, 32)
	_draw_line(image, a, b, color, 3)
	var h1 := Vector2i(-8, -8)
	var h2 := Vector2i(-8, 8)
	if dir == "left":
		h1 = Vector2i(8, -8); h2 = Vector2i(8, 8)
	elif dir == "up":
		h1 = Vector2i(-8, 8); h2 = Vector2i(8, 8)
	elif dir == "down":
		h1 = Vector2i(-8, -8); h2 = Vector2i(8, -8)
	_draw_line(image, b, b + h1, color, 3)
	_draw_line(image, b, b + h2, color, 3)

func _draw_text(image: Image, pos: Vector2i, text: String, color: Color, scale: int) -> void:
	var cursor := pos
	for ch in text.to_upper():
		if ch == "\n":
			cursor.x = pos.x
			cursor.y += 9 * scale
			continue
		_draw_char(image, cursor, ch, color, scale)
		cursor.x += 6 * scale

func _draw_char(image: Image, pos: Vector2i, ch: String, color: Color, scale: int) -> void:
	var rows: Array = FONT.get(ch, FONT.get(" "))
	for y in rows.size():
		var row := String(rows[y])
		for x in row.length():
			if row[x] == "1":
				_fill_rect(image, Rect2i(pos.x + x * scale, pos.y + y * scale, scale, scale), color)
