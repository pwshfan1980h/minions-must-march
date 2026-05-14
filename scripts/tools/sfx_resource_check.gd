extends SceneTree

const SOUND_PATHS := [
	"res://assets/audio/generated/bone_clack.wav",
	"res://assets/audio/generated/march_step.wav",
	"res://assets/audio/generated/command_clatter.wav",
	"res://assets/audio/generated/death_yelp_tall.wav",
	"res://assets/audio/generated/death_yelp_wiry.wav",
	"res://assets/audio/generated/death_yelp_stocky.wav",
	"res://assets/audio/generated/death_knell.wav",
	"res://assets/audio/imported/death_bone_rattle.wav",
	"res://assets/audio/imported/styx_soup_impact.wav",
	"res://assets/audio/generated/blocker_brace.wav",
	"res://assets/audio/generated/resume_march.wav",
	"res://assets/audio/imported/exit_pillar_soft.wav",
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
			push_error("SFX is not an AudioStream: %s" % path)
			quit(1)
	print("SFX resource check loaded %d AudioStreams" % SOUND_PATHS.size())
	quit()
