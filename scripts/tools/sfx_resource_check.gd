extends SceneTree

const SOUND_PATHS := [
	"res://assets/audio/generated/bone_clack.wav",
	"res://assets/audio/generated/bone_splash.wav",
	"res://assets/audio/generated/blocker_brace.wav",
	"res://assets/audio/generated/resume_march.wav",
	"res://assets/audio/generated/exit_rescue.wav",
	"res://assets/audio/generated/job_select.wav",
	"res://assets/audio/generated/level_success.wav",
	"res://assets/audio/generated/level_fail.wav",
]

func _init() -> void:
	for path in SOUND_PATHS:
		var stream := ResourceLoader.load(path)
		if stream == null:
			push_error("Failed to load SFX: %s" % path)
			quit(1)
		if not stream is AudioStream:
			push_error("Generated SFX is not an AudioStream: %s" % path)
			quit(1)
	print("SFX resource check loaded %d generated AudioStreams" % SOUND_PATHS.size())
	quit()
