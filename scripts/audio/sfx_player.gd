extends Node
class_name SfxPlayer

const STREAMS := {
	"bone_clack": preload("res://assets/audio/generated/bone_clack.wav"),
	"bone_splash": preload("res://assets/audio/generated/bone_splash.wav"),
	"blocker_brace": preload("res://assets/audio/generated/blocker_brace.wav"),
	"resume_march": preload("res://assets/audio/generated/resume_march.wav"),
	"exit_rescue": preload("res://assets/audio/generated/exit_rescue.wav"),
	"job_select": preload("res://assets/audio/generated/job_select.wav"),
	"level_success": preload("res://assets/audio/generated/level_success.wav"),
	"level_fail": preload("res://assets/audio/generated/level_fail.wav"),
}

var _rng := RandomNumberGenerator.new()
var _active_players: Array[AudioStreamPlayer] = []

func _ready() -> void:
	_rng.randomize()

func _exit_tree() -> void:
	for player in _active_players:
		if is_instance_valid(player):
			player.stop()
			player.queue_free()
	_active_players.clear()

func play(sound_id: String, volume_db := 0.0, pitch_jitter := 0.04) -> void:
	if not STREAMS.has(sound_id):
		push_warning("Unknown SFX id: %s" % sound_id)
		return

	var player := AudioStreamPlayer.new()
	player.stream = STREAMS[sound_id]
	player.volume_db = volume_db
	player.pitch_scale = _rng.randf_range(1.0 - pitch_jitter, 1.0 + pitch_jitter)
	_active_players.append(player)
	player.finished.connect(_on_player_finished.bind(player))
	add_child(player)
	player.play()

func _on_player_finished(player: AudioStreamPlayer) -> void:
	_active_players.erase(player)
	player.queue_free()
