extends SceneTree

const SAMPLE_RATE := 44100
const OUT_DIR := "res://assets/audio/generated"
const MASTER_GAIN := 0.55

var _rng := RandomNumberGenerator.new()
var _ambience_noise_state := 0.0
var _ash_noise_state := 0.0

func _init() -> void:
	_rng.seed = 0xB10C_FEED
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	_write_wav("bone_clack", 0.22, _sample_bone_clack)
	_write_wav("bone_splash", 0.46, _sample_bone_splash)
	_write_wav("styx_impact", 0.62, _sample_styx_impact)
	_write_wav("blocker_brace", 0.28, _sample_blocker_brace)
	_write_wav("resume_march", 0.24, _sample_resume_march)
	_write_wav("exit_rescue", 0.55, _sample_exit_rescue)
	_write_wav("job_select", 0.14, _sample_job_select)
	_write_wav("level_success", 0.82, _sample_level_success)
	_write_wav("level_fail", 0.72, _sample_level_fail)
	_write_wav("builder_snap", 0.34, _sample_builder_snap)
	_write_wav("digger_crack", 0.42, _sample_digger_crack)
	_write_wav("feather_chime", 0.62, _sample_feather_chime)
	_write_wav("styx_ambience", 5.0, _sample_styx_ambience)
	_write_wav("ash_ambience", 5.0, _sample_ash_ambience)
	_write_wav("bone_step", 0.11, _sample_bone_step)
	_write_wav("builder_snap_alt", 0.36, _sample_builder_snap_alt)
	_write_wav("digger_crack_alt", 0.45, _sample_digger_crack_alt)
	_write_wav("portal_whoosh", 0.74, _sample_portal_whoosh)
	_write_wav("crumble_warning", 0.58, _sample_crumble_warning)
	_write_wav("ambient_whisper", 1.8, _sample_ambient_whisper)

	print("Generated procedural SFX in %s" % OUT_DIR)
	quit()

func _write_wav(name: String, duration: float, sampler: Callable) -> void:
	var sample_count := int(duration * SAMPLE_RATE)
	var pcm := PackedByteArray()
	pcm.resize(sample_count * 2)
	for i in sample_count:
		var t := float(i) / SAMPLE_RATE
		var v := clampf(float(sampler.call(t, duration)) * MASTER_GAIN, -1.0, 1.0)
		var s := int(v * 32767.0)
		if s < 0:
			s = 65536 + s
		pcm[i * 2] = s & 0xff
		pcm[i * 2 + 1] = (s >> 8) & 0xff

	var path := "%s/%s.wav" % [OUT_DIR, name]
	var file := FileAccess.open(path, FileAccess.WRITE)
	_write_string(file, "RIFF")
	_write_u32(file, 36 + pcm.size())
	_write_string(file, "WAVE")
	_write_string(file, "fmt ")
	_write_u32(file, 16)
	_write_u16(file, 1) # PCM
	_write_u16(file, 1) # mono
	_write_u32(file, SAMPLE_RATE)
	_write_u32(file, SAMPLE_RATE * 2)
	_write_u16(file, 2)
	_write_u16(file, 16)
	_write_string(file, "data")
	_write_u32(file, pcm.size())
	file.store_buffer(pcm)
	file.close()
	print("wrote %s" % path)

func _sample_bone_clack(t: float, _duration: float) -> float:
	var hit1 := _tone(t, 920.0, 0.040) * _decay(t, 0.035)
	var hit2 := _tone(maxf(t - 0.055, 0.0), 680.0, 0.050) * _decay(maxf(t - 0.055, 0.0), 0.045)
	var tick := _noise() * _pulse(t, 0.010, 0.070)
	return (hit1 + hit2 * 0.75 + tick * 0.35) * 0.7

func _sample_bone_splash(t: float, duration: float) -> float:
	var burst := _noise() * _decay(t, 0.11) * 0.72
	var clacks := 0.0
	for n in 7:
		var at := 0.018 + float(n) * 0.043
		var lt := t - at
		if lt >= 0.0:
			clacks += sin(TAU * (410.0 + n * 118.0) * lt) * _decay(lt, 0.024) * 0.42
	var low_knock := sin(TAU * 72.0 * t) * _decay(t, 0.20) * 0.28
	var tail := sin(TAU * 118.0 * t) * _fade_out(t, duration) * 0.06
	return burst + clacks + low_knock + tail

func _sample_styx_impact(t: float, duration: float) -> float:
	var plop := sin(TAU * 54.0 * t) * _decay(t, 0.16) * 0.85
	var sludge := _noise() * _decay(t, 0.22) * 0.38
	var bubbles := 0.0
	for n in 5:
		var lt := t - 0.11 - float(n) * 0.07
		if lt >= 0.0:
			bubbles += sin(TAU * (180.0 + n * 37.0) * lt) * _decay(lt, 0.045) * 0.18
	var undertow := sin(TAU * 31.0 * t) * _fade_out(t, duration) * 0.22
	return plop + sludge + bubbles + undertow

func _sample_blocker_brace(t: float, _duration: float) -> float:
	var thud := sin(TAU * 96.0 * t) * _decay(t, 0.08) * 0.9
	var rattle := _noise() * _pulse(t, 0.018, 0.14) * 0.45
	var snap := sin(TAU * 760.0 * t) * _decay(t, 0.026) * 0.38
	return thud + rattle + snap

func _sample_resume_march(t: float, _duration: float) -> float:
	var start := _tone(t, 420.0, 0.050) * _decay(t, 0.050)
	var lift := _tone(maxf(t - 0.060, 0.0), 620.0, 0.060) * _decay(maxf(t - 0.060, 0.0), 0.065)
	var tiny_step := _noise() * _pulse(t, 0.012, 0.12) * 0.22
	return start * 0.45 + lift * 0.55 + tiny_step

func _sample_exit_rescue(t: float, duration: float) -> float:
	var chime := 0.0
	var notes := [392.0, 493.88, 587.33]
	for n in notes.size():
		var lt := t - float(n) * 0.11
		if lt >= 0.0:
			chime += sin(TAU * notes[n] * lt) * _decay(lt, 0.24) * 0.20
	var warm_pad := sin(TAU * 196.0 * t) * _fade_out(t, duration) * 0.07
	var shimmer := sin(TAU * 880.0 * t) * _fade_out(t, duration) * 0.025
	return chime + warm_pad + shimmer

func _sample_job_select(t: float, _duration: float) -> float:
	return (_tone(t, 740.0, 0.045) + _tone(maxf(t - 0.035, 0.0), 990.0, 0.040) * 0.7) * _decay(t, 0.08)

func _sample_level_success(t: float, _duration: float) -> float:
	var notes := [392.0, 523.25, 659.25, 783.99]
	var out := 0.0
	for n in notes.size():
		var lt := t - float(n) * 0.13
		if lt >= 0.0:
			out += sin(TAU * notes[n] * lt) * _decay(lt, 0.24) * 0.32
	return out

func _sample_level_fail(t: float, _duration: float) -> float:
	var drop := lerpf(260.0, 95.0, minf(t / 0.55, 1.0))
	var moan := sin(TAU * drop * t) * _decay(t, 0.45) * 0.55
	var dust := _noise() * _decay(t, 0.22) * 0.18
	return moan + dust

func _sample_builder_snap(t: float, _duration: float) -> float:
	var wood_bone := sin(TAU * 340.0 * t) * _decay(t, 0.055) * 0.52
	var seat := sin(TAU * 128.0 * t) * _decay(t, 0.11) * 0.38
	var sparkle := sin(TAU * 1020.0 * maxf(t - 0.035, 0.0)) * _decay(maxf(t - 0.035, 0.0), 0.035) * 0.16
	return wood_bone + seat + sparkle

func _sample_digger_crack(t: float, _duration: float) -> float:
	var split := _noise() * _decay(t, 0.10) * 0.58
	var stone := sin(TAU * 82.0 * t) * _decay(t, 0.18) * 0.48
	var debris := 0.0
	for n in 5:
		var lt := t - 0.055 - float(n) * 0.047
		if lt >= 0.0:
			debris += sin(TAU * (270.0 + float(n) * 61.0) * lt) * _decay(lt, 0.026) * 0.20
	return split + stone + debris

func _sample_feather_chime(t: float, duration: float) -> float:
	var out := 0.0
	var notes := [659.25, 987.77, 1318.51]
	for n in notes.size():
		var lt := t - float(n) * 0.065
		if lt >= 0.0:
			out += sin(TAU * notes[n] * lt) * _decay(lt, 0.20) * 0.19
			out += sin(TAU * notes[n] * 2.01 * lt) * _decay(lt, 0.11) * 0.055
	return out * _fade_out(t, duration)

func _sample_styx_ambience(t: float, duration: float) -> float:
	# Integer-cycle layers and an edge-faded noise bed make a seamless loop.
	var loop_phase := t / duration
	var rumble := sin(TAU * 25.0 * t) * 0.14 + sin(TAU * 35.0 * t + 0.8) * 0.09
	var breath := 0.55 + 0.45 * sin(TAU * loop_phase - 0.6)
	var churn := (sin(TAU * 55.0 * t + sin(TAU * loop_phase) * 1.8) + sin(TAU * 67.0 * t + 1.2)) * 0.045 * breath
	var noise_window := pow(sin(PI * loop_phase), 2.0)
	_ambience_noise_state = lerpf(_ambience_noise_state, _noise(), 0.025)
	var sludge := _ambience_noise_state * noise_window * (0.10 + breath * 0.055)
	var bubbles := sin(TAU * 90.0 * t) * pow(maxf(0.0, sin(TAU * 3.0 * t)), 12.0) * 0.035
	return rumble * (0.55 + breath * 0.28) + churn + sludge + bubbles

func _sample_ash_ambience(t: float, duration: float) -> float:
	var loop_phase := t / duration
	var edge_window := pow(sin(PI * loop_phase), 2.0)
	var breath := 0.62 + 0.38 * sin(TAU * loop_phase + 0.4)
	_ash_noise_state = lerpf(_ash_noise_state, _noise(), 0.018)
	var hot_air := _ash_noise_state * edge_window * (0.16 + breath * 0.06)
	var stone_hum := (sin(TAU * 42.0 * t) * 0.10 + sin(TAU * 58.0 * t + 1.1) * 0.065) * breath
	var ember_ticks := sin(TAU * 530.0 * t) * pow(maxf(0.0, sin(TAU * 2.0 * t + 0.7)), 22.0) * 0.026
	var distant_bell := sin(TAU * 118.0 * t) * pow(maxf(0.0, sin(TAU * loop_phase)), 8.0) * 0.035
	return hot_air + stone_hum + ember_ticks + distant_bell

func _sample_bone_step(t: float, _duration: float) -> float:
	var tap := sin(TAU * 760.0 * t) * _decay(t, 0.022) * 0.34
	var heel := sin(TAU * 210.0 * t) * _decay(t, 0.038) * 0.18
	return tap + heel

func _sample_builder_snap_alt(t: float, _duration: float) -> float:
	var snap := sin(TAU * 430.0 * t) * _decay(t, 0.046) * 0.46
	var joint := sin(TAU * 152.0 * t) * _decay(t, 0.13) * 0.34
	var second := sin(TAU * 820.0 * maxf(t - 0.058, 0.0)) * _decay(maxf(t - 0.058, 0.0), 0.032) * 0.15
	return snap + joint + second

func _sample_digger_crack_alt(t: float, _duration: float) -> float:
	var fracture := _noise() * _decay(t, 0.13) * 0.48
	var slab := sin(TAU * 68.0 * t) * _decay(t, 0.22) * 0.52
	var grit := sin(TAU * 330.0 * maxf(t - 0.09, 0.0)) * _decay(maxf(t - 0.09, 0.0), 0.065) * 0.18
	return fracture + slab + grit

func _sample_portal_whoosh(t: float, duration: float) -> float:
	var envelope := sin(clampf(t / duration, 0.0, 1.0) * PI)
	var sweep_hz := lerpf(90.0, 520.0, t / duration)
	var sweep := sin(TAU * sweep_hz * t) * envelope * 0.22
	var air := _noise() * envelope * 0.13
	var low_gate := sin(TAU * 48.0 * t) * _decay(t, 0.34) * 0.30
	return sweep + air + low_gate

func _sample_crumble_warning(t: float, duration: float) -> float:
	var knock := sin(TAU * 74.0 * t) * _decay(t, 0.15) * 0.48
	var crack := _noise() * _decay(t, 0.11) * 0.28
	var pulse := sin(TAU * 148.0 * t) * pow(maxf(0.0, sin(TAU * 4.0 * t)), 5.0) * _fade_out(t, duration) * 0.16
	return knock + crack + pulse

func _sample_ambient_whisper(t: float, duration: float) -> float:
	var envelope := pow(sin(clampf(t / duration, 0.0, 1.0) * PI), 1.7)
	var breath := _noise() * envelope * 0.065
	var hollow := (sin(TAU * 176.0 * t + sin(TAU * 0.7 * t)) + sin(TAU * 233.0 * t + 1.4)) * envelope * 0.024
	return breath + hollow

func _tone(t: float, hz: float, length: float) -> float:
	if t < 0.0 or t > length:
		return 0.0
	return sin(TAU * hz * t)

func _decay(t: float, seconds: float) -> float:
	return exp(-t / maxf(seconds, 0.001))

func _pulse(t: float, length: float, start: float = 0.0) -> float:
	var local := t - start
	if local < 0.0 or local > length:
		return 0.0
	return 1.0 - (local / length)

func _fade_out(t: float, duration: float) -> float:
	return clampf(1.0 - t / maxf(duration, 0.001), 0.0, 1.0)

func _noise() -> float:
	return _rng.randf_range(-1.0, 1.0)

func _write_string(file: FileAccess, value: String) -> void:
	file.store_buffer(value.to_ascii_buffer())

func _write_u16(file: FileAccess, value: int) -> void:
	file.store_8(value & 0xff)
	file.store_8((value >> 8) & 0xff)

func _write_u32(file: FileAccess, value: int) -> void:
	file.store_8(value & 0xff)
	file.store_8((value >> 8) & 0xff)
	file.store_8((value >> 16) & 0xff)
	file.store_8((value >> 24) & 0xff)
