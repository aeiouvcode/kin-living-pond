extends SceneTree
# Exercise the real water-lab drop entry point without allocating a renderer.
func _initialize() -> void:
	var lab = load("res://labs/water_lab/water_lab.gd").new()
	lab.use_gpu = true
	for uv in [Vector2(-0.01, 0.5), Vector2(1.01, 0.5), Vector2(0.5, -0.1), Vector2(0.5, 1.1), Vector2(NAN, 0.5), Vector2(0.5, INF)]:
		lab.drop_at(uv, 0.2, 2.0)
	for bad in [NAN, INF, -INF, 0.0, -0.1]:
		lab.drop_at(Vector2(0.5, 0.5), bad, 2.0)
		lab.drop_at(Vector2(0.5, 0.5), 0.2, bad)
	assert(lab.pending.is_empty(), "invalid drops must not consume queue slots")
	for uv in [Vector2.ZERO, Vector2(0.5, 0.5), Vector2.ONE]:
		lab.drop_at(uv, 0.2, 2.0)
	assert(lab.pending.size() == 3, "boundary-valid drops must be accepted")
	assert(lab.pending[0].x == 0.0 and lab.pending[1].x == 0.5 and lab.pending[2].x == 1.0, "valid order changed")
	# CPU path must reject the same malformed inputs without touching its grid.
	lab.use_gpu = false
	lab.W = 8
	lab.H = 8
	lab.cur.resize(64)
	for bad in [NAN, INF, -INF, 0.0, -0.1]:
		lab.drop_at(Vector2(0.5, 0.5), bad, 2.0)
		lab.drop_at(Vector2(0.5, 0.5), 0.2, bad)
	for v in lab.cur:
		assert(v == 0.0 and is_finite(v), "invalid CPU impulse mutated the grid")
	lab.drop_at(Vector2(0.5, 0.5), 0.2, 2.0)
	assert(lab.cur[4 * lab.W + 4] < -0.19, "valid CPU impulse must still work")
	print("RIPPLE_BOUNDS_QA rejected=16 valid=3 ordered=1 cpu_rejected=10 cpu_valid=1")
	lab.free()
	quit()
