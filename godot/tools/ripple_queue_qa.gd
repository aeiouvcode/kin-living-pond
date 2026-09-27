extends SceneTree
# Isolated source-level contract for the GPU queue's backpressure.
# No renderer or source mutation; fails loudly on count/order mismatch.
func _initialize() -> void:
	var lab = load("res://labs/water_lab/water_lab.gd").new()
	lab.use_gpu = true
	for i in 100:
		lab.drop_at(Vector2(float(i) / 100.0, 0.5), 0.1, 2.0)
	assert(lab.pending.size() == 32, "queue must hold exactly 32 latest drops")
	assert(is_equal_approx(lab.pending[0].x, 0.68), "first surviving drop must be 68")
	assert(is_equal_approx(lab.pending[31].x, 0.99), "last surviving drop must be 99")
	var delivered := 0
	for batch in 4:
		var values = lab._take_gpu_drops()
		assert(values.size() == 8, "each of four GPU batches must be full")
		for j in values.size():
			assert(is_equal_approx(values[j].x, float(68 + delivered + j) / 100.0), "drop order changed")
		delivered += values.size()
	assert(delivered == 32 and lab.pending.is_empty(), "queue must drain exactly 32 drops")
	print("RIPPLE_QUEUE_QA count=32 first=68 last=99 batches=4 delivered=32 remaining=0")
	lab.free()
	quit()
