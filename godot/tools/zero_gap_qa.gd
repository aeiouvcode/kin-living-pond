extends SceneTree
# Exact-coincidence branch of Pond Next's actual hard-gap step.
func _initialize() -> void:
	var p = load("res://labs/pond_lab.gd").new()
	var hard: float = p.GAP_HARD
	var left: Vector3 = p._hard_gap_step(Vector3.ZERO, hard, 0, 1)
	var right: Vector3 = p._hard_gap_step(Vector3.ZERO, hard, 1, 0)
	assert(is_equal_approx((left - right).length(), hard), "coincident fish must separate exactly to hard gap")
	assert(left.is_finite() and right.is_finite(), "coincident displacement is not finite")
	assert(is_equal_approx((left + right).length(), 0.0), "pair correction must be opposite")
	assert(p._hard_gap_step(Vector3(hard, 0, 0), hard, 0, 1).is_zero_approx(), "normal gap must stay unchanged")
	var near: Vector3 = p._hard_gap_step(Vector3(hard * 0.5, 0, 0), hard, 0, 1)
	assert(is_equal_approx(near.x, hard * 0.25) and near.z == 0.0, "near gap must use geometric direction")
	print("ZERO_GAP_QA finite=2 separated=%.3f hard=%.3f" % [(left - right).length(), hard])
	p.free()
	quit()
