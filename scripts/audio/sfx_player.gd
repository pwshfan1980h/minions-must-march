extends Node
class_name SfxPlayer

const STREAMS := {
	"bone_clack": preload("res://assets/audio/generated/bone_clack.wav"),
	"builder_snap": preload("res://assets/audio/generated/builder_snap.wav"),
	"command_clatter": preload("res://assets/audio/generated/command_clatter.wav"),
	"digger_crack": preload("res://assets/audio/generated/digger_crack.wav"),
	"feather_chime": preload("res://assets/audio/generated/feather_chime.wav"),
	"death_yelp_tall": preload("res://assets/audio/generated/death_yelp_tall.wav"),
	"death_yelp_wiry": preload("res://assets/audio/generated/death_yelp_wiry.wav"),
	"death_yelp_stocky": preload("res://assets/audio/generated/death_yelp_stocky.wav"),
	"death_knell": preload("res://assets/audio/generated/death_knell.wav"),
	"bone_splash": preload("res://assets/audio/imported/death_bone_rattle.wav"),
	"styx_impact": preload("res://assets/audio/imported/styx_soup_impact.wav"),
	"blocker_brace": preload("res://assets/audio/generated/blocker_brace.wav"),
	"resume_march": preload("res://assets/audio/generated/resume_march.wav"),
	"exit_rescue": preload("res://assets/audio/imported/exit_pillar_soft.wav"),
	"job_select": preload("res://assets/audio/generated/job_select.wav"),
	"level_success": preload("res://assets/audio/generated/level_success.wav"),
	"level_fail": preload("res://assets/audio/generated/level_fail.wav"),
	"ash_ambience": preload("res://assets/audio/generated/ash_ambience.wav"),
	"styx_ambience": preload("res://assets/audio/generated/styx_ambience.wav"),
}

const VOLUME_OFFSETS_DB := {
	"bone_clack": -2.0,
	"bone_splash": -9.0,
	"builder_snap": -3.0,
	"command_clatter": -5.0,
	"digger_crack": -3.5,
	"feather_chime": -4.0,
	"death_yelp_tall": -4.5,
	"death_yelp_wiry": -5.0,
	"death_yelp_stocky": -4.0,
	"death_knell": -12.0,
	"styx_impact": -7.5,
	"exit_rescue": -7.0,
	"level_success": -1.0,
}

const MAX_INSTANCES := {
	"bone_clack": 4,
	"bone_splash": 2,
	"command_clatter": 2,
	"death_knell": 2,
	"death_yelp_tall": 2,
	"death_yelp_wiry": 2,
	"death_yelp_stocky": 2,
	"exit_rescue": 3,
	"styx_impact": 2,
}

const WORLD_SOUNDS := {
	"bone_clack": true,
	"bone_splash": true,
	"builder_snap": true,
	"command_clatter": true,
	"death_knell": true,
	"death_yelp_tall": true,
	"death_yelp_wiry": true,
	"death_yelp_stocky": true,
	"digger_crack": true,
	"exit_rescue": true,
	"feather_chime": true,
	"styx_impact": true,
}

var _rng := RandomNumberGenerator.new()
var _active_players: Array[Dictionary] = []
var _ambience_player: AudioStreamPlayer
var _ambience_tween: Tween
var _biome_profile := ""

func _ready() -> void:
	_rng.randomize()
	_ensure_bus("World SFX", -1.5)
	_ensure_bus("UI SFX", -3.0)
	_ensure_bus("Ambience", -4.0)
	set_biome_profile("crypt")

func _exit_tree() -> void:
	if _ambience_tween != null:
		_ambience_tween.kill()
	for entry in _active_players:
		var player: AudioStreamPlayer = entry["player"]
		if is_instance_valid(player):
			player.stop()
			player.queue_free()
	_active_players.clear()
	if is_instance_valid(_ambience_player):
		_ambience_player.stop()

func play(sound_id: String, volume_db := 0.0, pitch_jitter := 0.04) -> void:
	play_at(sound_id, Vector2.INF, volume_db, pitch_jitter)

func play_at(sound_id: String, world_position: Vector2, volume_db := 0.0, pitch_jitter := 0.04) -> void:
	if DisplayServer.get_name() == "headless":
		return
	if not STREAMS.has(sound_id):
		push_warning("Unknown SFX id: %s" % sound_id)
		return

	_enforce_polyphony(sound_id)
	var spatial := world_position != Vector2.INF and WORLD_SOUNDS.has(sound_id)
	var player: Variant
	if spatial:
		var player_2d := AudioStreamPlayer2D.new()
		player_2d.max_distance = 1450.0
		player_2d.attenuation = 0.35
		player_2d.panning_strength = 0.72
		player = player_2d
	else:
		player = AudioStreamPlayer.new()
	player.stream = STREAMS[sound_id]
	player.volume_db = volume_db + float(VOLUME_OFFSETS_DB.get(sound_id, 0.0))
	player.pitch_scale = _rng.randf_range(1.0 - pitch_jitter, 1.0 + pitch_jitter)
	player.bus = "World SFX" if WORLD_SOUNDS.has(sound_id) else "UI SFX"
	_active_players.append({"id": sound_id, "player": player})
	player.finished.connect(_on_player_finished.bind(player))
	add_child(player)
	if spatial:
		player.global_position = world_position
	player.play()

func _ensure_bus(bus_name: String, volume_db: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		AudioServer.add_bus()
		index = AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_volume_db(index, volume_db)

func set_biome_profile(profile: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var normalized := "ash_catacombs" if profile == "ash_catacombs" else "crypt"
	if normalized == _biome_profile and is_instance_valid(_ambience_player):
		return
	_biome_profile = normalized
	if _ambience_tween != null:
		_ambience_tween.kill()
	if is_instance_valid(_ambience_player):
		_ambience_player.stop()
		_ambience_player.queue_free()
	var stream_id := "ash_ambience" if normalized == "ash_catacombs" else "styx_ambience"
	var loop_stream: AudioStreamWAV = STREAMS[stream_id].duplicate()
	loop_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	loop_stream.loop_begin = 0
	loop_stream.loop_end = int(loop_stream.get_length() * float(loop_stream.mix_rate))
	_ambience_player = AudioStreamPlayer.new()
	_ambience_player.name = "StyxAmbience"
	_ambience_player.stream = loop_stream
	_ambience_player.bus = "Ambience"
	_ambience_player.volume_db = -42.0
	add_child(_ambience_player)
	_ambience_player.play()
	_ambience_tween = create_tween()
	var target_volume := -14.5 if normalized == "ash_catacombs" else -13.0
	_ambience_tween.tween_property(_ambience_player, "volume_db", target_volume, 2.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _enforce_polyphony(sound_id: String) -> void:
	var matches: Array[Node] = []
	for entry in _active_players:
		if String(entry["id"]) == sound_id and is_instance_valid(entry["player"]):
			matches.append(entry["player"])
	var limit := int(MAX_INSTANCES.get(sound_id, 3))
	while matches.size() >= limit:
		var oldest: Node = matches.pop_front()
		_active_players = _active_players.filter(func(entry: Dictionary) -> bool: return entry["player"] != oldest)
		oldest.stop()
		oldest.queue_free()

func _on_player_finished(player: Node) -> void:
	_active_players = _active_players.filter(func(entry: Dictionary) -> bool: return entry["player"] != player)
	player.queue_free()
