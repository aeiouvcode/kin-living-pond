extends SceneTree
# Inspect procedural mesh buffers from the actual fish builder, not copies.
func _initialize() -> void:
	var lab = load("res://labs/fish_lab.gd").new()
	var kinds = ["ryukin", "demekin"]
	for kind in kinds:
		var fish = lab._build_fish(kind)
		var total_tri := 0
		var finite_verts := 0
		var degenerates := 0
		var procedural_tri := 0
		var procedural_parts := 0
		for item in fish.get_children():
			if not item is MeshInstance3D:
				continue
			var mesh: Mesh = item.mesh
			var is_procedural = mesh is ArrayMesh
			if is_procedural:
				procedural_parts += 1
			var item_degenerate := 0
			var item_tri := 0
			for surf in mesh.get_surface_count():
				var arrays = mesh.surface_get_arrays(surf)
				var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
				var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
				var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
				assert(vertices.size() == normals.size() and not vertices.is_empty(), "vertex/normal mismatch")
				assert(indices.size() % 3 == 0 and indices.size() > 0, "missing triangles")
				for i in vertices.size():
					assert(vertices[i].is_finite() and normals[i].is_finite(), "nonfinite fish geometry")
					finite_verts += 1
				for tri in indices.size() / 3:
					assert(indices[tri * 3] >= 0 and indices[tri * 3] < vertices.size(), "triangle index out of range")
					assert(indices[tri * 3 + 1] >= 0 and indices[tri * 3 + 1] < vertices.size(), "triangle index out of range")
					assert(indices[tri * 3 + 2] >= 0 and indices[tri * 3 + 2] < vertices.size(), "triangle index out of range")
					var a = vertices[indices[tri * 3]]
					var b = vertices[indices[tri * 3 + 1]]
					var c = vertices[indices[tri * 3 + 2]]
					if (b - a).cross(c - a).length_squared() < 1e-12:
						degenerates += 1
						item_degenerate += 1
					if is_procedural:
						procedural_tri += 1
					total_tri += 1
					item_tri += 1
			if is_procedural:
				assert(item_degenerate == 0, "procedural body/fin has degenerate triangles")
		assert(finite_verts > 1000 and total_tri > 1000 and procedural_parts == 10 and procedural_tri > 7000, "mesh walk was vacuous")
		# Primitive SphereMesh lenses close at a pole with zero-area cap faces;
		# identify this separately, never forgive degeneracy in authored meshes.
		assert(degenerates == (256 if kind == "ryukin" else 512), "primitive-mesh degeneracy pattern changed")
		print("FISH_MESH_QA %s verts=%d triangles=%d procedural_parts=%d procedural_tri=%d procedural_degenerate=0 primitive_caps=%d" % [kind, finite_verts, total_tri, procedural_parts, procedural_tri, degenerates])
		fish.free()
	lab.free()
	quit()
