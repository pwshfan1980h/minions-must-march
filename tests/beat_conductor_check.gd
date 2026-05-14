extends SceneTree

const BeatConductor := preload("res://scripts/audio/beat_conductor.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var beat := BeatConductor.new()
	beat.configure({"bpm": 96.0, "steps_per_beat": 2, "swing": 0.12})

	_assert_close(beat.seconds_per_beat(), 0.625, 0.0001, "96 BPM should be 0.625 seconds per beat")
	_assert_close(beat.beat_phase_at(0.0), 0.0, 0.0001, "phase starts on beat")
	_assert_close(beat.beat_phase_at(0.3125), 0.5, 0.0001, "halfway through beat should be phase 0.5")
	_assert_close(beat.beat_phase_at(0.625), 0.0, 0.0001, "phase wraps on next beat")

	var first_step := beat.step_index_at(0.0)
	var second_step := beat.step_index_at(0.34)
	var next_bar_step := beat.step_index_at(1.25)
	if first_step != 0:
		_fail("Expected first step index 0, got %d" % first_step)
		return
	if second_step != 1:
		_fail("Expected swung offbeat step index 1, got %d" % second_step)
		return
	if next_bar_step != 4:
		_fail("Expected four half-beat steps after two beats, got %d" % next_bar_step)
		return

	var walk_phase_a := beat.walk_cycle_radians_at(0.0, 0.0)
	var walk_phase_b := beat.walk_cycle_radians_at(0.625, 0.0)
	_assert_close(walk_phase_a, 0.0, 0.0001, "walk phase starts at zero")
	_assert_close(walk_phase_b, TAU, 0.0001, "one beat should equal one full walk cycle")

	print("PASS: BeatConductor exposes deterministic BPM phase, swung steps, and walk-cycle radians")
	quit(0)

func _assert_close(actual: float, expected: float, epsilon: float, message: String) -> void:
	if absf(actual - expected) > epsilon:
		_fail("%s (actual=%f expected=%f)" % [message, actual, expected])

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
