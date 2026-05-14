extends Node
class_name SfxPlayer

const MUSIC_PATH := "res://assets/audio/generated/crypt_march_loop.wav"

const STREAMS := {
	"bone_clack": preload("res://assets/audio/generated/bone_clack.wav"),
	"march_step": preload("res://assets/audio/generated/march_step.wav"),
	"command_clatter": preload("res://assets/audio/generated/command_clatter.wav"),
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
}

const VOLUME_OFFSETS_DB := {
	"march_step": -8.0,
	"bone_splash": -7.5,
	"command_clatter": -3.0,
	"death_yelp_tall": -4.5,
	"death_yelp_wiry": -5.0,
	"death_yelp_stocky": -4.0,
	"death_knell": -10.0,
	"styx_impact": -9.0,
	"exit_rescue": -5.5,
}

var _rng := RandomNumberGenerator.new()
var _active_players: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer

func _ready() -> void:
	_rng.randomize()

func start_music(_config := {}) -> void:
	if DisplayServer.get_name() == "headless":
		return
	if _music_player != null and is_instance_valid(_music_player):
		_music_player.stop()
		_music_player.queue_free()
	_music_player = AudioStreamPlayer.new()
	var stream := AudioStreamWAV.load_from_file(MUSIC_PATH)
	if stream == null:
		push_warning("Music skipped: could not load %s" % MUSIC_PATH)
		return
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_music_player.stream = stream
	_music_player.volume_db = -12.0
	add_child(_music_player)
	_music_player.play()

func play_march_step(step_index: int) -> void:
	# One aggregate bone-stomp per conductor step. This makes the march beat
	# audible without scaling SFX count by the number of skeletons on screen.
	var accent_db := -2.0 if step_index % 2 == 0 else -5.0
	play("march_step", accent_db, 0.015)

func _exit_tree() -> void:
	if _music_player != null and is_instance_valid(_music_player):
		_music_player.stop()
	for player in _active_players:
		if is_instance_valid(player):
			player.stop()
			player.queue_free()
	_active_players.clear()

func play(sound_id: String, volume_db := 0.0, pitch_jitter := 0.04) -> void:
	if DisplayServer.get_name() == "headless":
		return
	if not STREAMS.has(sound_id):
		push_warning("Unknown SFX id: %s" % sound_id)
		return

	var player := AudioStreamPlayer.new()
	player.stream = STREAMS[sound_id]
	player.volume_db = volume_db + float(VOLUME_OFFSETS_DB.get(sound_id, 0.0))
	player.pitch_scale = _rng.randf_range(1.0 - pitch_jitter, 1.0 + pitch_jitter)
	_active_players.append(player)
	player.finished.connect(_on_player_finished.bind(player))
	add_child(player)
	player.play()

func _on_player_finished(player: AudioStreamPlayer) -> void:
	_active_players.erase(player)
	player.queue_free()
