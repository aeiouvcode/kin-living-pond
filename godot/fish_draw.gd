extends Node2D
## Draws one koi (mode 0) or its floor shadow (mode 1) from the fish's current mesh.

var fish: RefCounted
var mode := 0

func _draw() -> void:
	if fish == null:
		return
	var m: Dictionary = fish.mesh
	if m.is_empty():
		return
	RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), m.idx, m.pts, m.cols, m.uvs)
