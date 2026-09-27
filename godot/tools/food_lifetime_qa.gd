extends SceneTree
# Exercise Pond Next's real aging method with a full six-slot queue.
func _initialize() -> void:
	call_deferred("run_qa")

func run_qa() -> void:
	var pond = load("res://labs/pond_lab.gd").new()
	root.add_child(pond)
	for i in 6:
		var pellet = MeshInstance3D.new()
		pond.add_child(pellet)
		pond.food.append({"node": pellet, "age": 39.75 if i < 3 else 1.0})
	assert(pond.food.size() == 6, "food cap fixture was not filled")
	pond._age_food(0.2)
	assert(pond.food.size() == 6, "food expired before TTL")
	pond._age_food(0.1)
	assert(pond.food.size() == 3, "three stale pellets should expire at TTL")
	pond._spawn_food(Vector2(195, 422))
	assert(pond.food.size() == 4, "freed slot did not accept a new tap")
	for fd in pond.food:
		assert(not fd.node.is_queued_for_deletion(), "fresh food was freed")
	assert(pond.get_children().filter(func(n): return n is MeshInstance3D and n.is_queued_for_deletion()).size() == 3, "stale nodes not queued for deletion")
	pond._age_food(39.0)
	assert(pond.food.size() == 1, "only the newly tapped pellet should remain")
	pond._age_food(1.0)
	assert(pond.food.is_empty(), "new pellet should eventually expire too")
	print("FOOD_LIFETIME_QA cap=6 before=6 after_boundary=3 reopened=4 final=0 queued=7")
	pond.queue_free()
	quit()
