extends Node
class_name BeatConductor

signal beat_crossed(beat_index: int)
signal step_crossed(step_index: int)

const DEFAULT_BPM := 92.0
const DEFAULT_STEPS_PER_BEAT := 2
const DEFAULT_SWING := 0.0

var bpm := DEFAULT_BPM
var steps_per_beat := DEFAULT_STEPS_PER_BEAT
var swing := DEFAULT_SWING
var walk_cycles_per_beat := 1.0
var enabled := true

var _song_time := 0.0
var _last_beat_index := -1
var _last_step_index := -1

func _process(delta: float) -> void:
	if not enabled:
		return
	_song_time += delta
	var beat_index := int(floor(_song_time / seconds_per_beat()))
	if beat_index != _last_beat_index:
		_last_beat_index = beat_index
		beat_crossed.emit(beat_index)
	var step_index := step_index_at(_song_time)
	if step_index != _last_step_index:
		_last_step_index = step_index
		step_crossed.emit(step_index)

func configure(config: Dictionary) -> void:
	bpm = maxf(20.0, float(config.get("bpm", bpm)))
	steps_per_beat = maxi(1, int(config.get("steps_per_beat", steps_per_beat)))
	swing = clampf(float(config.get("swing", swing)), -0.45, 0.45)
	walk_cycles_per_beat = maxf(0.125, float(config.get("walk_cycles_per_beat", walk_cycles_per_beat)))

func reset(time_seconds := 0.0) -> void:
	_song_time = maxf(0.0, time_seconds)
	_last_beat_index = -1
	_last_step_index = -1

func song_time() -> float:
	return _song_time

func seconds_per_beat() -> float:
	return 60.0 / maxf(1.0, bpm)

func beat_phase_at(time_seconds: float) -> float:
	return fposmod(time_seconds / seconds_per_beat(), 1.0)

func beat_index_at(time_seconds: float) -> int:
	return int(floor(maxf(0.0, time_seconds) / seconds_per_beat()))

func step_index_at(time_seconds: float) -> int:
	var spb := seconds_per_beat()
	var raw_beat := maxf(0.0, time_seconds) / spb
	var beat_index := int(floor(raw_beat))
	var phase := raw_beat - float(beat_index)
	var step_in_beat := 0
	for i in range(1, steps_per_beat):
		var threshold := _step_threshold(i)
		if phase >= threshold:
			step_in_beat = i
	return beat_index * steps_per_beat + step_in_beat

func walk_cycle_radians_at(time_seconds: float, phase_offset := 0.0) -> float:
	var beats := maxf(0.0, time_seconds) / seconds_per_beat()
	return phase_offset + beats * TAU * walk_cycles_per_beat

func walk_cycle_radians(phase_offset := 0.0) -> float:
	return walk_cycle_radians_at(_song_time, phase_offset)

func _step_threshold(step_number: int) -> float:
	var base := float(step_number) / float(steps_per_beat)
	if steps_per_beat == 2 and step_number == 1:
		return clampf(base + swing, 0.05, 0.95)
	if step_number % 2 == 1:
		return clampf(base + swing / float(steps_per_beat), 0.05, 0.95)
	return clampf(base, 0.05, 0.95)
